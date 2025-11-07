import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/html_editor_controller_unsupported.dart'
    as unsupported;
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

/// Controller for web
class HtmlEditorController extends unsupported.HtmlEditorController {
  HtmlEditorController({
    super.processInputHtml = true,
    super.processNewLineAsBr = false,
    super.processOutputHtml = true,
  });

  /// Manages the view ID for the [HtmlEditorController] on web
  String? _viewId;

  /// Internal method to set the view ID when iframe initialization
  /// is complete
  @override
  @internal
  set viewId(String? viewId) => _viewId = viewId;

  /// Gets the text from the editor and returns it as a [String].
  @override
  Future<String> getText() async {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: getText'});

    final event = await web.window.onMessage.firstWhere((event) {
      final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
      return data['type'] == 'toDart: getText';
    });
    final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
    String text = data['text'];

    if (processOutputHtml &&
        (text.isEmpty ||
            text == '<p></p>' ||
            text == '<p><br></p>' ||
            text == '<p><br/></p>')) {
      text = '';
    }
    return text;
  }

  /// Gets the text with signature content from the editor and returns it as a [String].
  @override
  Future<String> getTextWithSignatureContent() async {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: getTextWithSignatureContent'});

    final event = await web.window.onMessage.firstWhere((event) {
      final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
      return data['type'] == 'toDart: getTextWithSignatureContent';
    });
    final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
    String text = data['text'];

    if (processOutputHtml &&
        (text.isEmpty ||
            text == '<p></p>' ||
            text == '<p><br></p>' ||
            text == '<p><br/></p>')) {
      text = '';
    }
    return text;
  }

  @override
  Future<String> getSelectedTextWeb({bool withHtmlTags = false}) async {
    if (withHtmlTags) {
      _evaluateJavascriptWeb(data: {'type': 'toIframe: getSelectedTextHtml'});
    } else {
      _evaluateJavascriptWeb(data: {'type': 'toIframe: getSelectedText'});
    }
    final event = await web.window.onMessage.firstWhere((event) {
      final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
      return data['type'] == 'toDart: getSelectedText';
    });
    final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
    String selectedText = data['text'];
    return selectedText;
  }

  /// Sets the text of the editor. Some pre-processing is applied to convert
  /// [String] elements like "\n" to HTML elements.
  @override
  void setText(String text) {
    text = _processHtml(html: text);
    _evaluateJavascriptWeb(data: {'type': 'toIframe: setText', 'text': text});
  }

