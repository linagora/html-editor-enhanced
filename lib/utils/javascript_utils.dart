class JavascriptUtils {
  const JavascriptUtils._();

  static String jsHandleCreateSignature(String viewId) => '''
   function insertSignature(signatureHtml, allowCollapsed) {
      const signatureNode = document.querySelector('.note-editable > .tmail-signature');
      
      if (signatureNode) {
        const currentSignatureContent = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
        const currentSignatureButton = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-button');
      
        if (currentSignatureContent && currentSignatureButton) {
          currentSignatureContent.innerHTML = signatureHtml;
          
          if (allowCollapsed) {
            currentSignatureButton.contentEditable = "false";
            currentSignatureButton.setAttribute('onclick', 'handleOnClickSignature()');
            currentSignatureButton.setAttribute("onmouseenter", "handleSignatureHoverIn(this)");
            currentSignatureButton.setAttribute("onmouseleave", "handleSignatureHoverOut(this)");
            const browserName = getBrowserName();
            if (browserName === 'Firefox') {
              currentSignatureButton.style.userSelect = 'none';
            }
          } else {
            replaceSignatureContent();
          }
        } else {
          const signatureContainer = createSignatureElement(signatureHtml, allowCollapsed);
      
          if (signatureNode.outerHTML) {
            signatureNode.outerHTML = signatureContainer.outerHTML;
          } else {
            signatureNode.parentNode.replaceChild(signatureContainer, signatureNode);
          }
        }
      } else {
        const signatureContainer = createSignatureElement(signatureHtml, allowCollapsed);
      
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
   }
   
   function replaceSignatureContent() {
      const nodeSignature = document.querySelector('.note-editable > .tmail-signature');
      const signatureContent = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
      if (nodeSignature && signatureContent) {
        signatureContent.className = 'tmail-signature';
        signatureContent.style.display = 'block';
        signatureContent.style.clear = 'both';
          
        if (nodeSignature.outerHTML) {
          nodeSignature.outerHTML = signatureContent.outerHTML;
        } else { 
          nodeSignature.parentNode.replaceChild(signatureContent, nodeSignature); 
        }
      }
   }
    
   function handleOnClickSignature() {
     const contentElement = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
     const buttonElement = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-button');
     if (contentElement && buttonElement) {
        contentElement.style.display = contentElement.style.display === 'block' ? 'none' : 'block';
     }
   }
   
   function updateBodyDirection(direction) {
     const nodeEditor = document.querySelector('.note-editable');
     if (nodeEditor) {
        const currentDirection = direction;
        nodeEditor.style.direction = currentDirection.toString();
     }
   }
   
   function removeSignature() {
      const nodeSignature = document.querySelector('.note-editable > .tmail-signature');
      if (nodeSignature) {
        nodeSignature.remove();
      }
   }
   
   function createSignatureElement(signatureHtml, allowCollapsed) {
      const signatureContainer = document.createElement("div");
      signatureContainer.className = "tmail-signature";
      signatureContainer.style.clear = "both";
    
      if (allowCollapsed) {
        const signatureContent = document.createElement("div");
        signatureContent.className = "tmail-signature-content";
        signatureContent.innerHTML = signatureHtml;
        signatureContent.style.display = "none";
      
        const signatureButton = document.createElement("div");
        signatureButton.className = "tmail-signature-button";
        signatureButton.contentEditable = "false";
        signatureButton.setAttribute("onclick", "handleOnClickSignature()");
        signatureButton.setAttribute("onmouseenter", "handleSignatureHoverIn(this)");
        signatureButton.setAttribute("onmouseleave", "handleSignatureHoverOut(this)");
        const browserName = getBrowserName();
        if (browserName === 'Firefox') {
          signatureButton.style.userSelect = 'none';
        }
      
        const signatureButtonThreeDots = document.createElement("button");
        signatureButtonThreeDots.className = "tmail-signature-button-three-dots";
      
        for (let i = 0; i < 3; i++) {
          const dot = document.createElement("div");
          dot.className = "tmail-signature-button-dot";
          signatureButtonThreeDots.appendChild(dot);
        }
      
        signatureButton.appendChild(signatureButtonThreeDots);
      
        signatureContainer.appendChild(signatureButton);
        signatureContainer.appendChild(signatureContent);
      } else {
        signatureContainer.innerHTML = signatureHtml;
        signatureContainer.style.display = "block";
      }
      
      return signatureContainer;
    }
    
    function getAbsolutePosition(element) {
      const rect = element.getBoundingClientRect();
      const iframeRect = window.frameElement?.getBoundingClientRect() || { top: 0, left: 0 };
      return {
        top: rect.top + iframeRect.top + window.parent.scrollY,
        left: rect.left + iframeRect.left + window.parent.scrollX,
        width: rect.width,
        height: rect.height
      };
    }
    
    function isSignatureContentVisible() {
      const contentElement = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
      if (contentElement) {
        return contentElement.style.display === 'block';
      } else {
        return false;
      }
    }
    
    function handleSignatureHoverIn(element) {
      try {
        const position = getAbsolutePosition(element);
        const isContentVisible = isSignatureContentVisible();
        const payload = {
          view: '$viewId',
          type: 'toDart: onSignatureHoverIn',
          top: position.top,
          left: position.left,
          width: position.width,
          height: position.height,
          isContentVisible: isContentVisible
        };
        window.parent.postMessage(JSON.stringify(payload), "*");
      } catch (error) {}
    }
    
    function handleSignatureHoverOut(element) {
      try {
        const payload = {
          view: '$viewId',
          type: 'toDart: onSignatureHoverOut'
        };
        window.parent.postMessage(JSON.stringify(payload), "*");
      } catch (error) {}
    }
  ''';

  static const String jsDetectBrowser = '''
    function getBrowserName() {
      const ua = navigator.userAgent;

      if (ua.includes('OPR') || ua.includes('Opera')) return 'Opera';
      if (ua.includes('Edg')) return 'Microsoft Edge';
      if (ua.includes('Chrome') && !ua.includes('Edg') && !ua.includes('OPR')) return 'Chrome';
      if (ua.includes('Safari') && !ua.includes('Chrome') && !ua.includes('Edg') && !ua.includes('OPR')) return 'Safari';
      if (ua.includes('Firefox')) return 'Firefox';
      if (ua.includes('Trident') || ua.includes('MSIE')) return 'Internet Explorer';
    
      return 'Unknown';
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

  static const String jsHandleOnKeyDown = '''
      if (e.which === 13) { // Press "Enter"
          setTimeout(() => {
              let selection = window.getSelection();
              if (selection.rangeCount > 0) {
                  let range = selection.getRangeAt(0);
                  let node = range.commonAncestorContainer;
                  
                  // If the node is a text node, get its parent element
                  if (node.nodeType === 3) { 
                      node = node.parentElement;
                  }
  
                  // Check if the node has no height (empty line after Enter)
                  if (node && node.getBoundingClientRect().height === 0) {
                      node = node.nextElementSibling || node.parentElement;
                  }
  
                  if (node) {
                      node.scrollIntoView({ behavior: "smooth", block: "nearest" });
                  }
              }
          }, 50); // Increase delay to 50ms to allow DOM updates
      }
  ''';

  static const String jsHandleInsertImageWithSafeSignature = '''
    function insertImageWithSafeSignature(imgSource) {
      if (!isRangeOutsideSignatureButton()) {
        const nodeEditor = document.querySelector('.note-editable');
        if (nodeEditor) {
          const signatureNode = document.querySelector('.note-editable > div.tmail-signature');
          const imageContainer = document.createElement('div');
          imageContainer.innerHTML = imgSource;
          if (signatureNode) {
            nodeEditor.insertBefore(imageContainer, signatureNode);
          } else {
            nodeEditor.appendChild(imageContainer);
          }
          return;
        }
      }

      const browserName = getBrowserName();
      if ((browserName === 'Safari' || browserName === 'Firefox') && !editorHasBeenFocused) {
        safePasteHTML(imgSource);
      } else {
        \$('#summernote-2').summernote('pasteHTML', imgSource);
      }
    }
    
    function isRangeOutsideSignatureButton() {
      try {
        const sel = window.getSelection();
        if (!sel || sel.rangeCount === 0) return true;
    
        const range = sel.getRangeAt(0);
        if (!range) return true;
    
        const container = range.startContainer;
        const node = container.nodeType === Node.TEXT_NODE ? container.parentNode : container;
        return !node.closest('.tmail-signature-button');
      } catch (error) {
        return true;
      }
    }
    
    function safePasteHTML(htmlToInsert) {
      const nodeEditor = document.querySelector('.note-editable');
      if (nodeEditor) {
        const signatureNode = document.querySelector('.note-editable > div.tmail-signature');
        const imageContainer = document.createElement('div');
        imageContainer.innerHTML = htmlToInsert;
        if (signatureNode) {
          nodeEditor.insertBefore(imageContainer, signatureNode);
        } else {
          nodeEditor.appendChild(imageContainer);
        }
        return;
      }
      
      \$('#summernote-2').summernote('pasteHTML', imgSource);
    }
  ''';

  static const String jsHandleNormalizeHtmlTextWhenDropping = '''
    const INTERNAL_MIME = 'application/x-editor-internal';
  
    let noteEditor = document.getElementsByClassName('note-editor')[0];
    if (noteEditor) {
    
      noteEditor.addEventListener('dragstart', (e) => {
        try {
          e.dataTransfer.setData(INTERNAL_MIME, '1'); 
        } catch (_) {}
      });
            
      noteEditor.addEventListener('dragover', (e) => {
        try {
          const dt = (e.originalEvent || e).dataTransfer || e.dataTransfer;
          if (!dt) return;
          const types = Array.from(dt.types || []);
          const isInternal = types.includes(INTERNAL_MIME);
          if (!isInternal) {
            e.preventDefault();
          }
        } catch (_) {}
      });
      
      noteEditor.addEventListener("drop", function(event) {
        try {
          const dataTransfer = (event.originalEvent || event).dataTransfer;
          if (!dataTransfer) return;
      
          const types = Array.from(dataTransfer.types || []);
          const isInternal = types.includes(INTERNAL_MIME);
          const htmlData = dataTransfer.getData('text/html');
        
          if (isInternal) return;
          
          if (htmlData) {
            event.preventDefault();
            
            const x = event.clientX;
            const y = event.clientY;
      
            noteEditor.focus();
      
            let range;
            if (document.caretRangeFromPoint) {
              range = document.caretRangeFromPoint(x, y);
            } else if (document.caretPositionFromPoint) {
              const pos = document.caretPositionFromPoint(x, y);
              range = document.createRange();
              range.setStart(pos.offsetNode, pos.offset);
            }
      
            if (range) {
              const selection = window.getSelection();
              selection.removeAllRanges();
              selection.addRange(range);
            }
      
            setTimeout(() => {
              document.execCommand("insertHTML", false, htmlData);
            }, 0);
          }
        } catch (_) {}
      });
    }
  ''';

  static String jsHandleClickHyperLink(String viewId) => '''
    document.addEventListener('click', function(e) {
      try {
        const target = e.target;
        if (!target) return;
    
        // Handle link click
        if (target.tagName === 'A') {
          e.preventDefault();
          const href = target.getAttribute('href') || '';
          const text = target.textContent?.trim() || '';
          const rect = target.getBoundingClientRect();
    
          window.parent.postMessage(JSON.stringify({
            "view": "$viewId",
            "type": "toDart: linkClick",
            "href": href,
            "text": text,
            "rect": rect
          }), "*");
          return;
        }
    
        // Handle click outside link
        window.parent.postMessage(JSON.stringify({
          "view": "$viewId",
          "type": "toDart: clickOutsideEditor"
        }), "*");
      } catch (_) {}
    });
  ''';

  static const String jsHandleActionLink = '''
    if (data["type"].includes("editLink")) {
       try {
         \$('#summernote-2').summernote('linkDialog.show');
       } catch (_) {}
    } else if (data["type"].includes("updateLink")) {
       try {
          updateCurrentLink({ text: data.text, url: data.url });
       } catch (_) {}
    } else if (data["type"].includes("removeLink")) {
      try {
        \$('#summernote-2').summernote('editor.unlink');
      } catch (_) {}
    }
  ''';

  static const String jsHandleUpdateCurrentLink = '''
    function updateCurrentLink({ text, url }) {
      if (!url) return;
    
      try {
        \$('#summernote-2').summernote('editor.restoreRange');
      } catch (_) {}
    
      const sel = window.getSelection();
      if (!sel || sel.rangeCount === 0) return;
    
      let node = sel.anchorNode;
      if (node && node.nodeType === Node.TEXT_NODE) node = node.parentElement;
      const anchor = node ? node.closest('a') : null;
    
      \$('#summernote-2').summernote('editor.beforeCommand');
    
      if (anchor) {
        if (typeof text === 'string' && text.length) {
          anchor.textContent = text;
        }
        anchor.setAttribute('href', url);
      } else {
        const fallbackText = (typeof text === 'string' && text.length)
          ? text
          : (sel.toString() || url);
    
        \$('#summernote-2').summernote('createLink', {
          text: fallbackText,
          url: url,
        });
      }
    
      \$('#summernote-2').summernote('editor.afterCommand');
    }
  ''';
}