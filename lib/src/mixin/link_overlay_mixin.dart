import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

mixin LinkOverlay {
  final _jsonEncoder = const JsonEncoder();

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

  void postMessageToIframe(
    String type, {
    String? iframeId,
    Map<String, dynamic>? data,
  }) {
    final messageAsJson = _jsonEncoder.convert({
      if (iframeId != null) 'view': iframeId,
      'type': 'toIframe: $type',
      if (data != null) ...data,
    });
    web.window.postMessage(messageAsJson.jsify(), '*'.toJS);
  }
}
