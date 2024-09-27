export 'dart:html';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/model/default_transfer_method.dart';
import 'package:html_editor_enhanced/src/model/event_data_properties.dart';
import 'package:html_editor_enhanced/src/model/transfer_event_data.dart';
import 'package:html_editor_enhanced/src/model/transfer_type.dart';
import 'package:html_editor_enhanced/utils/javascript_utils.dart';
import 'package:html_editor_enhanced/utils/utils.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:html_editor_enhanced/utils/shims/dart_ui.dart' as ui;

/// The HTML Editor widget itself, for web (uses IFrameElement)
class HtmlEditorWidget extends StatefulWidget {
  const HtmlEditorWidget({
    Key? key,
    required this.controller,
    this.callbacks,
    required this.plugins,
    required this.htmlEditorOptions,
    required this.htmlToolbarOptions,
    required this.otherOptions,
    required this.initBC,
  }) : super(key: key);

  final HtmlEditorController controller;
  final Callbacks? callbacks;
  final List<Plugins> plugins;
  final HtmlEditorOptions htmlEditorOptions;
  final HtmlToolbarOptions htmlToolbarOptions;
  final OtherOptions otherOptions;
  final BuildContext initBC;

  @override
  State<HtmlEditorWidget> createState() => _HtmlEditorWidgetWebState();
}

/// State for the web Html editor widget
///
/// A stateful widget is necessary here, otherwise the IFrameElement will be
/// rebuilt excessively, hurting performance
class _HtmlEditorWidgetWebState extends State<HtmlEditorWidget> {
  /// The view ID for the IFrameElement. Must be unique.
  late String createdViewId;

  /// The actual height of the editor, used to automatically set the height
  late double actualHeight;

  /// A Future that is observed by the [FutureBuilder]. We don't use a function
  /// as the Future on the [FutureBuilder] because when the widget is rebuilt,
  /// the function may be excessively called, hurting performance.
  Future<bool>? summernoteInit;

  /// Helps get the height of the toolbar to accurately adjust the height of
  /// the editor when the keyboard is visible.
  GlobalKey toolbarKey = GlobalKey();

  /// Tracks whether the editor was disabled onInit (to avoid re-disabling on reload)
  bool alreadyDisabled = false;

  final _jsonEncoder = const JsonEncoder();

  StreamSubscription<html.MessageEvent>? _onWindowMessageStreamSubscription;

