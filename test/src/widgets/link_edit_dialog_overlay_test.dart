@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/src/widgets/link_edit_dialog_overlay.dart';
import 'package:html_editor_enhanced/utils/web_utils.dart';
import 'package:web/web.dart' as web;

void main() {
  const rejectedUrlErrorText = 'This type of link is not allowed!';
  const animationDuration = Duration(milliseconds: 300);

  Future<void> openOverlay(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox.shrink();
      }),
    ));
    LinkEditDialogOverlay().show(
      context: context,
      rect: web.DOMRect(0, 0, 10, 10),
    );
    await tester.pump(animationDuration);
  }

  Future<void> applyUrl(WidgetTester tester, String url) async {
    await tester.enterText(find.byType(TextField).last, url);
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pump(animationDuration);
  }

  group('LinkEditDialogOverlay → apply', () {
    testWidgets(
      'keeps the overlay open with an error on a rejected URL',
      (tester) async {
        final postedUrls = <String?>[];
        final subscription = web.window.onMessage
            .map(WebUtils.convertMessageEventToDataMap)
            .where((data) => data['type'] == 'toIframe: updateLink')
            .listen((data) => postedUrls.add(data['url'] as String?));
        addTearDown(subscription.cancel);

        await openOverlay(tester);
        await applyUrl(tester, 'javascript:alert(1)');

        expect(find.text(rejectedUrlErrorText), findsOneWidget);
        expect(find.text('Apply'), findsOneWidget);

        await tester.enterText(find.byType(TextField).last, 'https://e.com');
        await tester.pump();
        expect(find.text(rejectedUrlErrorText), findsNothing);

        await tester.tap(find.text('Apply'));
        await tester.pump(animationDuration);
        expect(find.text('Apply'), findsNothing);

        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        expect(postedUrls, ['https://e.com']);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    testWidgets(
      'rejects a URL whose scheme a browser reads as javascript: after '
      'stripping a tab',
      (tester) async {
        final postedUrls = <String?>[];
        final subscription = web.window.onMessage
            .map(WebUtils.convertMessageEventToDataMap)
            .where((data) => data['type'] == 'toIframe: updateLink')
            .listen((data) => postedUrls.add(data['url'] as String?));
        addTearDown(subscription.cancel);

        await openOverlay(tester);
        await applyUrl(tester, 'java\tscript:alert(1)');

        expect(find.text(rejectedUrlErrorText), findsOneWidget);
        expect(find.text('Apply'), findsOneWidget);

        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        expect(postedUrls, isEmpty);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
