import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/html_editor_controller_unsupported.dart'
    as unsupported;
import 'package:html_editor_enhanced/src/model/default_transfer_method.dart';
import 'package:html_editor_enhanced/src/model/transfer_event_data.dart';
import 'package:html_editor_enhanced/src/model/transfer_method.dart';
import 'package:html_editor_enhanced/src/model/transfer_type.dart';
import 'package:meta/meta.dart';

/// Controller for web
class HtmlEditorController extends unsupported.HtmlEditorController {
  final _jsonEncoder = const JsonEncoder();

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
    _evaluateJavascriptWeb(method: DefaultTransferMethod.getText.method);
    final eventData = await _getEventDataOnMessageToDart(method: DefaultTransferMethod.getText.method);
    String text = eventData?.data ?? '';
    if (processOutputHtml &&
        (text.isEmpty ||
            text == '<p></p>' ||
            text == '<p><br></p>' ||
            text == '<p><br/></p>')) text = '';
    return text;
  }

  /// Gets the text with signature content from the editor and returns it as a [String].
  @override
  Future<String> getTextWithSignatureContent() async {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.getTextWithSignatureContent.method);
    final eventData = await _getEventDataOnMessageToDart(method: DefaultTransferMethod.getTextWithSignatureContent.method);
    String text = eventData?.data ?? '';
    if (processOutputHtml &&
        (text.isEmpty ||
            text == '<p></p>' ||
            text == '<p><br></p>' ||
            text == '<p><br/></p>')) text = '';
    return text;
  }

  @override
  Future<String> getSelectedTextWeb({bool withHtmlTags = false}) async {
    final method = withHtmlTags
      ? DefaultTransferMethod.getSelectedTextHtml.method
      : DefaultTransferMethod.getSelectedText.method;
    _evaluateJavascriptWeb(method: method);
    final eventData = await _getEventDataOnMessageToDart(method: method);
    String text = eventData?.data ?? '';
    return text;
  }

  /// Sets the text of the editor. Some pre-processing is applied to convert
  /// [String] elements like "\n" to HTML elements.
  @override
  void setText(String text) {
    text = _processHtml(html: text);
    _evaluateJavascriptWeb(method: DefaultTransferMethod.setText.method, data: text);
  }

  /// Sets the editor to full-screen mode.
  @override
  void setFullScreen() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.setFullScreen.method);
  }

  /// isFullScreen mode in the Html editor
  @override
  Future<bool> isFullScreen() async {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.isFullScreen.method);
    final eventData = await _getEventDataOnMessageToDart(method: DefaultTransferMethod.isFullScreen.method);
    bool value = eventData?.data ?? false;
    return value;
  }

  /// Sets the focus to the editor.
  @override
  void setFocus() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.setFocus.method);
  }

  /// Clears the editor of any text.
  @override
  void clear() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.clear.method);
  }

  /// Sets the hint for the editor.
  @override
  void setHint(String text) {
    text = _processHtml(html: text);
    _evaluateJavascriptWeb(method: DefaultTransferMethod.setHint.method, data: text);
  }

  /// toggles the codeview in the Html editor
  @override
  void toggleCodeView() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.toggleCodeView.method);
  }

  /// isActivated the codeView in the Html editor
  @override
  Future<bool> isActivatedCodeView() async {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.isActivatedCodeView.method);
    final eventData = await _getEventDataOnMessageToDart(method: DefaultTransferMethod.isActivatedCodeView.method);
    bool isActivated = eventData?.data ?? false;
    return isActivated;
  }

  /// disables the Html editor
  @override
  void disable() {
    toolbar!.disable();
    _evaluateJavascriptWeb(method: DefaultTransferMethod.disable.method);
  }

  /// enables the Html editor
  @override
  void enable() {
    toolbar!.enable();
    _evaluateJavascriptWeb(method: DefaultTransferMethod.enable.method);
  }

  /// Undoes the last action
  @override
  void undo() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.undo.method);
  }

  /// Redoes the last action
  @override
  void redo() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.redo.method);
  }

  /// Insert text at the end of the current HTML content in the editor
  /// Note: This method should only be used for plaintext strings
  @override
  void insertText(String text) {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.insertText.method, data: text);
  }

  /// Insert HTML at the position of the cursor in the editor
  /// Note: This method should not be used for plaintext strings
  @override
  void insertHtml(String html) {
    html = _processHtml(html: html);
    _evaluateJavascriptWeb(method: DefaultTransferMethod.insertHtml.method, data: html);
  }

  /// Insert a network image at the position of the cursor in the editor
  @override
  void insertNetworkImage(String url, {String filename = ''}) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.insertNetworkImage.method,
      data: {
        'url': url,
        'filename': filename
      }
    );
  }

  /// Insert a link at the position of the cursor in the editor
  @override
  void insertLink(String text, String url, bool isNewWindow) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.insertLink.method,
      data: {
        'text': text,
        'url': url,
        'isNewWindow': isNewWindow
      }
    );
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
    _evaluateJavascriptWeb(method: DefaultTransferMethod.reload.method);
  }

  /// Recalculates the height of the editor to remove any vertical scrolling.
  /// This method will not do anything if [autoAdjustHeight] is turned off.
  @override
  void recalculateHeight() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.getHeight.method);
  }

  /// A function to quickly call a document.execCommand function in a readable format
  @override
  void execCommand(String command, {String? argument}) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.execCommand.method,
      data: {
        'command': command,
        'argument': argument
      }
    );
  }

  /// A function to quickly call a Summernote API function in a readable format
  @override
  void execSummernoteAPI(String nameAPI, {String? value}) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.execSummernoteAPI.method,
      data: {
        'nameAPI': nameAPI,
        'value': value
      }
    );
  }

  /// A function to set font size for text selected
  @override
  void setFontSize(int size) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.setFontSize.method,
      data: size
    );
  }

  /// A function to execute JS passed as a [WebScript] to the editor. This should
  /// only be used on Flutter Web.
  @override
  Future<dynamic> evaluateJavascriptWeb(String name,
      {bool hasReturnValue = false}) async {
    final transferMethod = TransferMethod(name);
    _evaluateJavascriptWeb(method: transferMethod);
    if (hasReturnValue) {
      final eventData = await _getEventDataOnMessageToDart(method: transferMethod);
      return eventData;
    }
  }

  /// Internal function to change list style on Web
  @override
  void changeListStyle(String changed) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.changeListStyle.method,
      data: changed
    );
  }

  /// Internal function to change line height on Web
  @override
  void changeLineHeight(String changed) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.changeLineHeight.method,
      data: changed
    );
  }

  /// Internal function to change text direction on Web
  @override
  void changeTextDirection(String direction) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.changeTextDirection.method,
      data: direction
    );
  }

  /// Internal function to change case on Web
  @override
  void changeCase(String changed) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.changeCase.method,
      data: changed
    );
  }

  /// Internal function to insert table on Web
  @override
  void insertTable(String dimensions) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.insertTable.method,
      data: dimensions
    );
  }

  /// Add a notification to the bottom of the editor. This is styled similar to
  /// Bootstrap alerts. You can set the HTML to be displayed in the alert,
  /// and the notificationType determines how the alert is displayed.
  @override
  void addNotification(String html, NotificationType notificationType) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.addNotification.method,
      data: {
        'html': html,
        if (notificationType != NotificationType.plaintext) 'alertType': 'alert alert-${notificationType.name}'
      }
    );
    recalculateHeight();
  }

  /// Remove the current notification from the bottom of the editor
  @override
  void removeNotification() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.removeNotification.method);
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
  void _evaluateJavascriptWeb({
    required TransferMethod method,
    TransferType type = TransferType.toIframe,
    dynamic data,
  }) async {
    if (!kIsWeb) {
      throw Exception(
        'Non-Flutter Web environment detected, please make sure you are importing package:html_editor_enhanced/html_editor.dart');
    }

    if (_viewId == null) return;

    final eventData = TransferEventData(
      id: _viewId!,
      type: type,
      method: method,
      data: data
    );
    debugPrint('HtmlEditorController::_evaluateJavascriptWeb: EventData = $eventData');
    _sendEventData(eventData);
  }

  @override
  void insertSignature(String signature) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.insertSignature.method,
      data: signature
    );
  }

  @override
  void removeSignature() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.removeSignature.method);
  }

  @override
  void updateBodyDirection(String direction) {
    _evaluateJavascriptWeb(
      method: DefaultTransferMethod.updateBodyDirection.method,
      data: direction
    );
  }

  @override
  void setOnDragDropEvent() {
    _evaluateJavascriptWeb(method: DefaultTransferMethod.onDragDropEvent.method);
  }

  void _sendEventData(TransferEventData eventData) {
    html.window.postMessage(_jsonEncoder.convert(eventData.toJson()), '*');
  }

  Future<TransferEventData?> _getEventDataOnMessageToDart({required TransferMethod method}) async {
    try {
      final messageEvent = await html.window.onMessage.firstWhere((event) {
        final transferEventData = TransferEventData.fromJson(jsonDecode(event.data));
        return transferEventData.type == TransferType.toDart 
          && transferEventData.method == method;
      });
      final eventData = TransferEventData.fromJson(jsonDecode(messageEvent.data));
      return eventData;
    } catch (e) {
      debugPrint('HtmlEditorController::_parsingEventDataFromOnMessage:Exception = $e');
      return null;
    }
  }
}
