@TestOn('browser')
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/widgets/html_editor_widget_web.dart';
import 'package:html_editor_enhanced/utils/nonce_utils.dart';
import 'package:web/web.dart' as web;

const _nonce = 'widgetTestNonce1';

// The test web server answers every *.html URL with a generated test wrapper,
// so the real template cannot be fetched; serve a synthetic one whose script
// tags match the real template (guarded by nonce_utils_test).
const _syntheticTemplate = '''
<html lang="en">
<head>
  <meta charset="UTF-8">
  <script src="jquery.min.js"></script>
  <link href="summernote-lite.min.css" rel="stylesheet">
  <script src="summernote-lite.min.js"></script>
  <!--customInternalCSS-->
  <!--darkCSS-->
</head>
<body>
<div id="summernote-2"></div>
<!--headString-->
<!--summernoteScripts-->
<!--customBodyCssStyle-->
</body>
</html>
''';

late int _inlinedInnerScriptCount;

String? _templateOverride;
String? _filePathOverride;
List<Plugins> _pluginsOverride = const [];

const _customFilePath = 'custom-editor.html';

const _customTemplate = '''
<html lang="en">
<head>
  <script>var t = "<script>";</script>
  <script src="jquery.min.js"></script>
  <link href="summernote-lite.min.css" rel="stylesheet">
  <script src="summernote-lite.min.js"></script>
  <!--customInternalCSS-->
  <!--darkCSS-->
</head>
<body>
<div id="summernote-2"></div>
<!--headString-->
<!--summernoteScripts-->
<!--customBodyCssStyle-->
</body>
</html>
''';

const _pluginSrc =
    'assets/packages/html_editor_enhanced/assets/plugins/summernote-at-mention/summernote-at-mention.js';

Future<String> _fetchAsset(String packagePath) async {
  final response = await web.window.fetch('/$packagePath'.toJS).toDart;
  return (await response.text().toDart).toDart;
}

/// The test browser registers no 'flutter/assets' handler, so rootBundle would
/// hang; serve the package sources over HTTP instead.
Future<ByteData?> _serveAsset(ByteData? message) async {
  final key = utf8.decode(message!.buffer.asUint8List());
  if (key.endsWith('.html')) {
    return ByteData.sublistView(
        utf8.encode(_templateOverride ?? _syntheticTemplate));
  }
  final response = await web.window.fetch('/$key'.toJS).toDart;
  if (response.status != 200) return null;
  final body = await response.arrayBuffer().toDart;
  return body.toDart.asByteData();
}

// Platform views are never composited in widget tests, so the editor's iframe
// never lands in the DOM; capture it at creation time instead.
void _installIframeCaptureHook() {
  final hook = web.document.createElement('script') as web.HTMLScriptElement
    ..text = '''
      (function() {
        window.__origCreateElement = document.createElement;
        window.__capturedIframes = [];
        document.createElement = function(tagName, options) {
          var el = window.__origCreateElement.call(document, tagName, options);
          if (String(tagName).toLowerCase() === 'iframe') {
            window.__capturedIframes.push(el);
          }
          return el;
        };
      })();
    ''';
  web.document.body!.append(hook);
  hook.remove();
}

void _uninstallIframeCaptureHook() {
  final restore = web.document.createElement('script') as web.HTMLScriptElement
    ..text = 'document.createElement = window.__origCreateElement;';
  web.document.body!.append(restore);
  restore.remove();
}

List<JSObject> _capturedIframes() =>
    (globalContext['__capturedIframes'] as JSArray<JSObject>).toDart;

web.HTMLIFrameElement _lastCapturedIframe() =>
    _capturedIframes().last as web.HTMLIFrameElement;

String _editorSrcdoc() => (_lastCapturedIframe().srcdoc as JSString).toDart;

web.HTMLScriptElement _appendHostScript({String? attribute, String? property}) {
  final element = web.document.createElement('script') as web.HTMLScriptElement;
  if (attribute != null) element.setAttribute('nonce', attribute);
  if (property != null) element.nonce = property;
  web.document.head!.append(element);
  addTearDown(() => element.remove());
  return element;
}

