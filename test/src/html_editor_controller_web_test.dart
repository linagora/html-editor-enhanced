@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/src/html_editor_controller_web.dart';
import 'package:html_editor_enhanced/utils/web_utils.dart';
import 'package:web/web.dart' as web;

void main() {
  group('HtmlEditorController (web) → insertLink', () {
    test('does not post a link with a dangerous scheme', () async {
      final firstInsertLink = web.window.onMessage
          .map(WebUtils.convertMessageEventToDataMap)
          .firstWhere((data) => data['type'] == 'toIframe: insertLink');

      HtmlEditorController()
        ..insertLink('Click', 'java\tscript:alert(1)', false)
        ..insertLink('Safe', 'https://example.com', false);

      final data = await firstInsertLink;
      expect(data['text'], 'Safe');
      expect(data['url'], 'https://example.com');
    });
  });
}
