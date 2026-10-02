@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/src/html_editor_controller_mobile.dart';

class _FakeInAppWebViewController implements InAppWebViewController {
  final List<String> sources = [];

  @override
  Future<bool> isLoading() async => false;

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    sources.add(source);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late _FakeInAppWebViewController webViewController;
  late HtmlEditorController controller;

  setUp(() {
    webViewController = _FakeInAppWebViewController();
    controller = HtmlEditorController()..editorController = webViewController;
  });

  group('HtmlEditorController (mobile) → insertLink', () {
    test('does not create a link with a dangerous scheme', () async {
      controller.insertLink('Click', 'java\tscript:alert(1)', false);
      await pumpEventQueue();

      expect(webViewController.sources, isEmpty);
    });

    test('creates a link with a safe URL', () async {
      controller.insertLink('Click', 'https://example.com', false);
      await pumpEventQueue();

      expect(webViewController.sources, hasLength(1));
      expect(
        webViewController.sources.single,
        contains('url: "https://example.com"'),
      );
    });

    test('passes text and URL as JS string literals, not as JS source',
        () async {
      // JS would decode `\x6a` to `j` inside a quoted literal and a quote
      // would end it, so both must reach the webview escaped.
      const text = 'a"b';
      const url = r"\x6aavascript:alert(1)//'";
      controller.insertLink(text, url, false);
      await pumpEventQueue();

      final source = webViewController.sources.single;
      expect(source, contains('text: ${jsonEncode(text)},'));
      expect(source, contains('url: ${jsonEncode(url)},'));
    });
  });
}
