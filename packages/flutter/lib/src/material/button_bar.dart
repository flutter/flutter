// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

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
    this.alignment = MainAxisAlignment.end,
    this.mainAxisSize = MainAxisSize.max,
    this.children = const <Widget>[],
  }) : super(key: key);

  /// How the children should be placed along the horizontal axis.
  final MainAxisAlignment alignment;

  /// How much horizontal space is available. See [Row.mainAxisSize].
  final MainAxisSize mainAxisSize;

  /// The buttons to arrange horizontally.
  ///
  /// Typically [RaisedButton] or [FlatButton] widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    // We divide by 4.0 because we want half of the average of the left and right padding.
    final double paddingUnit = buttonTheme.padding.horizontal / 4.0;
    final Widget child = Row(
      mainAxisAlignment: alignment,
      mainAxisSize: mainAxisSize,
      children: children.map<Widget>((Widget child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingUnit),
          child: child
        );
      }).toList()
    );
    switch (buttonTheme.layoutBehavior) {
      case ButtonBarLayoutBehavior.padded:
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 2.0 * paddingUnit,
            horizontal: paddingUnit
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
