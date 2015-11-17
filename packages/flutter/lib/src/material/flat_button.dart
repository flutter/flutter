// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material_button.dart';
import 'theme.dart';

class FlatButton extends MaterialButton {
  FlatButton({
    Key key,
    Widget child,
    VoidCallback onPressed
  }) : super(key: key,
             child: child,
             onPressed: onPressed);

  _FlatButtonState createState() => new _FlatButtonState();
}

class _FlatButtonState extends MaterialButtonState<FlatButton> {

  int get elevation => 0;

  Color getColor(BuildContext context, { bool highlight }) {
    if (!config.enabled || !highlight)
      return null;
    switch (Theme.of(context).brightness) {
      case ThemeBrightness.light:
        return Colors.grey[400];
      case ThemeBrightness.dark:
        return Colors.grey[200];
    }
  }

  ThemeBrightness getColorBrightness(BuildContext context) {
    return Theme.of(context).brightness;
  }

}
