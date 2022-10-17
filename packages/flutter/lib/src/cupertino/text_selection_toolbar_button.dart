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
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarBackgroundColor = Color(0xEB202020);

// Eyeballed value.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0);

/// A button in the style of the iOS text selection toolbar buttons.
class CupertinoTextSelectionToolbarButton extends StatelessWidget {
  /// Create an instance of [CupertinoTextSelectionToolbarButton].
  ///
  /// [child] cannot be null.
  const CupertinoTextSelectionToolbarButton({
    super.key,
    this.onPressed,
    required Widget this.child,
  }) : assert(child != null),
       buttonItem = null;

  /// Create an instance of [CupertinoTextSelectionToolbarButton] whose child is
  /// a [Text] widget styled like the default iOS text selection toolbar button.
  CupertinoTextSelectionToolbarButton.text({
    super.key,
    this.onPressed,
    required String text,
  }) : buttonItem = null,
       child = Text(
         text,
         overflow: TextOverflow.ellipsis,
         style: _kToolbarButtonFontStyle.copyWith(
           color: onPressed != null ? CupertinoColors.white : CupertinoColors.inactiveGray,
         ),
       );

  /// Create an instance of [CupertinoTextSelectionToolbarButton] from the given
  /// [ContextMenuButtonItem].
  ///
  /// [buttonItem] cannot be null.
  CupertinoTextSelectionToolbarButton.buttonItem({
    super.key,
    required ContextMenuButtonItem this.buttonItem,
  }) : assert(buttonItem != null),
       child = null,
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
      case ContextMenuButtonType.custom:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = this.child ?? Text(
      getButtonLabel(context, buttonItem!),
      overflow: TextOverflow.ellipsis,
      style: _kToolbarButtonFontStyle.copyWith(
        color: onPressed != null ? CupertinoColors.white : CupertinoColors.inactiveGray,
      ),
    );
    return CupertinoButton(
      borderRadius: null,
      color: _kToolbarBackgroundColor,
      disabledColor: _kToolbarBackgroundColor,
      onPressed: onPressed,
      padding: _kToolbarButtonPadding,
      pressedOpacity: onPressed == null ? 1.0 : 0.7,
      child: child,
    );
  }
}
