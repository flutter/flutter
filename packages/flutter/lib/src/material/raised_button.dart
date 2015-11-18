// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material_button.dart';
import 'theme.dart';

class RaisedButton extends MaterialButton {
  RaisedButton({
    Key key,
    Widget child,
    this.color,
    this.colorBrightness,
    this.disabledColor,
    this.elevation: 2,
    this.highlightElevation: 8,
    this.disabledElevation: 0,
    VoidCallback onPressed
  }) : super(key: key,
             child: child,
             onPressed: onPressed);

  final Color color;
  final Color disabledColor;

  /// Controls the default text color if the text color isn't explicit set.
  final ThemeBrightness colorBrightness;

  final int elevation;
  final int highlightElevation;
  final int disabledElevation;

  _RaisedButtonState createState() => new _RaisedButtonState();
}

class _RaisedButtonState extends MaterialButtonState<RaisedButton> {

  int get elevation {
    if (config.enabled) {
      if (highlight)
        return config.highlightElevation;
      return config.elevation;
    } else {
      return config.disabledElevation;
    }
  }

  Color getColor(BuildContext context) {
    if (config.enabled) {
      if (config.color != null)
        return config.color;
      switch (Theme.of(context).brightness) {
        case ThemeBrightness.light:
          return Colors.grey[300];
        case ThemeBrightness.dark:
          Map<int, Color> swatch = Theme.of(context).primarySwatch ?? Colors.blue;
          return swatch[600];
      }
    } else {
      if (config.disabledColor != null)
        return config.disabledColor;
      switch (Theme.of(context).brightness) {
        case ThemeBrightness.light:
          return Colors.black12;
        case ThemeBrightness.dark:
          return Colors.white12;
      }
    }
  }

  ThemeBrightness getColorBrightness(BuildContext context) {
    return config.colorBrightness ?? Theme.of(context).brightness;
  }

}
