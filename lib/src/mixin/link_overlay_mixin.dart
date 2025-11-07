import 'package:web/web.dart' as web;

mixin LinkOverlay {
  web.DOMRect adjustRectForIframe(web.DOMRect rect, {String? iframeId}) {
    web.Element? iframeEl;
    if (iframeId != null && iframeId.isNotEmpty) {
      iframeEl = web.document.getElementById(iframeId);
    }
    iframeEl ??= web.document.querySelector('iframe');

    if (iframeEl is web.HTMLIFrameElement) {
      final iframeRect = iframeEl.getBoundingClientRect();
      return web.DOMRect(
        rect.x + iframeRect.x,
        rect.y + iframeRect.y,
        rect.width,
        rect.height,
      );
    }
    return rect;
  }
}
