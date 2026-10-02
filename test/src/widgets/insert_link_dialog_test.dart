import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/src/widgets/insert_link_dialog.dart';

void main() {
  late List<String> insertedUrls;

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => InsertLinkDialog(
            context: context,
            onInsert: (text, url, openNewTab) => insertedUrls.add(url),
          ).show(),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> submitUrl(WidgetTester tester, String url) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL'),
      url,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  setUp(() => insertedUrls = []);

  group('InsertLinkDialog', () {
    testWidgets('rejects a dangerous URL and stays open', (tester) async {
      await openDialog(tester);
      await submitUrl(tester, 'javascript:alert(1)');

      expect(insertedUrls, isEmpty);
      expect(find.text('This type of link is not allowed!'), findsOneWidget);
      expect(find.text('Insert Link'), findsOneWidget);
    });

    testWidgets('inserts a safe URL and closes', (tester) async {
      await openDialog(tester);
      await submitUrl(tester, 'https://example.com');

      expect(insertedUrls, ['https://example.com']);
      expect(find.text('Insert Link'), findsNothing);
    });
  });
}
