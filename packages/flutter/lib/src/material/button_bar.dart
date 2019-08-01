// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'button_bar_theme.dart';
import 'button_theme.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'raised_button.dart';

/// An end-aligned row of buttons.
///
/// Places the buttons horizontally according to the padding in the current
/// [ButtonTheme]. The children are laid out in a [Row] with
/// [MainAxisAlignment.end]. When the [Directionality] is [TextDirection.ltr],
/// the button bar's children are right justified and the last child becomes
/// the rightmost child. When the [Directionality] [TextDirection.rtl] the
/// children are left justified and the last child becomes the leftmost child.
///
/// Used by [Dialog] to arrange the actions at the bottom of the dialog.
///
/// See also:
///
///  * [RaisedButton], a kind of button.
///  * [FlatButton], another kind of button.
///  * [Card], at the bottom of which it is common to place a [ButtonBar].
///  * [Dialog], which uses a [ButtonBar] for its actions.
///  * [ButtonTheme], which configures the [ButtonBar].
class ButtonBar extends StatelessWidget {
  /// Creates a button bar.
  ///
  /// The alignment argument defaults to [MainAxisAlignment.end].
  const ButtonBar({
    Key key,
    this.alignment,
    this.mainAxisSize,
    this.buttonTextTheme,
    this.buttonMinWidth,
    this.buttonHeight,
    this.buttonPadding,
    this.buttonAlignedDropdown,
    this.layoutBehavior,
    this.children = const <Widget>[],
  }) : super(key: key);

  /// How the children should be placed along the horizontal axis.
  final MainAxisAlignment alignment;

  /// How much horizontal space is available. See [Row.mainAxisSize].
  final MainAxisSize mainAxisSize;

  final ButtonTextTheme buttonTextTheme;
  final double buttonMinWidth;
  final double buttonHeight;
  final EdgeInsetsGeometry buttonPadding;
  final bool buttonAlignedDropdown;
  final ButtonBarLayoutBehavior layoutBehavior;

  /// The buttons to arrange horizontally.
  ///
  /// Typically [RaisedButton] or [FlatButton] widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData parentButtonTheme = ButtonTheme.of(context);
    final ButtonBarThemeData barTheme = ButtonBarTheme.of(context);

    final ButtonThemeData buttonTheme = parentButtonTheme.copyWith(
      textTheme: buttonTextTheme ?? barTheme.buttonTextTheme ?? ButtonTextTheme.primary,
      minWidth: buttonMinWidth ?? barTheme.buttonMinWidth ?? 64.0,
      height: buttonHeight ?? barTheme.buttonHeight ?? 36.0,
      padding: buttonPadding ?? barTheme.buttonPadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      alignedDropdown: buttonAlignedDropdown ?? barTheme.buttonAlignedDropdown ?? false,
      layoutBehavior: layoutBehavior ?? barTheme.layoutBehavior ?? ButtonBarLayoutBehavior.padded,
    );

    // We divide by 4.0 because we want half of the average of the left and right padding.
    final double paddingUnit = buttonTheme.padding.horizontal / 4.0;
    final Widget child = ButtonTheme.fromButtonThemeData(
      data: buttonTheme,
      child: Row(
        mainAxisAlignment: alignment ?? barTheme.alignment ?? MainAxisAlignment.end,
        mainAxisSize: mainAxisSize ?? barTheme.mainAxisSize ?? MainAxisSize.max,
        children: children.map<Widget>((Widget child) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingUnit),
            child: child,
          );
        }).toList(),
      ),
    );
    switch (buttonTheme.layoutBehavior) {
      case ButtonBarLayoutBehavior.padded:
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 2.0 * paddingUnit,
            horizontal: paddingUnit,
          ),
          child: child,
        );
      case ButtonBarLayoutBehavior.constrained:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: paddingUnit),
          constraints: const BoxConstraints(minHeight: 52.0),
          alignment: Alignment.center,
          child: child,
        );
    }
    assert(false);
    return null;
  }
}
