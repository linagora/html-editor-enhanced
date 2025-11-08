import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/mixin/link_overlay_mixin.dart';
import 'package:middle_ellipsis_text/middle_ellipsis_text.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:web/web.dart' as web;

typedef CustomLinkButtonBuilder = Widget Function(
  String href,
  VoidCallback onPressed,
);

class LinkTooltipOverlay with LinkOverlay {
  OverlayEntry? _entry;

  final LinkTooltipOverlayOptions tooltipOverlayOptions;
  final LinkEditDialogOverlay? linkEditDialogOverlay;

  LinkTooltipOverlay({
    this.tooltipOverlayOptions = const LinkTooltipOverlayOptions(),
    this.linkEditDialogOverlay,
  });

  void show(
    BuildContext context,
    String href,
    web.DOMRect rect, {
    String? iframeId,
    String? text,
  }) {
    if (_entry != null) {
      hide();
      Future.microtask(() {
        if (context.mounted) {
          show(context, href, rect, text: text, iframeId: iframeId);
        }
      });
      return;
    }

    final overlay = Overlay.maybeOf(context);

    final viewportHeight = web.window.innerHeight.toDouble();
    final viewportWidth = web.window.innerWidth.toDouble();

    final tooltipWidth = viewportWidth < tooltipOverlayOptions.tooltipBaseWidth
        ? viewportWidth - tooltipOverlayOptions.tooltipHorizontalMargin * 2
        : tooltipOverlayOptions.tooltipBaseWidth;

    final adjustRect = adjustRectForIframe(rect, iframeId: iframeId);

    final bool showAbove = (adjustRect.bottom.toDouble() +
            tooltipOverlayOptions.tooltipHeight +
            tooltipOverlayOptions.tooltipMarginTop) >
        viewportHeight;

    final double tooltipTop = showAbove
        ? adjustRect.top.toDouble() -
            tooltipOverlayOptions.tooltipHeight -
            tooltipOverlayOptions.tooltipMarginTop
        : adjustRect.bottom.toDouble() + tooltipOverlayOptions.tooltipMarginTop;

    double tooltipLeft = adjustRect.left.toDouble();
    if (tooltipLeft + tooltipWidth > viewportWidth) {
      tooltipLeft = viewportWidth -
          tooltipWidth -
          tooltipOverlayOptions.tooltipHorizontalMargin;
    }
    if (tooltipLeft < tooltipOverlayOptions.tooltipHorizontalMargin) {
      tooltipLeft = tooltipOverlayOptions.tooltipHorizontalMargin;
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
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        end: 8,
                      ),
                      height: tooltipOverlayOptions.tooltipHeight,
                      constraints: BoxConstraints(maxWidth: tooltipWidth),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
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
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tooltipOverlayOptions.linkPrefixLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Text(
                                tooltipOverlayOptions.linkPrefixLabel,
                                style: tooltipOverlayOptions
                                        .linkPrefixLabelStyle ??
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
                          Flexible(
                            child: InkWell(
                              onTap: () => _onClickLink(href),
                              child: MiddleEllipsisText(
                                href,
                                style: tooltipOverlayOptions.linkLabelStyle ??
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
                          if (tooltipOverlayOptions.editLinkButtonBuilder !=
                              null)
                            tooltipOverlayOptions.editLinkButtonBuilder!(
                              href,
                              () => _onEditLink(
                                context,
                                href,
                                rect,
                                text: text,
                                iframeId: iframeId,
                              ),
                            )
                          else
                            TextButton(
                              onPressed: () => _onEditLink(
                                context,
                                href,
                                rect,
                                text: text,
                                iframeId: iframeId,
                              ),
                              child: Text(
                                tooltipOverlayOptions.editLinkLabel,
                                style:
                                    tooltipOverlayOptions.editLinkLabelStyle ??
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
                          if (tooltipOverlayOptions.removeLinkButtonBuilder !=
                              null)
                            tooltipOverlayOptions.removeLinkButtonBuilder!(
                              href,
                              () => _onRemoveLink(iframeId: iframeId),
                            )
                          else
                            IconButton(
                              onPressed: () =>
                                  _onRemoveLink(iframeId: iframeId),
                              icon: const Icon(
                                Icons.link_off,
                                size: 20,
                                color: Color(0xFF007AFF),
                              ),
                              tooltip: tooltipOverlayOptions
                                  .removeLinkTooltipMessage,
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

  void _onClickLink(String href) {
    try {
      hide();
      web.window.open(href, '_blank');
    } catch (_) {}
  }

  void _onEditLink(
    BuildContext context,
    String href,
    web.DOMRect rect, {
    String? iframeId,
    String? text,
  }) {
    try {
      hide();

      linkEditDialogOverlay?.show(
        context: context,
        rect: rect,
        initialText: text,
        initialUrl: href,
        iframeId: iframeId,
      );
    } catch (_) {}
  }

  void _onRemoveLink({String? iframeId}) {
    try {
      hide();
      postMessageToIframe('removeLink', iframeId: iframeId);
    } catch (_) {}
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
