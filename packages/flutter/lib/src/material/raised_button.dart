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
    VoidCallback onPressed
  }) : super(key: key,
             child: child,
             onPressed: onPressed);

  _RaisedButtonState createState() => new _RaisedButtonState();
}

class _RaisedButtonState extends MaterialButtonState<RaisedButton> {

  int get elevation => config.enabled ? (highlight ? 8 : 2) : 0;

  Color getColor(BuildContext context, { bool highlight }) {
    if (config.enabled) {
      switch (Theme.of(context).brightness) {
        case ThemeBrightness.light:
          if (highlight)
            return Colors.grey[350];
          else
            return Colors.grey[300];
          break;
        case ThemeBrightness.dark:
          Map<int, Color> swatch = Theme.of(context).primarySwatch ?? Colors.blue;
          if (highlight)
            return swatch[700];
          else
            return swatch[600];
          break;
      }
    } else {
      switch (Theme.of(context).brightness) {
        case ThemeBrightness.light:
          return Colors.black12;
        case ThemeBrightness.dark:
          return Colors.white12;
      }
    }
  }

  ThemeBrightness getColorBrightness(BuildContext context) {
    return Theme.of(context).brightness;
  }

}
