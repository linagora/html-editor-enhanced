class JavascriptUtils {
  const JavascriptUtils._();

  static String jsHandleInsertSignature(String viewId) => '''
    const signatureNode = document.querySelector('.note-editable > .tmail-signature');
    const signatureHtml = data['signature'];
    
    if (signatureNode) {
      const currentSignatureContent = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-content');
      const currentSignatureButton = document.querySelector('.note-editable > .tmail-signature > .tmail-signature-button');
    
      if (currentSignatureContent && currentSignatureButton) {
        currentSignatureContent.innerHTML = signatureHtml;
        currentSignatureButton.contentEditable = "false";
        currentSignatureButton.setAttribute('onclick', 'handleOnClickSignature()');
        currentSignatureButton.setAttribute("onmouseenter", "handleSignatureHoverIn(this)");
        currentSignatureButton.setAttribute("onmouseleave", "handleSignatureHoverOut(this)");
      } else {
        const signatureContainer = createSignatureElement(signatureHtml);
    
        if (signatureNode.outerHTML) {
          signatureNode.outerHTML = signatureContainer.outerHTML;
        } else {
          signatureNode.parentNode.replaceChild(signatureContainer, signatureNode);
        }
      }
    } else {
      const signatureContainer = createSignatureElement(signatureHtml);
    
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
      signatureContent.style.clear = 'both';
        
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
        contentElement.style.display = contentElement.style.display === 'block' ? 'none' : 'block';
     }
   }
  ''';

  static String jsHandleCreateSignature(String viewId) => '''
   function createSignatureElement(signatureHtml) {
      const signatureContainer = document.createElement("div");
      signatureContainer.className = "tmail-signature";
      signatureContainer.style.clear = "both";
    
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

  static String jsHandleSetFontSize(double defaultFontSizePx) => '''
    var activeFontSize = `$defaultFontSizePx`;

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
      var fontElements = document.querySelectorAll('.note-editable font[size="7"]');
      fontElements.forEach(function(fontEl) {
        fontEl.removeAttribute("size");
        fontEl.style.fontSize = activeFontSize + "px";
      });
    }
    
    function createStyle() {
      style.innerHTML = '.note-editable font[size="7"]{font-size: ' + activeFontSize + 'px}';
    }
    
    \$('#summernote-2').on('summernote.keyup', function(_, e) {
      updateTags();
    });
  ''';

  static String jsHandleSetupDefaultFontSize(
    double defaultFontSizePx,
    double defaultLineHeightPx,
  ) => '''
    const ratio = `${defaultLineHeightPx / defaultFontSizePx}`;
    
    function calcLineHeightPx(fontSize) {
      return Math.round(fontSize * ratio);
    }
    
    function normalizeFontAndLineHeight(editable) {
      editable.querySelectorAll("[style*='font-size']").forEach(element => {
        const fontSize = parseInt(element.style.fontSize);
        if (fontSize) {
          element.style.lineHeight = calcLineHeightPx(fontSize) + "px";
        }
      });
    }

    function normalizeAllHeaderStyle(headerTag) {
      const nodeEditable = document.querySelector('.note-editable');
      if (nodeEditable) {
        if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(headerTag)) {
          nodeEditable.querySelectorAll(headerTag).forEach(element => {
            const size = parseInt(window.getComputedStyle(element).fontSize);
    
            if (size && !element.style.lineHeight) {
              element.style.lineHeight = calcLineHeightPx(size) + "px";
            }
    
            element.querySelectorAll("*").forEach(child => {
              if (child.style) {
                child.style.removeProperty("line-height");
                child.style.removeProperty("font-size");
    
                if (child.getAttribute("style") === "") {
                  child.removeAttribute("style");
                }
              }
            });
          });
        } else {
          nodeEditable.querySelectorAll(headerTag).forEach(element => {
            if (element.style) {
              element.style.removeProperty("line-height");

              if (element.getAttribute("style") === "") {
                element.removeAttribute("style");
              }
            }
          });
        }
      }
    }
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
          const signatureNode = document.querySelector('.note-editable > .tmail-signature');
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
        const signatureNode = document.querySelector('.note-editable > .tmail-signature');
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
    let noteEditor = document.getElementsByClassName('note-editor')[0];
    if (noteEditor) {
      noteEditor.addEventListener("drop", function(event) {
        let types = event.dataTransfer.types;
        if (types.includes("text/html")) {
          try {
            const dataTransfer = (event.originalEvent || event).dataTransfer;
            const htmlData = dataTransfer.getData('text/html');
            if (!htmlData) return;
             
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
          } catch (error) {
            console.error('[Drop Handler] Error during drop handling:', error);
          }
        }
      });
    }
  ''';
}