  /// Sets the editor to full-screen mode.
  @override
  void setFullScreen() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: setFullScreen'});
  }

  /// isFullScreen mode in the Html editor
  @override
  Future<bool> isFullScreen() async {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: isFullScreen'});
    final event = await web.window.onMessage.firstWhere((event) {
      final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
      return data['type'] == 'toDart: isFullScreen';
    });
    final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
    bool isFullScreen = data['value'];
    return isFullScreen;
  }

  /// Sets the focus to the editor.
  @override
  void setFocus() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: setFocus'});
  }

  /// Clears the editor of any text.
  @override
  void clear() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: clear'});
  }

  /// Sets the hint for the editor.
  @override
  void setHint(String text) {
    text = _processHtml(html: text);
    _evaluateJavascriptWeb(data: {'type': 'toIframe: setHint', 'text': text});
  }

  /// toggles the codeview in the Html editor
  @override
  void toggleCodeView() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: toggleCodeview'});
  }

  /// isActivated the codeView in the Html editor
  @override
  Future<bool> isActivatedCodeView() async {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: isActivatedCodeView'});
    final event = await web.window.onMessage.firstWhere((event) {
      final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
      return data['type'] == 'toDart: isActivatedCodeView';
    });
    final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
    bool isActivated = data['value'];
    return isActivated;
  }

  /// disables the Html editor
  @override
  void disable() {
    toolbar!.disable();
    _evaluateJavascriptWeb(data: {'type': 'toIframe: disable'});
  }

  /// enables the Html editor
  @override
  void enable() {
    toolbar!.enable();
    _evaluateJavascriptWeb(data: {'type': 'toIframe: enable'});
  }

  /// Undoes the last action
  @override
  void undo() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: undo'});
  }

  /// Redoes the last action
  @override
  void redo() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: redo'});
  }

  /// Insert text at the end of the current HTML content in the editor
  /// Note: This method should only be used for plaintext strings
  @override
  void insertText(String text) {
    _evaluateJavascriptWeb(
        data: {'type': 'toIframe: insertText', 'text': text});
  }

  /// Insert HTML at the position of the cursor in the editor
  /// Note: This method should not be used for plaintext strings
  @override
  void insertHtml(String html) {
    html = _processHtml(html: html);
    _evaluateJavascriptWeb(
        data: {'type': 'toIframe: insertHtml', 'html': html});
  }

  /// Insert a network image at the position of the cursor in the editor
  @override
  void insertNetworkImage(String url, {String filename = ''}) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: insertNetworkImage',
      'url': url,
      'filename': filename
    });
  }

  /// Insert a link at the position of the cursor in the editor
  @override
  void insertLink(String text, String url, bool isNewWindow) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: insertLink',
      'text': text,
      'url': url,
      'isNewWindow': isNewWindow
    });
  }

  /// Clears the focus from the webview by hiding the keyboard, calling the
  /// clearFocus method on the [InAppWebViewController], and resetting the height
  /// in case it was changed.
  @override
  void clearFocus() {
    throw Exception(
        'Flutter Web environment detected, please make sure you are importing package:html_editor_enhanced/html_editor.dart and check kIsWeb before calling this method.');
  }

  /// Resets the height of the editor back to the original if it was changed to
  /// accommodate the keyboard. This should only be used on mobile, and only
  /// when [adjustHeightForKeyboard] is enabled.
  @override
  void resetHeight() {
    throw Exception(
        'Flutter Web environment detected, please make sure you are importing package:html_editor_enhanced/html_editor.dart and check kIsWeb before calling this method.');
  }

  /// Refresh the page
  ///
  /// Note: This should only be used in Flutter Web!!!
  @override
  void reloadWeb() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: reload'});
  }

  /// Recalculates the height of the editor to remove any vertical scrolling.
  /// This method will not do anything if [autoAdjustHeight] is turned off.
  @override
  void recalculateHeight() {}

  /// A function to quickly call a document.execCommand function in a readable format
  @override
  void execCommand(String command, {String? argument}) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: execCommand',
      'command': command,
      'argument': argument
    });
  }

  /// A function to quickly call a Summernote API function in a readable format
  @override
  void execSummernoteAPI(String nameAPI, {String? value}) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: execSummernoteAPI',
      'nameAPI': nameAPI,
      'value': value
    });
  }

  /// A function to set font size for text selected
  @override
  void setFontSize(int size) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: setFontSize',
      'size': size
    });
  }

  /// A function to execute JS passed as a [WebScript] to the editor. This should
  /// only be used on Flutter Web.
  @override
  Future<dynamic> evaluateJavascriptWeb(String name,
      {bool hasReturnValue = false}) async {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: $name'});
    if (hasReturnValue) {
      final event = await web.window.onMessage.firstWhere((event) {
        final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
        return data['type'] == 'toDart: $name';
      });
      final data = HtmlEditorUtils.convertMessageEventToDataMap(event);
      return data;
    }
  }

  /// Internal function to change list style on Web
  @override
  void changeListStyle(String changed) {
    _evaluateJavascriptWeb(
        data: {'type': 'toIframe: changeListStyle', 'changed': changed});
  }

  /// Internal function to change line height on Web
  @override
  void changeLineHeight(String changed) {
    _evaluateJavascriptWeb(
        data: {'type': 'toIframe: changeLineHeight', 'changed': changed});
  }

  /// Internal function to change text direction on Web
  @override
  void changeTextDirection(String direction) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: changeTextDirection',
      'direction': direction
    });
  }

  /// Internal function to change case on Web
  @override
  void changeCase(String changed) {
    _evaluateJavascriptWeb(
        data: {'type': 'toIframe: changeCase', 'case': changed});
  }

  /// Internal function to insert table on Web
  @override
  void insertTable(String dimensions) {
    _evaluateJavascriptWeb(
        data: {'type': 'toIframe: insertTable', 'dimensions': dimensions});
  }

  /// Add a notification to the bottom of the editor. This is styled similar to
  /// Bootstrap alerts. You can set the HTML to be displayed in the alert,
  /// and the notificationType determines how the alert is displayed.
  @override
  void addNotification(String html, NotificationType notificationType) {
    if (notificationType == NotificationType.plaintext) {
      _evaluateJavascriptWeb(
          data: {'type': 'toIframe: addNotification', 'html': html});
    } else {
      _evaluateJavascriptWeb(data: {
        'type': 'toIframe: addNotification',
        'html': html,
        'alertType': 'alert alert-${notificationType.name}'
      });
    }
    recalculateHeight();
  }

  /// Remove the current notification from the bottom of the editor
  @override
  void removeNotification() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: removeNotification'});
    recalculateHeight();
  }

  /// Helper function to process input html
  String _processHtml({required html}) {
    if (processInputHtml) {
      html = html.replaceAll('\r', '').replaceAll('\r\n', '');
    }
    if (processNewLineAsBr) {
      html = html.replaceAll('\n', '<br/>').replaceAll('\n\n', '<br/>');
    } else {
      html = html.replaceAll('\n', '').replaceAll('\n\n', '');
    }
    return html;
  }

  /// Helper function to run javascript and check current environment
  void _evaluateJavascriptWeb({required Map<String, Object?> data}) async {
    if (kIsWeb) {
      data['view'] = _viewId;
      const jsonEncoder = JsonEncoder();
      var json = jsonEncoder.convert(data);
      web.window.postMessage(json.jsify(), '*'.toJS);
    } else {
      throw Exception(
          'Non-Flutter Web environment detected, please make sure you are importing package:html_editor_enhanced/html_editor.dart');
    }
  }

  @override
  void insertSignature(String signature, {bool allowCollapsed = true}) {
    _evaluateJavascriptWeb(
      data: {
        'type': 'toIframe: insertSignature',
        'signature': signature,
        'allowCollapsed': allowCollapsed,
      }
    );
  }

  @override
  void removeSignature() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: removeSignature'});
  }

  @override
  void updateBodyDirection(String direction) {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: updateBodyDirection', 'direction': direction});
  }

  @override
  void setOnDragDropEvent() {
    _evaluateJavascriptWeb(data: {'type': 'toIframe: onDragDropEvent'});
  }

  @override
  void insertImage(String source) {
    _evaluateJavascriptWeb(data: {
      'type': 'toIframe: insertImage',
      'source': source,
    });
  }
}
