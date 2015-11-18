// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material_button.dart';
import 'theme.dart';

class FlatButton extends MaterialButton {
  FlatButton({
    Key key,
    Widget child,
    ButtonColor textTheme,
    Color textColor,
    Color disabledTextColor,
    this.color,
    this.colorBrightness,
    this.disabledColor,
    VoidCallback onPressed
  }) : super(key: key,
             child: child,
             textTheme: textTheme,
             textColor: textColor,
             disabledTextColor: disabledTextColor,
             onPressed: onPressed);

  // These default to null, meaning transparent.
  final Color color;
  final Color disabledColor;

  /// Controls the default text color if the text color isn't explicit set.
  final ThemeBrightness colorBrightness;

  _FlatButtonState createState() => new _FlatButtonState();
}

class _FlatButtonState extends MaterialButtonState<FlatButton> {

  int get elevation => 0;

  Color getColor(BuildContext context) {
    if (!config.enabled)
      return config.disabledColor;
    return config.color;
  }

  ThemeBrightness getColorBrightness(BuildContext context) {
    return config.colorBrightness ?? Theme.of(context).brightness;
  }

}