  @override
  void initState() {
    actualHeight = widget.otherOptions.height;
    createdViewId = getRandString(10);
    widget.controller.viewId = createdViewId;
    initSummernote();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant HtmlEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otherOptions.dropZoneWidth != oldWidget.otherOptions.dropZoneWidth ||
        widget.otherOptions.dropZoneHeight != oldWidget.otherOptions.dropZoneHeight) {
      _setDimensionDropZoneView(
        width: widget.otherOptions.dropZoneWidth,
        height: widget.otherOptions.dropZoneHeight,
      );
    }
  }

  void initSummernote() async {
    var headString = '';
    var summernoteCallbacks = '''callbacks: {
        onKeydown: function(e) {
            var chars = \$(".note-editable").text();
            var totalChars = chars.length;
            ${widget.htmlEditorOptions.characterLimit != null ? '''allowedKeys = (
                e.which === 8 ||  /* BACKSPACE */
                e.which === 35 || /* END */
                e.which === 36 || /* HOME */
                e.which === 37 || /* LEFT */
                e.which === 38 || /* UP */
                e.which === 39 || /* RIGHT*/
                e.which === 40 || /* DOWN */
                e.which === 46 || /* DEL*/
                e.ctrlKey === true && e.which === 65 || /* CTRL + A */
                e.ctrlKey === true && e.which === 88 || /* CTRL + X */
                e.ctrlKey === true && e.which === 67 || /* CTRL + C */
                e.ctrlKey === true && e.which === 86 || /* CTRL + V */
                e.ctrlKey === true && e.which === 90    /* CTRL + Z */
            );
            if (!allowedKeys && \$(e.target).text().length >= ${widget.htmlEditorOptions.characterLimit}) {
                e.preventDefault();
            }''' : ''}
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.characterCount.name}",
              "${EventDataProperties.data.name}": totalChars
            }), "*");
        },
    ''';
    var maximumFileSize = 10485760;
    for (var p in widget.plugins) {
      headString = '$headString${p.getHeadString()}\n';
      if (p is SummernoteAtMention) {
        summernoteCallbacks =
            '''$summernoteCallbacks            \nsummernoteAtMention: {
              getSuggestions: (value) => {
                const mentions = ${p.getMentionsWeb()};
                return mentions.filter((mention) => {
                  return mention.includes(value);
                });
              },
              onSelect: (value) => {
                window.parent.postMessage(JSON.stringify({
                  "${EventDataProperties.id.name}": "$createdViewId",
                  "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                  "${EventDataProperties.method.name}": "${DefaultTransferMethod.onSelectMention.name}",
                  "${EventDataProperties.data.name}": value
                }), "*");
              },
            },
          ''';
      }
    }
    if (widget.callbacks?.onImageLinkInsert != null) {
      summernoteCallbacks =
          '''$summernoteCallbacks          onImageLinkInsert: function(url) {
          window.parent.postMessage(JSON.stringify({
            "${EventDataProperties.id.name}": "$createdViewId",
            "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
            "${EventDataProperties.method.name}": "${DefaultTransferMethod.onImageLinkInsert.name}",
            "${EventDataProperties.data.name}": url
          }), "*");
        },
      ''';
    }
    if (widget.callbacks?.onImageUpload != null) {
      summernoteCallbacks =
          """$summernoteCallbacks          onImageUpload: function(files) {
          let listFileUploaded = [];
          let listFileFailed = [];
          var reader = new FileReader();  
          function readFile(index) {
            if (index >= files.length) {
              window.parent.postMessage(JSON.stringify({
                "id": "$createdViewId",
                "type": "${TransferType.toDart.name}",
                "method": "${DefaultTransferMethod.onImageUpload.name}",
                "data": {
                  "listFileUploaded": listFileUploaded,
                  "listFileFailed": listFileFailed
                }
              }), "*");
              return;
            }
            let file = files[index];

            reader.onload = function (e) {
              let base64 = e.target.result;
              let fileUpload = {
                 'lastModified': file.lastModified,
                 'lastModifiedDate': file.lastModifiedDate,
                 'name': file.name,
                 'size': file.size,
                 'type': file.type,
                 'base64': base64
              };
              listFileUploaded.push(fileUpload);
              readFile(index+1);
            };
            
            reader.onerror = function (_) {
              let fileUploadError = {
                 'lastModified': file.lastModified,
                 'lastModifiedDate': file.lastModifiedDate,
                 'name': file.name,
                 'size': file.size,
                 'type': file.type
              };
              listFileFailed.push(fileUploadError);
              readFile(index+1);
            };
            
            reader.readAsDataURL(file);
          }
          readFile(0);
        },
      """;
    }
    if (widget.callbacks?.onImageUploadError != null) {
        summernoteCallbacks =
            """$summernoteCallbacks              onImageUploadError: function(file, error) {
                // if (typeof file === 'string') {
                //   window.parent.postMessage(JSON.stringify({
                //     "${EventDataProperties.id.name}": "$createdViewId",
                //     "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                //     "${EventDataProperties.method.name}": "${DefaultTransferMethod.onImageUploadError.name}",
                //     "${EventDataProperties.data.name}": {
                //       "base64": file,
                //       "error": error
                //     }
                //   }), "*");
                // } else {
                //   let listFileFailed = [];
                //   let fileUploadError = {
                //      'lastModified': file.lastModified,
                //      'lastModifiedDate': file.lastModifiedDate,
                //      'name': file.name,
                //      'size': file.size,
                //      'type': file.type
                //   };
                //   listFileFailed.push(fileUploadError);
                //   window.parent.(JSON.stringify({
                //     "${EventDataProperties.id.name}": "$createdViewId",
                //     "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                //     "${EventDataProperties.method.name}": "${DefaultTransferMethod.onImageUploadError.name}",
                //     "${EventDataProperties.data.name}": {
                //       "listFileFailed": listFileFailed,
                //       "error": error
                //     }
                //   }), "*");
                // }
              },
            """;
      }

    summernoteCallbacks = '$summernoteCallbacks}';
    var darkCSS = '';
    if ((Theme.of(widget.initBC).brightness == Brightness.dark ||
            widget.htmlEditorOptions.darkMode == true) &&
        widget.htmlEditorOptions.darkMode != false) {
      darkCSS =
          '<link href="assets/packages/html_editor_enhanced/assets/summernote-lite-dark.css" rel="stylesheet">';
    }
    var jsCallbacks = '';
    if (widget.callbacks != null) {
      jsCallbacks = getJsCallbacks(widget.callbacks!);
    }
    var userScripts = '';
    if (widget.htmlEditorOptions.webInitialScripts != null) {
      for (var element in widget.htmlEditorOptions.webInitialScripts!) {
        userScripts = '''$userScripts
          if (transferMethod == "${element.name}") {
            ${element.script}
          }
          \n
        ''';
      }
    }
    var summernoteScripts = """
      <script type="text/javascript">
        \$(document).ready(function () {
          \$('#summernote-2').summernote({
            placeholder: "${widget.htmlEditorOptions.hint}",
            tabsize: 2,
            height: ${widget.otherOptions.height},
            disableResizeEditor: false,
            disableDragAndDrop: ${widget.htmlEditorOptions.disableDragAndDrop},
            disableGrammar: false,
            spellCheck: ${widget.htmlEditorOptions.spellCheck},
            maximumFileSize: $maximumFileSize,
            ${widget.htmlEditorOptions.customOptions}
            $summernoteCallbacks
          });
          
          \$('#summernote-2').on('summernote.change', function(_, contents, \$editable) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onChangeContent.name}",
              "${EventDataProperties.data.name}": contents
            }), "*");
          });
        });
       
        window.parent.addEventListener('message', handleMessage, false);
        document.onselectionchange = onSelectionChange;
      
        function handleMessage(e) {
          if (!e?.data) {
            console.warn("handleMessage::Received null data in message.");
            return;
          }
        
          let data;
          try {
              data = JSON.parse(e.data);
          } catch (error) {
              console.error("handleMessage::Failed to parse message data:", error);
              return;
          }
          
          const eventId = data["${EventDataProperties.id.name}"];
          const transferType = data["${EventDataProperties.type.name}"];

          if (eventId == "$createdViewId" && transferType == "${TransferType.toIframe.name}") {
            const transferMethod = data["${EventDataProperties.method.name}"];
            
            if (!transferMethod) {
              console.warn("handleMessage::Transfer method is null in message.");
              return;
            }
            const eventData = data["${EventDataProperties.data.name}"];
            
            if (transferMethod == "${DefaultTransferMethod.getText.name}") {
              var str = \$('#summernote-2').summernote('code');
                
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.getText.name}",
                "${EventDataProperties.data.name}": str
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.getTextWithSignatureContent.name}") {
              ${JavascriptUtils.jsHandleReplaceSignatureContent}
              
              var str = \$('#summernote-2').summernote('code');
              
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.getTextWithSignatureContent.name}",
                "${EventDataProperties.data.name}": str
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.getHeight.name}") {
              var height = document.body.scrollHeight;
                
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.getHeight.name}",
                "${EventDataProperties.data.name}": height
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.setInputType.name}") {
              document.getElementsByClassName('note-editable')[0].setAttribute('inputmode', '${widget.htmlEditorOptions.inputType.name}');
            }
            
            if (transferMethod == "${DefaultTransferMethod.setDimensionDropZone.name}") {
              const nodeDropZone = document.querySelector('.note-editor > .note-dropzone');
              if (nodeDropZone) {
                var styleDropZone = "";
                
                if (eventData && eventData["height"]) {
                  styleDropZone = "height:" + eventData["height"] + "px;";
                }
                if (eventData && eventData["width"]) {
                  styleDropZone = styleDropZone + "width:" + eventData["width"] + "px;";
                }
                nodeDropZone.setAttribute('style', styleDropZone);
              }
            }
            
            if (transferMethod == "${DefaultTransferMethod.setText.name}") {
              \$('#summernote-2').summernote('code', eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.setFullScreen.name}") {
              \$("#summernote-2").summernote("fullscreen.toggle");
            }
            
            if (transferMethod == "${DefaultTransferMethod.isFullScreen.name}") {
              var changed = \$('#summernote-2').summernote('fullscreen.isFullscreen');
                
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.isFullScreen.name}",
                "${EventDataProperties.data.name}": changed
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.setFocus.name}") {
              \$('#summernote-2').summernote('focus');
            }
            
            if (transferMethod == "${DefaultTransferMethod.clear.name}") {
              \$('#summernote-2').summernote('reset');
            }
            
            if (transferMethod == "${DefaultTransferMethod.setHint.name}") {
              \$(".note-placeholder").html(eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.toggleCodeView.name}") {
              \$('#summernote-2').summernote('codeview.toggle');
            }
            
            if (transferMethod == "${DefaultTransferMethod.isActivatedCodeView.name}") {
              var changed = \$('#summernote-2').summernote('codeview.isActivated');
                
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.isActivatedCodeView.name}",
                "${EventDataProperties.data.name}": changed
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.disable.name}") {
              \$('#summernote-2').summernote('disable');
            }
            
            if (transferMethod == "${DefaultTransferMethod.enable.name}") {
              \$('#summernote-2').summernote('enable');
            }
            
            if (transferMethod == "${DefaultTransferMethod.undo.name}") {
              \$('#summernote-2').summernote('undo');
            }
            
            if (transferMethod == "${DefaultTransferMethod.redo.name}") {
              \$('#summernote-2').summernote('redo');
            }
            
            if (transferMethod == "${DefaultTransferMethod.insertText.name}") {
              \$('#summernote-2').summernote('insertText', eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.insertHtml.name}") {
              \$('#summernote-2').summernote('pasteHTML', eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.insertNetworkImage.name}") {
              \$('#summernote-2').summernote('insertImage', eventData["url"], eventData["filename"]);
            }
            
            if (transferMethod == "${DefaultTransferMethod.insertLink.name}") {
              \$('#summernote-2').summernote('createLink', {
                text: eventData["text"],
                url: eventData["url"],
                isNewWindow: eventData["isNewWindow"]
              });
            }
            
            if (transferMethod == "${DefaultTransferMethod.reload.name}") {
              window.location.reload();
            }
            
            if (transferMethod == "${DefaultTransferMethod.addNotification.name}") {
              if (eventData["alertType"] === null) {
                \$('.note-status-output').html(
                  eventData["html"]
                );
              } else {
                \$('.note-status-output').html(
                  '<div class="' + eventData["alertType"] + '">' +
                    eventData["html"] +
                  '</div>'
                );
              }
            }
            
            if (transferMethod == "${DefaultTransferMethod.removeNotification.name}") {
              \$('.note-status-output').empty();
            }
            
            if (transferMethod == "${DefaultTransferMethod.execCommand.name}") {
              var commandType = eventData["command"];
              var argument = eventData["argument"];
              
              if (commandType === "hiliteColor") {
                if (argument === null && !document.execCommand("hiliteColor", false)) {
                  document.execCommand("backColor", false);
                } else if (argument && !document.execCommand("hiliteColor", false, argument)) {
                  document.execCommand("backColor", false, argument);
                }
              } else {
                if (argument === null) {
                  document.execCommand(commandType, false);
                } else {
                  document.execCommand(commandType, false, argument);
                }
              }
            }
            
            if (transferMethod == "${DefaultTransferMethod.execSummernoteAPI.name}") {
              var nameAPI = eventData["nameAPI"];
              var value = eventData["value"];
              if (value === null) {
                \$('#summernote-2').summernote(nameAPI);
              } else {
                \$('#summernote-2').summernote(nameAPI, value);
              }
            }
            
            if (transferMethod == "${DefaultTransferMethod.setFontSize.name}") {
              setFontSize(eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.changeListStyle.name}") {
              var \$focusNode = \$(window.getSelection().focusNode);
              var \$parentList = \$focusNode.closest("div.note-editable ol, div.note-editable ul");
              \$parentList.css("list-style-type", eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.changeLineHeight.name}") {
              \$('#summernote-2').summernote('lineHeight', eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.changeTextDirection.name}") {
              var s = document.getSelection();			
              if (s == '') {
                document.execCommand("insertHTML", false, "<p dir='"+ eventData +"'></p>");
              } else {
                document.execCommand("insertHTML", false, "<div dir='"+ eventData +"'>"+ document.getSelection()+"</div>");
              }
            }
            
            if (transferMethod == "${DefaultTransferMethod.changeCase.name}") {
              var selected = \$('#summernote-2').summernote('createRange');
              if (selected.toString()) {
                var texto;
                var count = 0;
                var value = eventData;
                var nodes = selected.nodes();
                for (var i=0; i< nodes.length; ++i) {
                  if (nodes[i].nodeName == "#text") {
                    count++;
                    texto = nodes[i].nodeValue.toLowerCase();
                    nodes[i].nodeValue = texto;
                    if (value == 'upper') {
                       nodes[i].nodeValue = texto.toUpperCase();
                    } else if (value == 'sentence' && count==1) {
                       nodes[i].nodeValue = texto.charAt(0).toUpperCase() + texto.slice(1).toLowerCase();
                    } else if (value == 'title') {
                      var sentence = texto.split(" ");
                      for(var j = 0; j< sentence.length; j++){
                         sentence[j] = sentence[j][0].toUpperCase() + sentence[j].slice(1);
                      }
                      nodes[i].nodeValue = sentence.join(" ");
                    }
                  }
                }
              }
            }
            
            if (transferMethod == "${DefaultTransferMethod.getText.name}") {
              \$('#summernote-2').summernote('insertTable', eventData);
            }
            
            if (transferMethod == "${DefaultTransferMethod.getSelectedTextHtml.name}") {
              var range = window.getSelection().getRangeAt(0);
              var content = range.cloneContents();
              var span = document.createElement('span');
                
              span.appendChild(content);
              var htmlContent = span.innerHTML;
              
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.getSelectedTextHtml.name}",
                "${EventDataProperties.data.name}": htmlContent
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.getSelectedText.name}") {
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.getSelectedText.name}",
                "${EventDataProperties.data.name}": window.getSelection().toString()
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.insertSignature.name}") {
              ${JavascriptUtils.jsHandleInsertSignature}
               
              const contentsEditor = document.getElementsByClassName('note-editable')[0].innerHTML;
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.insertSignature.name}",
                "${EventDataProperties.data.name}": contentsEditor
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.removeSignature.name}") {
              ${JavascriptUtils.jsHandleRemoveSignature}

              const contentsEditor = document.getElementsByClassName('note-editable')[0].innerHTML;
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.removeSignature.name}",
                "${EventDataProperties.data.name}": contentsEditor
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.updateBodyDirection.name}") {
              ${JavascriptUtils.jsHandleUpdateBodyDirection}

              const contentsEditor = document.getElementsByClassName('note-editable')[0].innerHTML;
              window.parent.postMessage(JSON.stringify({
                "${EventDataProperties.id.name}": "$createdViewId",
                "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                "${EventDataProperties.method.name}": "${DefaultTransferMethod.updateBodyDirection.name}",
                "${EventDataProperties.data.name}": contentsEditor
              }), "*");
            }
            
            if (transferMethod == "${DefaultTransferMethod.onDragDropEvent.name}") {
              document.getElementsByClassName('note-editor')[0].addEventListener("dragenter", function(event) {
                event.preventDefault();
                window.parent.postMessage(JSON.stringify({
                  "${EventDataProperties.id.name}": "$createdViewId",
                  "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                  "${EventDataProperties.method.name}": "${DefaultTransferMethod.onDragEnter.name}",
                  "${EventDataProperties.data.name}": event.dataTransfer.types
                }), "*");
              });
              
              document.getElementsByClassName('note-editor')[0].addEventListener("dragleave", function(event) {
                event.preventDefault();
                window.parent.postMessage(JSON.stringify({
                  "${EventDataProperties.id.name}": "$createdViewId",
                  "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                  "${EventDataProperties.method.name}": "${DefaultTransferMethod.onDragLeave.name}",
                  "${EventDataProperties.data.name}": event.dataTransfer.types
                }), "*");
              });
            }
                        
            $userScripts
          }
        }
        
        ${JavascriptUtils.jsHandleOnClickSignature}
        ${JavascriptUtils.jsDetectBrowser}
        ${JavascriptUtils.jsHandleSetFontSize}
        
        function onSelectionChange() {
          let {anchorNode, anchorOffset, focusNode, focusOffset} = document.getSelection();
          var isBold = false;
          var isItalic = false;
          var isUnderline = false;
          var isStrikethrough = false;
          var isSuperscript = false;
          var isSubscript = false;
          var isUL = false;
          var isOL = false;
          var isLeft = false;
          var isRight = false;
          var isCenter = false;
          var isFull = false;
          var parent;
          var fontName;
          var fontSize = 16;
          var foreColor = "000000";
          var backColor = "FFFFFF";
          var focusNode2 = \$(window.getSelection().focusNode);
          var parentList = focusNode2.closest("div.note-editable ol, div.note-editable ul");
          var parentListType = parentList.css('list-style-type');
          var lineHeight = \$(focusNode.parentNode).css('line-height');
          var direction = \$(focusNode.parentNode).css('direction');
          if (document.queryCommandState) {
            isBold = document.queryCommandState('bold');
            isItalic = document.queryCommandState('italic');
            isUnderline = document.queryCommandState('underline');
            isStrikethrough = document.queryCommandState('strikeThrough');
            isSuperscript = document.queryCommandState('superscript');
            isSubscript = document.queryCommandState('subscript');
            isUL = document.queryCommandState('insertUnorderedList');
            isOL = document.queryCommandState('insertOrderedList');
            isLeft = document.queryCommandState('justifyLeft');
            isRight = document.queryCommandState('justifyRight');
            isCenter = document.queryCommandState('justifyCenter');
            isFull = document.queryCommandState('justifyFull');
          }
          if (document.queryCommandValue) {
            parent = document.queryCommandValue('formatBlock');
            fontSize = document.queryCommandValue('fontSize');
            foreColor = document.queryCommandValue('foreColor');
            backColor = document.queryCommandValue('hiliteColor')
            if (!backColor) {
               backColor = document.queryCommandValue('backColor');
            }
            fontName = document.queryCommandValue('fontName');
          }
          const browserName = getBrowserName();
          if (browserName === "Firefox") {
            backColor = \$(focusNode.parentNode).css('background-color');
          }
          var message = {
            '${EventDataProperties.id.name}': "$createdViewId", 
            '${EventDataProperties.type.name}': "${TransferType.toDart.name}",
            '${EventDataProperties.method.name}': "${DefaultTransferMethod.updateToolbar.name}",
            '${EventDataProperties.data.name}': {
              'style': parent,
              'fontName': fontName,
              'fontSize': fontSize,
              'font': [isBold, isItalic, isUnderline],
              'miscFont': [isStrikethrough, isSuperscript, isSubscript],
              'color': [foreColor, backColor],
              'paragraph': [isUL, isOL],
              'listStyle': parentListType,
              'align': [isLeft, isCenter, isRight, isFull],
              'lineHeight': lineHeight,
              'direction': direction
            }
          };
          window.parent.postMessage(JSON.stringify(message), "*");
        }
        
        $jsCallbacks

        function iframeLoaded(event) {
          window.parent.postMessage(JSON.stringify({
            "${EventDataProperties.id.name}": "$createdViewId",
            "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
            "${EventDataProperties.method.name}": "${DefaultTransferMethod.onIframeLoaded.name}"
          }), "*");
        }
        window.addEventListener('load', iframeLoaded, false);
        window.addEventListener('pagehide', (event) => {
          window.parent.removeEventListener('message', handleMessage, false);
        });
      </script>
    """;
    var filePath =
        'packages/html_editor_enhanced/assets/summernote-no-plugins.html';
    if (widget.htmlEditorOptions.filePath != null) {
      filePath = widget.htmlEditorOptions.filePath!;
    }
    var htmlString = await rootBundle.loadString(filePath);
    htmlString = htmlString
        .replaceFirst('<!--darkCSS-->', darkCSS)
        .replaceFirst('<!--headString-->', headString)
        .replaceFirst('<!--summernoteScripts-->', summernoteScripts)
        .replaceFirst('<!--customBodyCssStyle-->',
            widget.htmlEditorOptions.customBodyCssStyle)
        .replaceFirst('"jquery.min.js"',
            '"assets/packages/html_editor_enhanced/assets/jquery.min.js"')
        .replaceFirst('"summernote-lite.min.css"',
            '"assets/packages/html_editor_enhanced/assets/summernote-lite.min.css"')
        .replaceFirst('"summernote-lite.min.js"',
            '"assets/packages/html_editor_enhanced/assets/summernote-lite-v2.min.js"');
    _addWindowListener();

    final currentContextBC = widget.initBC;
    String maxWidth;
    if (currentContextBC.mounted) {
      maxWidth = MediaQuery.of(currentContextBC).size.width.toString();
    } else {
      maxWidth = '800';
    }
    final iframe = html.IFrameElement()
      ..width = maxWidth
      ..height = widget.htmlEditorOptions.autoAdjustHeight
          ? actualHeight.toString()
          : widget.otherOptions.height.toString()
      // ignore: unsafe_html, necessary to load HTML string
      ..srcdoc = htmlString
      ..style.border = 'none'
      ..style.overflow = 'hidden'
      ..style.width = '100%'
      ..style.height = '100%';
    ui.platformViewRegistry
        .registerViewFactory(createdViewId, (int viewId) => iframe);
    setState(mounted, this.setState, () {
      summernoteInit = Future.value(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.htmlEditorOptions.autoAdjustHeight
          ? actualHeight
          : widget.otherOptions.height,
      child: Column(
        children: <Widget>[
          widget.htmlToolbarOptions.toolbarPosition == ToolbarPosition.aboveEditor
              ? ToolbarWidget(
                  key: toolbarKey,
                  controller: widget.controller,
                  htmlToolbarOptions: widget.htmlToolbarOptions,
                  callbacks: widget.callbacks)
              : const SizedBox(height: 0, width: 0),
          Expanded(
              child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: FutureBuilder<bool>(
                      future: summernoteInit,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return HtmlElementView(
                            viewType: createdViewId,
                          );
                        } else {
                          return Container(
                              height: widget.htmlEditorOptions.autoAdjustHeight
                                  ? actualHeight
                                  : widget.otherOptions.height);
                        }
                      }))),
          widget.htmlToolbarOptions.toolbarPosition == ToolbarPosition.belowEditor
              ? ToolbarWidget(
                  key: toolbarKey,
                  controller: widget.controller,
                  htmlToolbarOptions: widget.htmlToolbarOptions,
                  callbacks: widget.callbacks)
              : const SizedBox(height: 0, width: 0),
        ],
      ),
    );
  }

  /// Adds the callbacks the user set into JavaScript
  String getJsCallbacks(Callbacks c) {
    var callbacks = '';
    if (c.onBeforeCommand != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.before.command', function(_, contents, \$editable) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onBeforeCommand.name}",
              "${EventDataProperties.data.name}": contents
            }), "*");
          });\n
        """;
    }
    if (c.onChangeCodeview != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.change.codeview', function(_, contents, \$editable) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onChangeCodeView.name}",
              "${EventDataProperties.data.name}": contents
            }), "*");
          });\n
        """;
    }
    if (c.onDialogShown != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.dialog.shown', function() {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onDialogShown.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onEnter != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.enter', function() {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onEnter.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onFocus != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.focus', function() {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onFocus.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onBlur != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.blur', function() {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onBlur.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onBlurCodeview != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.blur.codeview', function() {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onBlurCodeView.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onKeyDown != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.keydown', function(_, e) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onKeyDown.name}",
              "${EventDataProperties.data.name}": e.keyCode
            }), "*");
          });\n
        """;
    }
    if (c.onKeyUp != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.keyup', function(_, e) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onKeyUp.name}",
              "${EventDataProperties.data.name}": e.keyCode
            }), "*");
          });\n
        """;
    }
    if (c.onMouseDown != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.mousedown', function(_) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onMouseDown.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onMouseUp != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.mouseup', function(_) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onMouseUp.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onPaste != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.paste', function(_) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onPaste.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onScroll != null) {
      callbacks =
          """$callbacks          \$('#summernote-2').on('summernote.scroll', function(_) {
            window.parent.postMessage(JSON.stringify({
              "${EventDataProperties.id.name}": "$createdViewId",
              "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
              "${EventDataProperties.method.name}": "${DefaultTransferMethod.onScroll.name}"
            }), "*");
          });\n
        """;
    }
    if (c.onTextFontSizeChanged != null) {
      callbacks =
      """$callbacks          \$('#summernote-2').on('summernote.mouseup', function(_) {
            try {
              var selection = window.getSelection();

              var fontSize = selection && selection.rangeCount > 0 
                  && selection.getRangeAt(0).startContainer.parentNode 
                  && \$(selection.getRangeAt(0).startContainer.parentNode).css("font-size");
              console.log("JavascriptUtils::summernote.mouseup::fontSize:", fontSize);
              if (fontSize) {
                fontSize = fontSize.replace("px", "");
                var size = parseInt(fontSize);
                window.parent.postMessage(JSON.stringify({
                  "${EventDataProperties.id.name}": "$createdViewId",
                  "${EventDataProperties.type.name}": "${TransferType.toDart.name}",
                  "${EventDataProperties.method.name}": "${DefaultTransferMethod.onTextFontSizeChanged.name}",
                  "${EventDataProperties.data.name}": size
                }), "*");
              }
            } catch(error) {
              console.error("JavascriptUtils::summernote.mouseup::Exception", error.message);
            }
          });\n
        """;
    }
    return callbacks;
  }

  /// Adds an event listener to check when a callback is fired
  void _addWindowListener() {
    _onWindowMessageStreamSubscription = html.window.onMessage.listen(_handleOnMessageEventData);
  }

  void _handleOnMessageEventData(html.MessageEvent event) {
    try {
      final transferEventData = TransferEventData.fromJson(jsonDecode(event.data));
      debugPrint('_HtmlEditorWidgetWebState::_handleOnMessageEventData: transferEventData = $transferEventData');

      if (transferEventData.id != createdViewId) return;

      switch(transferEventData.type) {
        case TransferType.toDart:
          _handleTransferEventDataFromIframe(transferEventData);
          break;
        case TransferType.toIframe:
          break;
      }
    } catch (e) {
      debugPrint('_HtmlEditorWidgetWebState::_handleOnMessageEventData:Exception = $e');
    }
  }

  void _handleTransferEventDataFromIframe(TransferEventData eventData) {
    final data = eventData.data;

    final defaultTransferMethod = DefaultTransferMethod.values
      .firstWhere(
        (method) => method.name == eventData.method?.value,
        orElse: () => DefaultTransferMethod.unknown
      );

    switch(defaultTransferMethod) {
      case DefaultTransferMethod.onBeforeCommand:
        widget.callbacks?.onBeforeCommand?.call(data);
        break;
      case DefaultTransferMethod.onChangeCodeView:
        widget.callbacks?.onChangeCodeview?.call(data);
        break;
      case DefaultTransferMethod.onDialogShown:
        widget.callbacks?.onDialogShown?.call();
        break;
      case DefaultTransferMethod.onEnter:
        widget.callbacks?.onEnter?.call();
        break;
      case DefaultTransferMethod.onFocus:
        widget.callbacks?.onFocus?.call();
        break;
      case DefaultTransferMethod.onBlur:
        widget.callbacks?.onBlur?.call();
        break;
      case DefaultTransferMethod.onBlurCodeView:
        widget.callbacks?.onBlurCodeview?.call();
        break;
      case DefaultTransferMethod.onImageLinkInsert:
        widget.callbacks?.onImageLinkInsert?.call(data);
        break;
      case DefaultTransferMethod.onImageUpload:
        _handleImageUploadSuccess(data);
        break;
      case DefaultTransferMethod.onImageUploadError:
        _handleImageUploadFailure(data);
        break;
      case DefaultTransferMethod.onKeyDown:
        widget.callbacks?.onKeyDown?.call(data);
        break;
      case DefaultTransferMethod.onKeyUp:
        widget.callbacks?.onKeyUp?.call(data);
        break;
      case DefaultTransferMethod.onMouseDown:
        widget.callbacks?.onMouseDown?.call();
        break;
      case DefaultTransferMethod.onMouseUp:
        widget.callbacks?.onMouseUp?.call();
        break;
      case DefaultTransferMethod.onPaste:
        widget.callbacks?.onPaste?.call();
        break;
      case DefaultTransferMethod.onScroll:
        widget.callbacks?.onScroll?.call();
        break;
      case DefaultTransferMethod.characterCount:
        widget.controller.characterCount = data;
        break;
      case DefaultTransferMethod.onTextFontSizeChanged:
        widget.callbacks?.onTextFontSizeChanged?.call(data);
        break;
      case DefaultTransferMethod.onDragEnter:
        widget.callbacks?.onDragEnter?.call(data);
        break;
      case DefaultTransferMethod.onDragLeave:
        widget.callbacks?.onDragLeave?.call(data);
        break;
      case DefaultTransferMethod.onSelectMention:
        final listOnSelectMethod = widget.plugins
          .whereType<SummernoteAtMention>()
          .where((plugin) => plugin.onSelect != null);

        for (var mention in listOnSelectMethod) {
          mention.onSelect?.call(data);
        }
        break;
      case DefaultTransferMethod.onIframeLoaded:
        _handleOnIframeLoaded();
        break;
      case DefaultTransferMethod.getHeight:
        if (widget.htmlEditorOptions.autoAdjustHeight) {
          _handleGetHeight(data);
        }
        break;
      case DefaultTransferMethod.insertSignature:
      case DefaultTransferMethod.removeSignature:
      case DefaultTransferMethod.updateBodyDirection:
        widget.callbacks?.onChangeContent?.call(data);
        break;
      case DefaultTransferMethod.onChangeContent:
        _handleOnChangeContent(data);
        break;
      case DefaultTransferMethod.updateToolbar:
        widget.controller.toolbar?.updateToolbar(data);
        break;
      default:
        break;
    }
  }

  void _handleImageUploadSuccess(dynamic data) {
    try {
      final jsonString = jsonEncode(data);
      List<Map<String, dynamic>> dataList = jsonDecode(jsonString).cast<Map<String, dynamic>>();
      final listFileUpload = dataList.map((data) => FileUpload.fromJson(data)).toList();
      debugPrint('_HtmlEditorWidgetWebState::_handleImageUploadSuccess: COUNT_FILE_UPLOADED: ${listFileUpload.length}');
      widget.callbacks?.onImageUpload?.call(listFileUpload);
    } catch (e) {
      debugPrint('_HtmlEditorWidgetWebState::_handleImageUploadSuccess: Exception: $e');
      widget.callbacks?.onImageUploadError?.call(null, null, UploadError.jsException);
    }
  }

  void _handleImageUploadFailure(dynamic data) {
    try {
      final error = data['error'];
      final base64 = data['base64'];

      UploadError uploadError;
      if (error.contains('base64')) {
        uploadError = UploadError.jsException;
      } else if (error.contains('unsupported')) {
        uploadError = UploadError.unsupportedFile;
      } else {
        uploadError = UploadError.exceededMaxSize;
      }

      if (base64 != null) {
        widget.callbacks?.onImageUploadError?.call(null, base64, uploadError);
      } else {
        final jsonString = jsonEncode(data['listFileFailed']);
        List<Map<String, dynamic>> dataList = jsonDecode(jsonString).cast<Map<String, dynamic>>();
        final listFileUploadFailed = dataList.map((data) => FileUpload.fromJson(data)).toList();
        debugPrint('_HtmlEditorWidgetWebState::_handleImageUploadFailure: COUNT_FILE_FAILED: ${listFileUploadFailed.length}');
        widget.callbacks?.onImageUpload?.call(listFileUploadFailed);
      }
    } catch (e) {
      debugPrint('_HtmlEditorWidgetWebState::_handleImageUploadFailure: Exception: $e');
      widget.callbacks?.onImageUploadError?.call(null, null, UploadError.jsException);
    }
  }

  void _handleOnIframeLoaded() {
    if (widget.htmlEditorOptions.disabled && !alreadyDisabled) {
      widget.controller.disable();
      alreadyDisabled = true;
    }
    if (widget.callbacks?.onInit != null) {
      widget.callbacks?.onInit?.call();
    }
    if (widget.htmlEditorOptions.initialText != null) {
      widget.controller.setText(widget.htmlEditorOptions.initialText!);
      widget.callbacks?.onInitialTextLoadComplete?.call(widget.htmlEditorOptions.initialText!);
    }

    _sendEventData(TransferEventData(
      id: createdViewId,
      type: TransferType.toIframe,
      method: DefaultTransferMethod.getHeight.method));

    _sendEventData(TransferEventData(
      id: createdViewId,
      type: TransferType.toIframe,
      method: DefaultTransferMethod.setInputType.method));

    if (widget.otherOptions.dropZoneHeight != null ||
        widget.otherOptions.dropZoneWidth != null) {
      _setDimensionDropZoneView(
          height: widget.otherOptions.dropZoneHeight,
          width: widget.otherOptions.dropZoneWidth
      );
    }
  }

  void _handleGetHeight(dynamic height) {
    if (!mounted) return;

    final docHeight = height ?? actualHeight;
    final toolbarKeyHeight = toolbarKey.currentContext?.size?.height ?? 0;

    if (docHeight > 0 && docHeight != actualHeight) {
      this.setState(() {
        actualHeight = docHeight + toolbarKeyHeight;
      });
    }
  }

  void _handleOnChangeContent(dynamic data) {
    widget.callbacks?.onChangeContent?.call(data);

    if (!mounted) return;

    final renderObject = context.findRenderObject();
    if (widget.htmlEditorOptions.shouldEnsureVisible && renderObject != null) {
      Scrollable.maybeOf(context)?.position.ensureVisible(
        renderObject,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn
      );
    }
  }

  void _setDimensionDropZoneView({double? height, double? width}) {
    final eventData = TransferEventData(
      id: createdViewId,
      type: TransferType.toIframe,
      method: DefaultTransferMethod.setDimensionDropZone.method,
      data: <String, Object>{
        if (height != null) 'height': '${height.round()}',
        if (width != null) 'width': '${width.round()}'
      }
    );

    _sendEventData(eventData);
  }

  void _sendEventData(TransferEventData eventData) {
    html.window.postMessage(_jsonEncoder.convert(eventData.toJson()), '*');
  }

  @override
  void dispose() {
    _onWindowMessageStreamSubscription?.cancel();
    super.dispose();
  }
}
