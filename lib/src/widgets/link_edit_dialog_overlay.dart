import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:html_editor_enhanced/src/mixin/link_overlay_mixin.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:web/web.dart' as web;

class LinkEditDialogOverlay with LinkOverlay {
  OverlayEntry? _entry;
  TextEditingController? _textController;
  TextEditingController? _urlController;
  FocusNode? _textFocusNode;
  FocusNode? _urlFocusNode;
  FocusNode? _applyButtonFocusNode;

  ValueNotifier<bool>? _isApplyEnabled;

  final LinkEditDialogOverlayOptions dialogOverlayOptions;

  LinkEditDialogOverlay({
    this.dialogOverlayOptions = const LinkEditDialogOverlayOptions(),
  });

  void show({
    required BuildContext context,
    required web.DOMRect rect,
    String? initialText,
    String? initialUrl,
    String? iframeId,
  }) {
    if (_entry != null) {
      hide();
      Future.microtask(() {
        if (context.mounted) {
          show(
            context: context,
            rect: rect,
            initialText: initialText,
            initialUrl: initialUrl,
            iframeId: iframeId,
          );
        }
      });
      return;
    }

    LinkOverlayManager.instance.hideOthers(LinkOverlayType.editDialog, this);
    LinkOverlayManager.instance.register(LinkOverlayType.editDialog, this);

    final overlay = Overlay.maybeOf(context);

    final viewportHeight = web.window.innerHeight.toDouble();
    final viewportWidth = web.window.innerWidth.toDouble();

    final dialogWidth = viewportWidth < dialogOverlayOptions.dialogBaseWidth
        ? viewportWidth - dialogOverlayOptions.dialogHorizontalMargin * 2
        : dialogOverlayOptions.dialogBaseWidth;

    final adjustRect = adjustRectForIframe(rect, iframeId: iframeId);

    final bool showAbove = (adjustRect.bottom.toDouble() +
            dialogOverlayOptions.dialogHeight +
            dialogOverlayOptions.dialogMarginTop) >
        viewportHeight;

    final double dialogTop = showAbove
        ? adjustRect.top.toDouble() -
            dialogOverlayOptions.dialogHeight -
            dialogOverlayOptions.dialogMarginTop
        : adjustRect.bottom.toDouble() + dialogOverlayOptions.dialogMarginTop;

    double dialogLeft = adjustRect.left.toDouble();
    if (dialogLeft + dialogWidth > viewportWidth) {
      dialogLeft = viewportWidth -
          dialogWidth -
          dialogOverlayOptions.dialogHorizontalMargin;
    }
    if (dialogLeft < dialogOverlayOptions.dialogHorizontalMargin) {
      dialogLeft = dialogOverlayOptions.dialogHorizontalMargin;
    }

    _textController = TextEditingController(text: initialText ?? '');
    _urlController = TextEditingController(text: initialUrl ?? '');

    _textFocusNode = FocusNode();
    _urlFocusNode = FocusNode();
    _applyButtonFocusNode = FocusNode();

    _isApplyEnabled = ValueNotifier<bool>(
      _urlController!.text.trim().isNotEmpty,
    );

    _urlController!.addListener(() {
      _isApplyEnabled!.value = _urlController!.text.trim().isNotEmpty;
    });

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
                start: dialogLeft,
                top: dialogTop,
                child: PointerInterceptor(
                  child: Material(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                    child: Container(
                      width: dialogWidth,
                      padding: dialogOverlayOptions.dialogPadding ??
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dialogOverlayOptions.backgroundColor ??
                            Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 24,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildInputRow(
                                  icon: dialogOverlayOptions.textPrefixIcon ??
                                      const Icon(
                                        Icons.text_fields,
                                        size: 24,
                                        color: Color(0xFF55687D),
                                      ),
                                  controller: _textController!,
                                  focusNode: _textFocusNode,
                                  hintText: dialogOverlayOptions.hintText,
                                  onSubmitted: () => _performSubmittedAction(
                                    iframeId: iframeId,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildInputRow(
                                  icon: dialogOverlayOptions.urlPrefixIcon ??
                                      const Icon(
                                        Icons.link,
                                        size: 24,
                                        color: Color(0xFF55687D),
                                      ),
                                  controller: _urlController!,
                                  focusNode: _urlFocusNode,
                                  hintText: dialogOverlayOptions.hintUrl,
                                  onSubmitted: () => _performSubmittedAction(
                                    iframeId: iframeId,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: AlignmentDirectional.bottomEnd,
                            padding: const EdgeInsetsDirectional.only(
                              bottom: 4,
                            ),
                            child: ValueListenableBuilder<bool>(
                                valueListenable: _isApplyEnabled!,
                                builder: (context, enabled, _) {
                                  final color = enabled
                                      ? const Color(0xFF0A84FF)
                                      : const Color(0xFF939393);
                                  return TextButton(
                                    onPressed: enabled
                                        ? () => _performApplyLink(
                                              iframeId: iframeId,
                                            )
                                        : null,
                                    focusNode: _applyButtonFocusNode,
                                    child: Text(
                                      dialogOverlayOptions.applyButtonLabel,
                                      style: dialogOverlayOptions
                                              .applyButtonTextStyle
                                              ?.call(enabled) ??
                                          TextStyle(
                                            fontSize: 14,
                                            height: 20 / 14,
                                            letterSpacing: 0.1,
                                            color: color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  );
                                }),
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

  Widget _buildInputRow({
    required Widget icon,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hintText,
    VoidCallback? onSubmitted,
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: () {
              if (controller == _textController) {
                _urlFocusNode?.requestFocus();
              } else if (controller == _urlController) {
                _applyButtonFocusNode?.requestFocus();
              }
            },
            onSubmitted: (_) => onSubmitted?.call(),
            cursorColor:
                dialogOverlayOptions.cursorColor ?? const Color(0xFF0A84FF),
            style: dialogOverlayOptions.inputTextStyle ??
                const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w400,
                ),
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              hintStyle: dialogOverlayOptions.hintTextStyle ??
                  const TextStyle(
                    color: Color(0xFF818C99),
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w400,
                  ),
              contentPadding: const EdgeInsetsDirectional.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
              enabledBorder: dialogOverlayOptions.enabledBorder ??
                  const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      width: 1,
                      color: Color(0xFFE6E1E5),
                    ),
                  ),
              border: dialogOverlayOptions.border ??
                  const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      width: 1,
                      color: Color(0xFFE6E1E5),
                    ),
                  ),
              focusedBorder: dialogOverlayOptions.focusedBorder ??
                  const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      width: 1,
                      color: Color(0xFF0A84FF),
                    ),
                  ),
              filled: true,
              fillColor:
                  dialogOverlayOptions.inputBackgroundColor ?? Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _disposeControllers() {
    _textController?.dispose();
    _textController = null;

    _urlController?.dispose();
    _urlController = null;

    _isApplyEnabled?.dispose();
    _isApplyEnabled = null;

    _textFocusNode?.dispose();
    _textFocusNode = null;

    _urlFocusNode?.dispose();
    _urlFocusNode = null;

    _applyButtonFocusNode?.dispose();
    _applyButtonFocusNode = null;
  }

  void _performApplyLink({String? iframeId}) {
    final text = _textController?.text.trim() ?? '';
    final url = _urlController?.text.trim() ?? '';

    if (url.isNotEmpty) {
      postMessageToIframe(
        'updateLink',
        iframeId: iframeId,
        data: {
          'text': text.isEmpty ? url : text,
          'url': url,
        },
      );
      hide();
    }
  }

  void _performSubmittedAction({String? iframeId}) {
    _performApplyLink(iframeId: iframeId);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
    _disposeControllers();
    LinkOverlayManager.instance.unregister(LinkOverlayType.editDialog, this);
  }
}
