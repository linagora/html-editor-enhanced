
import 'package:html_editor_enhanced/utils/icon_utils.dart';

class JavascriptUtils {

  static const String jsHandleInsertSignature = '''
    const signatureNode = document.querySelector('.note-editable > .tmail-signature');
    if (signatureNode) {
      const currentSignatureContent = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
      const currentSignatureButton = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-button');
    
      if (currentSignatureContent && currentSignatureButton) {
        currentSignatureContent.innerHTML = data['signature'];
        currentSignatureButton.contentEditable = "false";
        currentSignatureButton.setAttribute('onclick', 'handleOnClickSignature()');
        if (currentSignatureContent.style.display === 'none') {
         currentSignatureButton.style.backgroundImage = `${IconUtils.chevronDownSVGIconUrlEncoded}`;
       } else {
         currentSignatureButton.style.backgroundImage = `${IconUtils.chevronUpSVGIconUrlEncoded}`;
       }
      } else {
        const signatureContainer = document.createElement('div');
        signatureContainer.setAttribute('class', 'tmail-signature');
    
        const signatureContent = document.createElement('div');
        signatureContent.setAttribute('class', 'tmail-signature-content');
        signatureContent.innerHTML = data['signature'];
        signatureContent.style.display = 'none';
    
        const signatureButton = document.createElement('button');
        signatureButton.setAttribute('class', 'tmail-signature-button');
        signatureButton.textContent = 'Signature';
        signatureButton.contentEditable = "false";
        signatureButton.style.backgroundImage = `${IconUtils.chevronDownSVGIconUrlEncoded}`;
        signatureButton.setAttribute('onclick', 'handleOnClickSignature()');
    
        signatureContainer.appendChild(signatureButton);
        signatureContainer.appendChild(signatureContent);
    
        if (signatureNode.outerHTML) {
          signatureNode.outerHTML = signatureContainer.outerHTML;
        } else {
          signatureNode.parentNode.replaceChild(signatureContainer, signatureNode);
        }
      }
    } else {
      const signatureContainer = document.createElement('div');
      signatureContainer.setAttribute('class', 'tmail-signature');
    
      const signatureContent = document.createElement('div');
      signatureContent.setAttribute('class', 'tmail-signature-content');
      signatureContent.innerHTML = data['signature'];
      signatureContent.style.display = 'none';
    
      const signatureButton = document.createElement('button');
      signatureButton.setAttribute('class', 'tmail-signature-button');
      signatureButton.textContent = 'Signature';
      signatureButton.contentEditable = "false";
      signatureButton.style.backgroundImage = `${IconUtils.chevronDownSVGIconUrlEncoded}`;
      signatureButton.setAttribute('onclick', 'handleOnClickSignature()');
    
      signatureContainer.appendChild(signatureButton);
      signatureContainer.appendChild(signatureContent);
    
      const nodeEditor = document.querySelector('.note-editable');
      if (nodeEditor) {
        const headerQuotedMessage = document.querySelector('.note-editable > cite');
        const quotedMessage = document.querySelector('.note-editable > blockquote');
    
        if (headerQuotedMessage) {
          nodeEditor.insertBefore(signatureContainer, headerQuotedMessage);
        } else if (quotedMessage) {
          nodeEditor.insertBefore(signatureContainer, quotedMessage);
        } else {
          nodeEditor.appendChild(signatureContainer);
        }
      }
    }
    var browserName = getBrowserName();
    var signatureButton = document.querySelector('.tmail-signature-button');
    if (browserName === 'Firefox' && signatureButton) {
      signatureButton.style.userSelect = 'none';
    }
  ''';

  static const String jsHandleRemoveSignature = '''
    const nodeSignature = document.querySelector('.note-editable > .tmail-signature');
    if (nodeSignature) {
      nodeSignature.remove();
    }
  ''';

  static const String jsHandleReplaceSignatureContent = '''
    const nodeSignature = document.querySelector('.note-editable > .tmail-signature');
    const signatureContent = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
    if (nodeSignature && signatureContent) {
      signatureContent.className = 'tmail-signature';
      signatureContent.style.display = 'block';
        
      if (nodeSignature.outerHTML) {
        nodeSignature.outerHTML = signatureContent.outerHTML;
      } else { 
        nodeSignature.parentNode.replaceChild(signatureContent, nodeSignature); 
      }
    }
  ''';

  static const String jsHandleUpdateBodyDirection = '''
    const nodeEditor = document.querySelector('.note-editable');
    if (nodeEditor) {
      const currentDirection = data['direction'];
      nodeEditor.style.direction = currentDirection.toString();
    }
  ''';

  static const String jsHandleOnClickSignature = '''
   function handleOnClickSignature() {
     const contentElement = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
     const buttonElement = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-button');
     if (contentElement && buttonElement) {
       if (contentElement.style.display === 'block') {
         contentElement.style.display = 'none';
         buttonElement.style.backgroundImage = `${IconUtils.chevronDownSVGIconUrlEncoded}`;
       } else {
         contentElement.style.display = 'block';
         buttonElement.style.backgroundImage = `${IconUtils.chevronUpSVGIconUrlEncoded}`;
       }
     }
   }
  ''';

  static const String jsDetectBrowser = '''
    function getBrowserName() {
      // Opera 8.0+
      if ((window.opr && window.opr.addons)
        || window.opera
        || navigator.userAgent.indexOf(' OPR/') >= 0) {
        return 'Opera';
      }
    
      // Firefox 1.0+
      if (/Firefox|FxiOS/.test(navigator.userAgent)) {
        return 'Firefox';
      }
    
      // Safari 3.0+ "[object HTMLElementConstructor]"
      if (/constructor/i.test(window.HTMLElement) || (function (p) {
        return p.toString() === '[object SafariRemoteNotification]';
      })(!window['safari'])) {
        return 'Safari';
      }
    
      // Internet Explorer 6-11
      if (/* @cc_on!@*/false || document.documentMode) {
        return 'Internet Explorer';
      }
    
      // Edge 20+
      if (!(document.documentMode) && window.StyleMedia) {
        return 'Microsoft Edge';
      }
      
      // Chrome
      if (window.chrome) {
        return 'Chrome';
      }
    }
  ''';

  static const String jsHandleSetFontSize = '''
    var activeFontSize = 15;
    var style = document.createElement("style");
    document.body.appendChild(style);

    window.addEventListener('pagehide', (event) => {
      document.body.removeChild(style);
    });
    
    function setFontSize(value) {
      \$('#summernote-2').summernote('focus');
      document.execCommand("fontSize", false, 20);
      activeFontSize = value;
      createStyle();
      updateTags();
    }
    
    function updateTags() {
      var nodeEditor = document.querySelector('.note-editable');
      var fontElements = nodeEditor.getElementsByTagName("font");
      for (var i = 0, len = fontElements.length; i < len; ++i) {
        if (fontElements[i].size == "7") {
          fontElements[i].removeAttribute("size");
          fontElements[i].style.fontSize = activeFontSize + "px";
        }
      }
    }
    
    function createStyle() {
      style.innerHTML = '.note-editable font[size="7"]{font-size: ' + activeFontSize + 'px}';
    }
    
    \$('#summernote-2').on('summernote.keyup', function(_, e) {
      updateTags();
    });
  ''';
}