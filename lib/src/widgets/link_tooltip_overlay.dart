import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:middle_ellipsis_text/middle_ellipsis_text.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:web/web.dart' as web;

typedef CustomLinkButtonBuilder = Widget Function(
  String href,
  VoidCallback onPressed,
);

class LinkTooltipOverlay {
  OverlayEntry? _entry;

  final CustomLinkButtonBuilder? removeLinkButtonBuilder;
  final CustomLinkButtonBuilder? editLinkButtonBuilder;
  final String linkPrefixLabel;
  final String editLinkLabel;
  final String removeLinkTooltipMessage;
  final TextStyle? linkPrefixLabelStyle;
  final TextStyle? linkLabelStyle;
  final TextStyle? editLinkLabelStyle;
  final double tooltipBaseWidth;
  final double tooltipHeight;
  final double tooltipMarginTop;
  final double tooltipHorizontalMargin;

  LinkTooltipOverlay({
    this.removeLinkButtonBuilder,
    this.editLinkButtonBuilder,
    this.tooltipBaseWidth = 565.0,
    this.tooltipHeight = 50.0,
    this.tooltipMarginTop = 4.0,
    this.tooltipHorizontalMargin = 10.0,
    this.linkPrefixLabel = 'Go to:',
    this.editLinkLabel = 'Change',
    this.removeLinkTooltipMessage = 'Remove link',
    this.linkPrefixLabelStyle,
    this.linkLabelStyle,
    this.editLinkLabelStyle,
  });

  void show(
    BuildContext context,
    String href,
    web.DOMRect rect, {
    String? iframeId,
  }) {
    if (_entry != null) {
      hide();
      Future.microtask(() {
        if (context.mounted) {
          show(context, href, rect, iframeId: iframeId);
        }
      });
      return;
    }

    final overlay = Overlay.maybeOf(context);

    final viewportHeight = web.window.innerHeight.toDouble();
    final viewportWidth = web.window.innerWidth.toDouble();

    final tooltipWidth = viewportWidth < tooltipBaseWidth
        ? viewportWidth - tooltipHorizontalMargin * 2
        : tooltipBaseWidth;

    rect = _adjustRectForIframe(rect, iframeId: iframeId);

    final bool showAbove =
        (rect.bottom.toDouble() + tooltipHeight + tooltipMarginTop) >
            viewportHeight;

    final double tooltipTop = showAbove
        ? rect.top.toDouble() - tooltipHeight - tooltipMarginTop
        : rect.bottom.toDouble() + tooltipMarginTop;

    double tooltipLeft = rect.left.toDouble();
    if (tooltipLeft + tooltipWidth > viewportWidth) {
      tooltipLeft = viewportWidth - tooltipWidth - tooltipHorizontalMargin;
    }
    if (tooltipLeft < tooltipHorizontalMargin) {
      tooltipLeft = tooltipHorizontalMargin;
    }

    _entry = OverlayEntry(
      builder: (_) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          builder: (context, opacity, child) {
            final slide = (showAbove ? -1 : 1) * (1 - opacity) * 8;
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, slide),
                child: child,
              ),
            );
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: hide,
                ),
              ),
              PositionedDirectional(
                start: tooltipLeft,
                top: tooltipTop,
                child: PointerInterceptor(
                  child: Material(
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        end: 8,
                      ),
                      width: tooltipWidth,
                      height: tooltipHeight,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE6E1E5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 23,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 2,
                            ),
                          ]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (linkPrefixLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Text(
                                linkPrefixLabel,
                                style: linkPrefixLabelStyle ??
                                    const TextStyle(
                                      fontSize: 14,
                                      height: 18 / 14,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF222222),
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _onClickLink(href),
                              child: MiddleEllipsisText(
                                href,
                                style: linkLabelStyle ??
                                    const TextStyle(
                                      fontSize: 14,
                                      height: 18 / 14,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF0A84FF),
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (editLinkButtonBuilder != null)
                            editLinkButtonBuilder!(
                              href,
                              () => _onEditLink(href, iframeId: iframeId),
                            )
                          else
                            TextButton(
                              onPressed: () => _onEditLink(
                                href,
                                iframeId: iframeId,
                              ),
                              child: Text(
                                editLinkLabel,
                                style: editLinkLabelStyle ??
                                    const TextStyle(
                                      fontSize: 14,
                                      height: 18 / 14,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF0A84FF),
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          if (removeLinkButtonBuilder != null)
                            removeLinkButtonBuilder!(
                              href,
                              () => _onRemoveLink(href, iframeId: iframeId),
                            )
                          else
                            IconButton(
                              onPressed: () => _onRemoveLink(
                                href,
                                iframeId: iframeId,
                              ),
                              icon: const Icon(
                                Icons.link_off,
                                size: 20,
                                color: Color(0xFF007AFF),
                              ),
                              tooltip: removeLinkTooltipMessage,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay?.insert(_entry!);
  }

  web.DOMRect _adjustRectForIframe(web.DOMRect rect, {String? iframeId}) {
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

  void _onClickLink(String href) {
    try {
      hide();
      web.window.open(href, '_blank');
    } catch (_) {}
  }

  void _onEditLink(String href, {String? iframeId}) {
    try {
      hide();
      _postMessageToIframe(
        'editLink',
        href,
        iframeId: iframeId,
      );
    } catch (_) {}
  }

  void _onRemoveLink(String href, {String? iframeId}) {
    try {
      hide();
      _postMessageToIframe(
        'removeLink',
        href,
        iframeId: iframeId,
      );
    } catch (_) {}
  }

  void _postMessageToIframe(String type, String href, {String? iframeId}) {
    final message = {
      if (iframeId != null) 'view': iframeId,
      'type': 'toIframe: $type',
      'href': href,
    };

    try {
      final iframe = iframeId != null
          ? web.document.getElementById(iframeId)
          : web.document.querySelector('iframe');

      if (iframe is web.HTMLIFrameElement) {
        iframe.contentWindow?.postMessage(message.jsify(), '*'.toJS);
      } else {
        web.window.postMessage(message.jsify(), '*'.toJS);
      }
    } catch (e) {
      web.window.postMessage(message.jsify(), '*'.toJS);
    }
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
