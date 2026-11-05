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

Future<String> _fetchAsset(String packagePath) async {
  final response = await web.window.fetch('/$packagePath'.toJS).toDart;
  return (await response.text().toDart).toDart;
}

/// The test browser registers no 'flutter/assets' handler, so rootBundle would
/// hang; serve the package sources over HTTP instead.
Future<ByteData?> _serveAsset(ByteData? message) async {
  final key = utf8.decode(message!.buffer.asUint8List());
  if (key.endsWith('.html')) {
    return ByteData.sublistView(utf8.encode(_syntheticTemplate));
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
          plugins: const [],
          htmlEditorOptions: HtmlEditorOptions(
            cacheHTMLAssetOffline: offline,
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
  expect(doc, contains('/<script|<style|<link/i'));
  expect(doc, contains('S("<script>")'));
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

void main() {
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

  group('HtmlEditorWidget (web) → script nonce', () {
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
  });
}