web.HTMLScriptElement _addHostScriptWithNonce() {
  // Reproduces nonce hiding: the attribute reads blank, the property holds it.
  final element = web.document.createElement('script') as web.HTMLScriptElement
    ..setAttribute('nonce', '')
    ..nonce = _nonce;
  web.document.head!.append(element);
  return element;
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required bool offline,
  List<WebScript> webInitialScripts = const [],
}) async {
  final existingIframes = _capturedIframes().length;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        return HtmlEditorWidget(
          controller: HtmlEditorController(),
          callbacks: null,
          plugins: _pluginsOverride,
          htmlEditorOptions: HtmlEditorOptions(
            cacheHTMLAssetOffline: offline,
            filePath: _filePathOverride,
            webInitialScripts: UnmodifiableListView(webInitialScripts),
          ),
          htmlToolbarOptions: const HtmlToolbarOptions(),
          otherOptions: const OtherOptions(),
          initBC: context,
        );
      }),
    ),
  ));
  for (var i = 0; i < 40; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (_capturedIframes().length > existingIframes) return;
  }
  fail('editor iframe was never created');
}

Future<void> _verifyOfflineDocument(WidgetTester tester) async {
  final hostScript = _addHostScriptWithNonce();
  addTearDown(() => hostScript.remove());

  await _pumpEditor(tester, offline: true);
  expect(_inlinedInnerScriptCount, greaterThan(0),
      reason: 'jquery.min.js must really hold literal "<script" strings');

  final doc = _editorSrcdoc();
  // Two inlined vendor tags plus the generated script block.
  expect('<script nonce="$_nonce"'.allMatches(doc).length, 3);
  expect(doc, contains('<script nonce="$_nonce" type="text/javascript">'));
  expect('<script'.allMatches(doc).length, 3 + _inlinedInnerScriptCount);
  _expectInlinedVendorBodies(doc);
}

Future<void> _verifyOnlineDocument(WidgetTester tester) async {
  final hostScript = _addHostScriptWithNonce();
  addTearDown(() => hostScript.remove());

  await _pumpEditor(tester, offline: false);

  final doc = _editorSrcdoc();
  expect(
      doc,
      contains(
          '<script nonce="$_nonce" src="${HtmlEditorConstants.jqueryAssetPath}">'));
  expect(
      doc,
      contains(
          '<script nonce="$_nonce" src="${HtmlEditorConstants.summernoteJSAssetPath}">'));
  expect(doc, contains('<script nonce="$_nonce" type="text/javascript">'));
}

Future<void> _verifyDocumentWithoutHostNonce(WidgetTester tester) async {
  expect(web.document.querySelector('script[nonce]'), isNull);

  await _pumpEditor(tester, offline: true);

  final doc = _editorSrcdoc();
  expect(doc.contains('nonce='), isFalse);
  expect('<script'.allMatches(doc).length, 3 + _inlinedInnerScriptCount);
}

Future<void> _verifyConsumerWebScriptBody(WidgetTester tester) async {
  final hostScript = _addHostScriptWithNonce();
  addTearDown(() => hostScript.remove());

  await _pumpEditor(
    tester,
    offline: true,
    webInitialScripts: [
      WebScript(name: 'probeConsumerScript', script: 'var t = "<script>";'),
    ],
  );

  final doc = _editorSrcdoc();
  expect(doc, contains('var t = "<script>";'));
  expect('<script nonce="$_nonce"'.allMatches(doc).length, 3);
  // Package tags plus the vendor bodies plus the consumer literal.
  expect('<script'.allMatches(doc).length, 4 + _inlinedInnerScriptCount);
}

void _expectInlinedVendorBodies(String doc) {
  expect(doc, contains('/<script|<style|<link/i'));
  expect(doc, contains('S("<script>")'));
}

void _expectPackageWrittenTags(String doc) {
  expect(doc, contains('<script>var t = "<script>";</script>'));
  expect(doc, contains('<script nonce="$_nonce" type="text/javascript">'));
  expect(doc, contains('<script nonce="$_nonce" src="$_pluginSrc"></script>'));
}

Future<String> _srcdocForCustomTemplate(
  WidgetTester tester, {
  required bool offline,
}) async {
  final hostScript = _addHostScriptWithNonce();
  addTearDown(() => hostScript.remove());
  _filePathOverride = _customFilePath;
  _templateOverride = _customTemplate;
  _pluginsOverride = const [SummernoteAtMention(mentionsWeb: ['ada'])];
  await _pumpEditor(tester, offline: offline);
  return _editorSrcdoc();
}

