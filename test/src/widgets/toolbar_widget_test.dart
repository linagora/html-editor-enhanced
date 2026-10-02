@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class _RecordingHtmlEditorController extends HtmlEditorController {
  final List<String> insertedUrls = [];

  @override
  void insertLink(String text, String url, bool isNewWindow) =>
      insertedUrls.add(url);
}

void main() {
  late _RecordingHtmlEditorController controller;

  Future<void> submitUrlFromToolbar(WidgetTester tester, String url) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ToolbarWidget(
          controller: controller,
          htmlToolbarOptions: const HtmlToolbarOptions(
            defaultToolbarButtons: [
              InsertButtons(
                picture: false,
                audio: false,
                video: false,
                table: false,
                hr: false,
              ),
            ],
          ),
          callbacks: null,
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.link));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL'),
      url,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  setUp(() => controller = _RecordingHtmlEditorController());

  group('ToolbarWidget → insert link dialog', () {
    testWidgets('rejects a dangerous URL and stays open', (tester) async {
      await submitUrlFromToolbar(tester, 'javascript:alert(1)');

      expect(controller.insertedUrls, isEmpty);
      expect(find.text('This type of link is not allowed!'), findsOneWidget);
      expect(find.text('Insert Link'), findsOneWidget);
    });

    testWidgets('inserts a safe URL and closes', (tester) async {
      await submitUrlFromToolbar(tester, 'https://example.com');

      expect(controller.insertedUrls, ['https://example.com']);
      expect(find.text('Insert Link'), findsNothing);
    });
  });
}
