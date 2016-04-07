// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'theme.dart';

/// A material design "flat button".
///
/// A flat button is a section printed on a [Material] widget that reacts to
/// touches by filling with color.
///
/// Use flat buttons on toolbars, in dialogs, or inline with other content but
/// offset from that content with padding so that the button's presence is
/// obvious. Flat buttons intentionally do not have visible borders and must
/// therefore rely on their position relative to other content for context. In
/// dialogs and cards, they should be grouped together in one of the bottom
/// corners. Avoid using flat buttons where they would blend in with other
/// content, for example in the middle of lists.
///
/// If the [onPressed] callback is not specified or null, then the button will
/// be disabled, will not react to touch, and will be colored as specified by
/// the [disabledColor] property instead of the [color] property. If you are
/// trying to change the button's [color] and it is not having any effect, check
/// that you are passing a non-null [onPressed] handler.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [RaisedButton]
///  * [DropDownButton]
///  * <https://www.google.com/design/spec/components/buttons.html>
class FlatButton extends MaterialButton {
  FlatButton({
    Key key,
    Widget child,
    ThemeBrightness colorBrightness,
    ButtonColor textTheme,
    Color textColor,
    Color disabledTextColor,
    this.color,
    this.disabledColor,
    VoidCallback onPressed
  }) : super(key: key,
             child: child,
             colorBrightness: colorBrightness,
             textTheme: textTheme,
             textColor: textColor,
             disabledTextColor: disabledTextColor,
             onPressed: onPressed);

  /// The color of the button, as printed on the [Material]. Defaults to null,
  /// meaning transparent.
  final Color color;

  /// The color of the button when the button is disabled. Buttons are disabled
  /// by default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  final Color disabledColor;

  @override
  _FlatButtonState createState() => new _FlatButtonState();
}

class _FlatButtonState extends MaterialButtonState<FlatButton> {
  @override
  int get elevation => 0;

  @override
  Color getColor(BuildContext context) {
    if (!config.enabled)
      return config.disabledColor;
    return config.color;
  }
}