Future<void> _verifyCustomFilePathTemplate(WidgetTester tester) async {
  final doc = await _srcdocForCustomTemplate(tester, offline: false);

  _expectPackageWrittenTags(doc);
  expect(doc,
      contains('<script src="${HtmlEditorConstants.jqueryAssetPath}"></script>'));
}

Future<void> _verifyCustomTemplateOfflineInline(WidgetTester tester) async {
  final doc = await _srcdocForCustomTemplate(tester, offline: true);

  _expectPackageWrittenTags(doc);
  _expectInlinedVendorBodies(doc);
  expect(doc.contains('<script src="jquery.min.js"></script>'), isFalse);
  expect(doc.contains('<script src="summernote-lite.min.js"></script>'), isFalse);
  expect(doc, contains('<script nonce="$_nonce">'));
  expect('<script nonce="$_nonce"'.allMatches(doc).length, 4);
}

Future<void> _verifyFirstValidHostNonce(WidgetTester tester) async {
  _appendHostScript(attribute: 'not valid', property: 'not valid');
  _appendHostScript(attribute: _nonce, property: _nonce);

  await _pumpEditor(tester, offline: false);

  final doc = _editorSrcdoc();
  expect(doc, contains('nonce="$_nonce"'));
  expect(doc.contains('not valid'), isFalse);
}

Future<void> _verifyNoncePropertyWithoutAttribute(WidgetTester tester) async {
  final element = web.document.createElement('script') as web.HTMLScriptElement
    ..nonce = _nonce;
  web.document.head!.append(element);
  element.removeAttribute('nonce');
  addTearDown(() => element.remove());
  expect(element.hasAttribute('nonce'), isFalse);
  expect(element.nonce, _nonce);

  await _pumpEditor(tester, offline: false);

  expect(_editorSrcdoc(), contains('nonce="$_nonce"'));
}

Future<void> _verifyInvalidHostNoncesOnly(WidgetTester tester) async {
  _appendHostScript(attribute: 'not valid', property: 'not valid');

  await _pumpEditor(tester, offline: true);

  expect(_editorSrcdoc().contains('nonce='), isFalse);
}

void _timeAddNonceOnChrome() {
  const sizes = [10000, 100000, 1000000];
  final builders = <String, String Function(int)>{
    'all <script ': (n) => '<script ' * (n ~/ 8) + ' ' * (n % 8),
    'alternating <script-x/<script ': (n) {
      const unit = '<script-x<script ';
      return unit * (n ~/ unit.length) + ' ' * (n % unit.length);
    },
    'no match': (n) => 'a' * n,
  };

  for (final entry in builders.entries) {
    final times = <int>[];
    for (final n in sizes) {
      final input = entry.value(n);
      expect(input.length, n, reason: entry.key);
      final stopwatch = Stopwatch()..start();
      final stamped = NonceUtils.addNonceToScriptTags(input, _nonce);
      stopwatch.stop();
      times.add(stopwatch.elapsedMicroseconds);
      if (entry.key.startsWith('all')) {
        expect(stamped, contains('nonce="$_nonce"'), reason: entry.key);
      } else if (entry.key == 'no match') {
        expect(stamped, input, reason: entry.key);
      } else {
        expect(stamped, contains('<script-x'), reason: entry.key);
      }
      // ignore: avoid_print
      print('chrome ${entry.key} $n chars: ${stopwatch.elapsedMicroseconds} us');
    }
    expect(times[1], lessThan(times[0] * 40 + 20000), reason: entry.key);
    expect(times[2], lessThan(times[1] * 40 + 20000), reason: entry.key);
  }
}

/// Records every CSP violation inside the editor document, so blocked inline
/// handlers, eval or unstamped scripts fail the test, not only blocked tags.
const _violationRecorder = '<script nonce="$_nonce">'
    'var root = document.documentElement;'
    'root.setAttribute("data-csp-violations", "");'
    'document.addEventListener("securitypolicyviolation", function (e) {'
    'var seen = root.getAttribute("data-csp-violations");'
    'root.setAttribute("data-csp-violations",'
    ' seen + e.effectiveDirective + " " + e.blockedURI + "\\n");'
    '});'
    '</script>';

/// Puts a nonce-only script policy at the top of the editor document. The meta
/// policy binds only that document, so the test runner page keeps running.
String _underNonceOnlyPolicy(String doc, String policyNonce) {
  expect(doc, contains('<head>'));
  final policy = '<meta http-equiv="Content-Security-Policy" '
      'content="script-src \'nonce-$policyNonce\'">';
  return doc.replaceFirst('<head>', '<head>$policy$_violationRecorder');
}

