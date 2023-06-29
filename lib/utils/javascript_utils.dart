
class JavascriptUtils {

  static const String jsHandleInsertSignature = '''
    const nodeSignature = document.getElementsByClassName('tmail-signature');
    if (nodeSignature.length <= 0) {
      const nodeEditor = document.getElementsByClassName('note-editable')[0];
      
      const divSignature = document.createElement('div');
      divSignature.setAttribute('class', 'tmail-signature');
      divSignature.innerHTML = data['signature'];
      
      const listHeaderQuotedMessage = nodeEditor.querySelectorAll('cite');
      const listQuotedMessage = nodeEditor.querySelectorAll('blockquote');
      
      if (listHeaderQuotedMessage.length > 0) {
        nodeEditor.insertBefore(divSignature, listHeaderQuotedMessage[0]);
      } else if (listQuotedMessage.length > 0) {
        nodeEditor.insertBefore(divSignature, listQuotedMessage[0]);
      } else {
        nodeEditor.appendChild(divSignature);
      }
    } else {
      nodeSignature[0].innerHTML = data['signature'];
    }
  ''';

  static const String jsHandleRemoveSignature = '''
    const nodeSignature = document.getElementsByClassName('tmail-signature');
    if (nodeSignature.length > 0) {
      nodeSignature[0].remove();
    }
  ''';

  static const String jsHandleUpdateBodyDirection = '''
    const nodeEditor = document.getElementsByClassName('note-editable')[0];
    const currentDirection = data['direction'];
    console.log('currentDirection: ' + currentDirection);
    nodeEditor.style.direction = currentDirection.toString();
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
}