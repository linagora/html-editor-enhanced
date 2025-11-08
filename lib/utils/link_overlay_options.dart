import 'package:flutter/cupertino.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class LinkOverlayOptions {
  final LinkTooltipOverlayOptions tooltipOptions;
  final LinkEditDialogOverlayOptions editDialogOptions;

  const LinkOverlayOptions({
    this.tooltipOptions = const LinkTooltipOverlayOptions(),
    this.editDialogOptions = const LinkEditDialogOverlayOptions(),
  });
}

class LinkTooltipOverlayOptions {
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

  const LinkTooltipOverlayOptions({
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
}

class LinkEditDialogOverlayOptions {
  final double dialogBaseWidth;
  final double dialogHeight;
  final double dialogMarginTop;
  final double dialogHorizontalMargin;
  final String hintText;
  final String hintUrl;
  final String applyButtonLabel;
  final TextStyle? hintTextStyle;
  final TextStyle? inputTextStyle;
  final TextStyle? applyButtonTextStyle;
  final Color? inputBackgroundColor;
  final Color? backgroundColor;
  final Widget? textPrefixIcon;
  final Widget? urlPrefixIcon;

  const LinkEditDialogOverlayOptions({
    this.dialogBaseWidth = 411.0,
    this.dialogHeight = 120.0,
    this.dialogMarginTop = 4.0,
    this.dialogHorizontalMargin = 10.0,
    this.hintText = 'Text',
    this.hintUrl = 'Type or paste a link',
    this.applyButtonLabel = 'Apply',
    this.hintTextStyle,
    this.inputTextStyle,
    this.applyButtonTextStyle,
    this.inputBackgroundColor,
    this.backgroundColor,
    this.textPrefixIcon,
    this.urlPrefixIcon,
  });
}
