import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

void main() => runApp(const HtmlEditorExampleApp());

class HtmlEditorExampleApp extends StatelessWidget {
  const HtmlEditorExampleApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      home: const HtmlEditorExample(title: 'Flutter HTML Editor Example'),
    );
  }
}

class HtmlEditorExample extends StatefulWidget {
  const HtmlEditorExample({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HtmlEditorExample> createState() => _HtmlEditorExampleState();
}

class _HtmlEditorExampleState extends State<HtmlEditorExample> {
  String result = '';
  final HtmlEditorController controller = HtmlEditorController();
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          controller.clearFocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (kIsWeb) {
                    controller.reloadWeb();
                  } else {
                    controller.editorController!.reload();
                  }
                })
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            controller.toggleCodeView();
          },
          child: const Text(r'<\>',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              HtmlEditor(
                controller: controller,
                htmlEditorOptions: const HtmlEditorOptions(
                  hint: 'Your text here...',
                  shouldEnsureVisible: true,
                  //initialText: "<p>text content initial, if any</p>",
                ),
                htmlToolbarOptions: HtmlToolbarOptions(
                  toolbarPosition: ToolbarPosition.aboveEditor, //by default
                  toolbarType: ToolbarType.nativeScrollable, //by default
                  onButtonPressed:
                      (ButtonType type, bool? status, Function? updateStatus) {
                    debugPrint(
                        "button '${describeEnum(type)}' pressed, the current selected status is $status");
                    return true;
                  },
                  onDropdownChanged: (DropdownType type, dynamic changed,
                      Function(dynamic)? updateSelectedItem) {
                    debugPrint(
                        "dropdown '${describeEnum(type)}' changed to $changed");
                    return true;
                  },
                  mediaLinkInsertInterceptor:
                      (String url, InsertFileType type) {
                    debugPrint('url $url');
                    return true;
                  },
                  mediaUploadInterceptor:
                      (PlatformFile file, InsertFileType type) async {
                    debugPrint('fileName ${file.name}'); //filename
                    debugPrint('fileSize ${file.size}'); //size in bytes
                    debugPrint('fileExtension ${file.extension}'); //file extension (eg jpeg or mp4)
                    return true;
                  },
                ),
                otherOptions: const OtherOptions(height: 550),
                callbacks: Callbacks(onBeforeCommand: (String? currentHtml) {
                  debugPrint('html before change is $currentHtml');
                }, onChangeContent: (String? changed) {
                  debugPrint('content changed to $changed');
                }, onChangeCodeview: (String? changed) {
                  debugPrint('code changed to $changed');
                }, onChangeSelection: (EditorSettings settings) {
                  debugPrint('parent element is ${settings.parentElement}');
                  debugPrint('font name is ${settings.fontName}');
                }, onDialogShown: () {
                  debugPrint('dialog shown');
                }, onEnter: () {
                  debugPrint('enter/return pressed');
                }, onFocus: () {
                  debugPrint('editor focused');
                }, onBlur: () {
                  debugPrint('editor unfocused');
                }, onBlurCodeview: () {
                  debugPrint('codeview either focused or unfocused');
                }, onInit: () {
                  debugPrint('init');
                },
                    //this is commented because it overrides the default Summernote handlers
                    /*onImageLinkInsert: (String? url) {
                    debugPrint(url ?? "unknown url");
                  },
                  onImageUpload: (FileUpload file) async {
                    debugPrint(file.name);
                    debugPrint(file.size);
                    debugPrint(file.type);
                    debugPrint(file.base64);
                  },*/
                    onImageUploadError: (FileUpload? file, String? base64Str,
                        UploadError error) {
                  debugPrint(describeEnum(error));
                  debugPrint(base64Str ?? '');
                  if (file != null) {
                    debugPrint('fileName ${file.name}');
                    debugPrint('fileName ${file.size}');
                    debugPrint('fileType ${file.type}');
                  }
                }, onKeyDown: (int? keyCode) {
                  debugPrint('$keyCode key downed');
                  debugPrint(
                      'current character count: ${controller.characterCount}');
                }, onKeyUp: (int? keyCode) {
                  debugPrint('$keyCode key released');
                }, onMouseDown: () {
                  debugPrint('mouse downed');
                }, onMouseUp: () {
                  debugPrint('mouse released');
                }, onNavigationRequestMobile: (String url) {
                  debugPrint('url $url');
                  return NavigationActionPolicy.ALLOW;
                }, onPaste: () {
                  debugPrint('pasted into editor');
                }, onScroll: () {
                  debugPrint('editor scrolled');
                }, onEditLink: (String? urlDisplayText, String? url, bool? isOpenInNewTab, String linkTagId) async {
                  debugPrint('urlDisplayText: $urlDisplayText, url: $url, isOpenInNewTab: $isOpenInNewTab, linkTagId: $linkTagId');
                  final textLinkDialogController = TextEditingController(text: urlDisplayText);
                  final urlLinkDialogController = TextEditingController(text: url);
                  final textLinkDialogFocusNode = FocusNode();
                  final urlLinkDialogFocusNode = FocusNode();
                  final formKeyDialog = GlobalKey<FormState>();
                  var isOpenNewTabLinkDialog = isOpenInNewTab ?? true;
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PointerInterceptor(
                          child: StatefulBuilder(
                            builder: (BuildContext contest, StateSetter setState) {
                              return AlertDialog(
                                title: const Text('Insert Link'),
                                scrollable: true,
                                content: Form(
                                  key: formKeyDialog,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Text to display',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: textLinkDialogController,
                                        focusNode: textLinkDialogFocusNode,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          hintText: urlDisplayText
                                        ),
                                        onSubmitted: (_) {
                                          urlLinkDialogFocusNode.requestFocus();
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'URL',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: urlLinkDialogController,
                                        focusNode: urlLinkDialogFocusNode,
                                        textInputAction: TextInputAction.done,
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          hintText: url
                                        ),
                                        validator: (String? value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a URL';
                                          }
                                          return null;
                                        },
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 48.0,
                                            width: 24.0,
                                            child: Checkbox(
                                              value: isOpenNewTabLinkDialog,
                                              activeColor: const Color(0xFF827250),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isOpenNewTabLinkDialog = value!;
                                                });
                                              },
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).dialogBackgroundColor,
                                              padding: const EdgeInsets.only(
                                                left: 5.0,
                                                right: 5.0
                                              )
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                isOpenNewTabLinkDialog = !isOpenNewTabLinkDialog;
                                              });
                                            },
                                            child: Text(
                                              'Open in new tab',
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyLarge?.color
                                              )
                                            )
                                          )
                                        ],
                                      )
                                    ],
                                  )
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel')
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (formKeyDialog.currentState!.validate()) {
                                        const htmlToolbarOptions = HtmlToolbarOptions();
                                        var proceed = await htmlToolbarOptions.linkInsertInterceptor?.call(
                                          textLinkDialogController.text.isEmpty
                                            ? urlLinkDialogController.text
                                            : textLinkDialogController.text,
                                          urlLinkDialogController.text,
                                          isOpenNewTabLinkDialog
                                        ) ?? true;
                                        if (proceed) {
                                          controller.updateLink(
                                            textLinkDialogController.text.isEmpty
                                              ? urlLinkDialogController.text
                                              : textLinkDialogController.text,
                                            urlLinkDialogController.text,
                                            isOpenNewTabLinkDialog,
                                            linkTagId
                                          );
                                        }
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                                    child: const Text('OK')
                                  )
                                ],
                              );
                            },
                          )
                        );
                      }
                    );
                  }
                }),
                plugins: [
                  SummernoteAtMention(
                      getSuggestionsMobile: (String value) {
                        var mentions = <String>['test1', 'test2', 'test3'];
                        return mentions
                            .where((element) => element.contains(value))
                            .toList();
                      },
                      mentionsWeb: ['test1', 'test2', 'test3'],
                      onSelect: (String value) {
                        debugPrint(value);
                      }),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        controller.undo();
                      },
                      child: const Text('Undo',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        controller.clear();
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () async {
                        var txt = await controller.getText();
                        if (txt.contains('src=\"data:')) {
                          txt =
                              '<text removed due to base-64 data, displaying the text could cause the app to crash>';
                        }
                        setState(() {
                          result = txt;
                        });
                      },
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        controller.redo();
                      },
                      child: const Text(
                        'Redo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(result),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        controller.disable();
                      },
                      child: const Text('Disable',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () async {
                        controller.enable();
                      },
                      child: const Text(
                        'Enable',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        controller.insertText('Google');
                      },
                      child: const Text('Insert Text',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        controller.insertHtml(
                            '''<p style="color: blue">Google in blue</p>''');
                      },
                      child: const Text('Insert HTML',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () async {
                        controller.insertLink(
                            'Google linked', 'https://google.com', true);
                      },
                      child: const Text(
                        'Insert Link',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        controller.insertNetworkImage(
                            'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
                            filename: 'Google network image');
                      },
                      child: const Text(
                        'Insert network image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        controller.addNotification(
                            'Info notification', NotificationType.info);
                      },
                      child: const Text('Info',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        controller.addNotification(
                            'Warning notification', NotificationType.warning);
                      },
                      child: const Text('Warning',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () async {
                        controller.addNotification(
                            'Success notification', NotificationType.success);
                      },
                      child: const Text(
                        'Success',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        controller.addNotification(
                            'Danger notification', NotificationType.danger);
                      },
                      child: const Text(
                        'Danger',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        controller.addNotification('Plaintext notification',
                            NotificationType.plaintext);
                      },
                      child: const Text('Plaintext',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary),
                      onPressed: () async {
                        controller.removeNotification();
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
