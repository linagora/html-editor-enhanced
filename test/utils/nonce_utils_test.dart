@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/utils/nonce_utils.dart';

const _nonce = 'aBc123+/=_-XYZ';

String _asset(String name) => File('lib/assets/$name').readAsStringSync();

int _scriptTagCount(String html) => '<script'.allMatches(html).length;

/// Mirrors the assembly order of html_editor_widget_web.dart: stamp the
/// template first, substitute the generated block under a stamped tag, then
/// inline the vendor bodies under stamped tags.
String _assembleOffline(
    String template, String? nonce, String generatedBlock,
    (String, String) vendorBodies) {
  final attribute = NonceUtils.nonceAttribute(nonce);
  final html = NonceUtils.addNonceToScriptTags(template, nonce).replaceFirst(
      '<!--summernoteScripts-->',
      '<script$attribute type="text/javascript">$generatedBlock</script>');
  return html
      .replaceFirst('<script$attribute src="jquery.min.js"></script>',
          '<script$attribute>${vendorBodies.$1}</script>')
      .replaceFirst('<script$attribute src="summernote-lite.min.js"></script>',
          '<script$attribute>${vendorBodies.$2}</script>');
}

void main() {
  group('NonceUtils → addNonceToScriptTags', () {
    test('stamps every <script tag of both editor template assets', () {
      for (final name in ['summernote.html', 'summernote-no-plugins.html']) {
        final template = _asset(name);
        final tagCount = _scriptTagCount(template);
        expect(tagCount, greaterThan(0), reason: name);

        final stamped = NonceUtils.addNonceToScriptTags(template, _nonce);

        expect('<script nonce="$_nonce"'.allMatches(stamped).length, tagCount,
            reason: name);
        expect(_scriptTagCount(stamped), tagCount, reason: name);
      }
    });

    test('the real templates hold the anchors the widget inlining relies on', () {
      for (final name in ['summernote.html', 'summernote-no-plugins.html']) {
        final template = _asset(name);
        expect(template, contains('<script src="jquery.min.js"></script>'),
            reason: name);
        expect(template,
            contains('<script src="summernote-lite.min.js"></script>'),
            reason: name);
      }
      final noPlugins = _asset('summernote-no-plugins.html');
      expect(noPlugins, contains('<!--summernoteScripts-->'));
    });

    test('stamps the generated block and plugin script tags', () {
      const html = '<script type="text/javascript">var x = 1;</script>\n'
          '<script src="assets/packages/html_editor_enhanced/assets/plugins/summernote-at-mention/summernote-at-mention.js"></script>';

      final stamped = NonceUtils.addNonceToScriptTags(html, _nonce);

      expect(stamped, contains('<script nonce="$_nonce" type="text/javascript">'));
      expect(stamped, contains('<script nonce="$_nonce" src="assets/packages'));
      expect(_scriptTagCount(stamped), _scriptTagCount(html));
    });

    test('offline flow stamps both inlined vendor tags and keeps their JS '
        'bodies byte-identical', () {
      final jquery = _asset('jquery.min.js');
      final summernoteJs = _asset('summernote-lite-v2.min.js');
      final innerCount = _scriptTagCount(jquery) + _scriptTagCount(summernoteJs);
      expect(innerCount, greaterThan(0),
          reason: 'jquery.min.js must really hold literal "<script" strings');

      final html = _assembleOffline(_asset('summernote-no-plugins.html'),
          _nonce, '', (jquery, summernoteJs));

      expect('<script nonce="$_nonce">'.allMatches(html).length, 2);
      expect(
          html, contains('<script nonce="$_nonce" type="text/javascript">'));
      expect(html, contains('<script nonce="$_nonce">$jquery</script>'));
      expect(html, contains('<script nonce="$_nonce">$summernoteJs</script>'));
      expect(_scriptTagCount(html), 3 + innerCount);
    });

    test('consumer text inside the generated block is never stamped', () {
      const consumerScript =
          'if (data["type"].includes("probe")) { var t = "<script>"; }';

      final html = _assembleOffline(_asset('summernote-no-plugins.html'),
          _nonce, consumerScript, ('no-inner', 'no-inner'));

      expect(html, contains(consumerScript));
      expect(
          html, contains('<script nonce="$_nonce" type="text/javascript">'));
      expect('<script nonce="$_nonce"'.allMatches(html).length, 3);
      expect(_scriptTagCount(html), 4);
    });

    test('a "<script" string inside an inlined JS body is never stamped', () {
      const template = '<head><script src="jquery.min.js"></script></head>';
      const body = 'var re=/<script|<style|<link/i;el=S("<script>");';

      final html =
          _assembleOffline(template, _nonce, '', (body, 'no-inner-tags'));

      expect(html, contains(body));
      expect('<script nonce="$_nonce"'.allMatches(html).length, 1);
      expect(_scriptTagCount(html), 1 + _scriptTagCount(body));
    });

    test('stamps <SCRIPT> and leaves <script-x untouched', () {
      const html = '<SCRIPT src="a.js"></SCRIPT><script-x>keep</script-x>';

      final stamped = NonceUtils.addNonceToScriptTags(html, _nonce);

      expect(stamped,
          '<script nonce="$_nonce" src="a.js"></SCRIPT><script-x>keep</script-x>');
    });

    test('addNonceToScriptTags stays linear on tag-shaped inputs', () {
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
            expect(stamped.contains('script-x nonce'), isFalse, reason: entry.key);
          }
          // ignore: avoid_print
          print('${entry.key} $n chars: ${stopwatch.elapsedMicroseconds} us');
        }
        expect(times[1], lessThan(times[0] * 40 + 20000), reason: entry.key);
        expect(times[2], lessThan(times[1] * 40 + 20000), reason: entry.key);
      }
    });

    test('null, empty or invalid nonce leaves the html identical', () {
      final template = _asset('summernote-no-plugins.html');
      final bad = <String?>[
        null,
        '',
        'has space',
        'has"quote',
        "has'quote",
        'semi;colon',
        'new\nline',
        'tag<bracket',
      ];
      for (final nonce in bad) {
        expect(NonceUtils.addNonceToScriptTags(template, nonce), template,
            reason: '$nonce');
      }
    });
  });

  group('NonceUtils → isValidNonce', () {
    test('accepts exactly the grammar, anchored at both ends', () {
      expect(NonceUtils.isValidNonce(_nonce), isTrue);
      expect(NonceUtils.isValidNonce('a'), isTrue);
      for (final bad in <String?>[null, '', ' abc', 'abc ', 'ab\tc', '"', 'abc\ndef']) {
        expect(NonceUtils.isValidNonce(bad), isFalse, reason: '$bad');
      }
    });

    test('stays linear on a 1 MB invalid string', () {
      final invalid = '${'A' * (1024 * 1024 - 1)}"';

      final stopwatch = Stopwatch()..start();
      final result = NonceUtils.isValidNonce(invalid);
      stopwatch.stop();

      // ignore: avoid_print
      print('isValidNonce on 1 MB invalid string: ${stopwatch.elapsedMilliseconds} ms');
      expect(result, isFalse);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
