// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'debug.dart';
import 'localizations.dart';

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 15.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

const CupertinoDynamicColor _kToolbarTextColor = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.black,
  darkColor: CupertinoColors.white,
);

const CupertinoDynamicColor _kToolbarPressedColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x10000000),
  darkColor: Color(0x10FFFFFF),
);

// Value measured from screenshot of iOS 16.0.2
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0);

/// A button in the style of the iOS text selection toolbar buttons.
class CupertinoTextSelectionToolbarButton extends StatefulWidget {
  /// Create an instance of [CupertinoTextSelectionToolbarButton].
  ///
  /// [child] cannot be null.
  const CupertinoTextSelectionToolbarButton({
    super.key,
    this.onPressed,
    required Widget this.child,
  }) : text = null,
       buttonItem = null;

  /// Create an instance of [CupertinoTextSelectionToolbarButton] whose child is
  /// a [Text] widget styled like the default iOS text selection toolbar button.
  const CupertinoTextSelectionToolbarButton.text({
    super.key,
    this.onPressed,
    required this.text,
  }) : buttonItem = null,
       child = null;

  /// Create an instance of [CupertinoTextSelectionToolbarButton] from the given
  /// [ContextMenuButtonItem].
  ///
  /// [buttonItem] cannot be null.
  CupertinoTextSelectionToolbarButton.buttonItem({
    super.key,
    required ContextMenuButtonItem this.buttonItem,
  }) : child = null,
       text = null,
       onPressed = buttonItem.onPressed;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.child}
  /// The child of this button.
  ///
  /// Usually a [Text] or an [Icon].
  /// {@endtemplate}
  final Widget? child;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  /// Called when this button is pressed.
  /// {@endtemplate}
  final VoidCallback? onPressed;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  /// The buttonItem used to generate the button when using
  /// [CupertinoTextSelectionToolbarButton.buttonItem].
  /// {@endtemplate}
  final ContextMenuButtonItem? buttonItem;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.text}
  /// The text used in the button's label when using
  /// [CupertinoTextSelectionToolbarButton.text].
  /// {@endtemplate}
  final String? text;

  /// Returns the default button label String for the button of the given
  /// [ContextMenuButtonItem]'s [ContextMenuButtonType].
  static String getButtonLabel(BuildContext context, ContextMenuButtonItem buttonItem) {
    if (buttonItem.label != null) {
      return buttonItem.label!;
    }

    assert(debugCheckHasCupertinoLocalizations(context));
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    switch (buttonItem.type) {
      case ContextMenuButtonType.cut:
        return localizations.cutButtonLabel;
      case ContextMenuButtonType.copy:
        return localizations.copyButtonLabel;
      case ContextMenuButtonType.paste:
        return localizations.pasteButtonLabel;
      case ContextMenuButtonType.selectAll:
        return localizations.selectAllButtonLabel;
      case ContextMenuButtonType.delete:
      case ContextMenuButtonType.custom:
        return '';
    }
  }

  @override
  State<StatefulWidget> createState() => _CupertinoTextSelectionToolbarButtonState();
}

class _CupertinoTextSelectionToolbarButtonState extends State<CupertinoTextSelectionToolbarButton> {
  bool isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => isPressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = CupertinoButton(
      color: isPressed
        ? _kToolbarPressedColor.resolveFrom(context)
        : const Color(0x00000000),
      borderRadius: null,
      disabledColor: const Color(0x00000000),
      // This CupertinoButton does not actually handle the onPressed callback,
      // this is only here to correctly enable/disable the button (see
      // GestureDetector comment below).
      onPressed: widget.onPressed,
      padding: _kToolbarButtonPadding,
      // There's no foreground fade on iOS toolbar anymore, just the background
      // is darkened.
      pressedOpacity: 1.0,
      child: widget.child ?? Text(
         widget.text ?? CupertinoTextSelectionToolbarButton.getButtonLabel(context, widget.buttonItem!),
         overflow: TextOverflow.ellipsis,
         style: _kToolbarButtonFontStyle.copyWith(
           color: widget.onPressed != null
               ? _kToolbarTextColor.resolveFrom(context)
               : CupertinoColors.inactiveGray,
         ),
       ),
    );

    if (widget.onPressed != null) {
      // As it's needed to change the CupertinoButton's backgroundColor when
      // pressed, not its opacity, this GestureDetector handles both the
      // onPressed callback and the backgroundColor change.
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: child,
      );
    } else {
      return child;
    }
  }
}
