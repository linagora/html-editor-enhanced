@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/utils/extensions/string_link_extension.dart';
import 'package:html_editor_enhanced/utils/javascript_utils.dart';
import 'package:web/web.dart' as web;

void _runScript(String source) {
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..text = source;
  web.document.body!.append(script);
  script.remove();
}

/// Installs the guard on a stub Summernote editor, calls `createLink` with
/// each of [urls] and returns the URLs that reached the original method.
List<String> _createLinks(List<String> urls) {
  _runScript(r'''
    (function() {
      window.createdUrls = [];
      const editor = {
        createLink: function(linkInfo) { window.createdUrls.push(linkInfo.url); }
      };
      window.$ = function() {
        return { data: function() { return { modules: { editor: editor } }; } };
      };
    })();
  ''');
  _runScript(JavascriptUtils.jsRejectDangerousLinkSchemes);
  _runScript('''
    (function() {
      const editor = window.\$().data().modules.editor;
      ${jsonEncode(urls)}.forEach(function(url) { editor.createLink({ url: url }); });
    })();
  ''');
  final created = globalContext['createdUrls'] as JSArray<JSString>;
  return created.toDart.map((url) => url.toDart).toList();
}

void main() {
  group('JavascriptUtils → jsRejectDangerousLinkSchemes', () {
    test('drops every dangerous scheme', () {
      final urls = [
        for (final scheme in dangerousLinkSchemes) '$scheme:alert(1)',
      ];

      expect(_createLinks(urls), isEmpty);
    });

    test('drops schemes hidden by case, tab, newline or leading controls', () {
      expect(
        _createLinks([
          'JavaScript:alert(1)',
          'java\tscript:alert(1)',
          'java\r\nscript:alert(1)',
          '\u0001javascript:alert(1)',
          ' data:text/html,<script>alert(1)</script>',
          'javascript://%0aalert(1)',
        ]),
        isEmpty,
      );
    });

    test('passes other links to createLink unchanged', () {
      const urls = [
        'https://example.com',
        'mailto:user@example.com',
        'example.com',
        '/relative/path',
        '#anchor',
        'custom-app:open',
      ];

      expect(_createLinks(urls), urls);
    });
  });
}