/// Platform views never reach the DOM in widget tests, so the captured srcdoc
/// is booted in a real iframe that waits until summernote builds its editor.
Future<web.HTMLIFrameElement> _bootInRealIframe(
  WidgetTester tester,
  String srcdoc,
) async {
  final frame = web.HTMLIFrameElement()..srcdoc = srcdoc.toJS;
  web.document.body!.append(frame);
  addTearDown(() => frame.remove());
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    if (_hasSummernoteEditor(frame)) break;
  }
  return frame;
}

bool _hasSummernoteEditor(web.HTMLIFrameElement frame) =>
    frame.contentDocument?.querySelector('.note-editor') != null;

List<String> _recordedViolations(web.HTMLIFrameElement frame) {
  // Kept in a DOM attribute: values from the iframe's JS realm fail Dart casts.
  final recorded = frame.contentDocument?.documentElement
      ?.getAttribute('data-csp-violations');
  if (recorded == null) return const ['the violation recorder never ran'];
  return recorded.split('\n').where((line) => line.isNotEmpty).toList();
}

Future<String> _offlineSrcdocWithHostNonce(WidgetTester tester) async {
  final hostScript = _addHostScriptWithNonce();
  addTearDown(() => hostScript.remove());
  await _pumpEditor(tester, offline: true);
  return _editorSrcdoc();
}

Future<void> _verifyEditorBootsUnderNoncePolicy(WidgetTester tester) async {
  final doc = await _offlineSrcdocWithHostNonce(tester);

  final frame =
      await _bootInRealIframe(tester, _underNonceOnlyPolicy(doc, _nonce));

  expect(_recordedViolations(frame), isEmpty);
  expect(_hasSummernoteEditor(frame), isTrue,
      reason: 'summernote must build its editor under a nonce-only policy');
}

Future<void> _verifyEditorBlockedUnderForeignNoncePolicy(
  WidgetTester tester,
) async {
  final doc = await _offlineSrcdocWithHostNonce(tester);

  final frame = await _bootInRealIframe(
      tester, _underNonceOnlyPolicy(doc, 'someOtherNonce1'));

  expect(_hasSummernoteEditor(frame), isFalse,
      reason: 'a policy with another nonce must block the editor scripts');
}

void _registerWidgetNonceTests() {
  group('HtmlEditorWidget (web) → script nonce', () {
    testWidgets(
      'boots the offline editor under a nonce-only script policy',
      _verifyEditorBootsUnderNoncePolicy,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'the editor does not boot when the policy holds another nonce',
      _verifyEditorBlockedUnderForeignNoncePolicy,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'stamps every script tag of the offline document and leaves the '
      'inlined jquery body untouched',
      _verifyOfflineDocument,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'stamps the src-loading tags of the online document',
      _verifyOnlineDocument,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'adds no nonce attribute when the host page has none',
      _verifyDocumentWithoutHostNonce,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'leaves a consumer WebScript body holding a literal <script> untouched',
      _verifyConsumerWebScriptBody,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'keeps a custom filePath template unchanged while package tags carry the nonce',
      _verifyCustomFilePathTemplate,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'inlines a custom template\'s vendor scripts and stamps those tags',
      _verifyCustomTemplateOfflineInline,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'uses the first valid host nonce when an earlier one is invalid',
      _verifyFirstValidHostNonce,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'reads a host nonce set only on the script property',
      _verifyNoncePropertyWithoutAttribute,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'adds no nonce when every host nonce is invalid',
      _verifyInvalidHostNoncesOnly,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}

void main() {
  setUp(() {
    _filePathOverride = null;
    _templateOverride = null;
    _pluginsOverride = const [];
  });

  setUpAll(() async {
    final jquery = await _fetchAsset(HtmlEditorConstants.jqueryAssetPath);
    final summernoteJs =
        await _fetchAsset(HtmlEditorConstants.summernoteJSAssetPath);
    _inlinedInnerScriptCount = '<script'.allMatches(jquery).length +
        '<script'.allMatches(summernoteJs).length;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', _serveAsset);
    _installIframeCaptureHook();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    _uninstallIframeCaptureHook();
  });

  _registerWidgetNonceTests();

  test(
    'addNonceToScriptTags stays linear on tag-shaped inputs',
    _timeAddNonceOnChrome,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
