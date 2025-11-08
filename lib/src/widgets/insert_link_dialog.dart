import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

typedef OnInsertLink = void Function(
  String text,
  String url,
  bool openNewTab,
);

typedef LinkInsertInterceptor = Future<bool> Function(
  String text,
  String url,
  bool openNewTab,
);

class InsertLinkDialog {
  final BuildContext context;
  final LinkInsertInterceptor? linkInsertInterceptor;
  final OnInsertLink onInsert;

  InsertLinkDialog({
    required this.context,
    required this.onInsert,
    this.linkInsertInterceptor,
  });

  Future<void> show() async {
    final textController = TextEditingController();
    final urlController = TextEditingController();
    final textFocus = FocusNode();
    final urlFocus = FocusNode();
    final formKey = GlobalKey<FormState>();
    var openNewTab = false;

    await showDialog(
      context: context,
      builder: (context) {
        return PointerInterceptor(
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Insert Link'),
                scrollable: true,
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Text to display',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: textController,
                        focusNode: textFocus,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Text',
                        ),
                        onSubmitted: (_) => urlFocus.requestFocus(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'URL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: urlController,
                        focusNode: urlFocus,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'URL',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a URL!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            height: 48.0,
                            width: 24.0,
                            child: Checkbox(
                              value: openNewTab,
                              activeColor: const Color(0xFF827250),
                              onChanged: (value) {
                                setState(() => openNewTab = value ?? false);
                              },
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => openNewTab = !openNewTab);
                            },
                            child: Text(
                              'Open in new window',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final displayText = textController.text.isEmpty
                            ? urlController.text
                            : textController.text;
                        final url = urlController.text;

                        final proceed = await linkInsertInterceptor?.call(
                              displayText,
                              url,
                              openNewTab,
                            ) ??
                            true;

                        if (proceed) {
                          onInsert(displayText, url, openNewTab);
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
