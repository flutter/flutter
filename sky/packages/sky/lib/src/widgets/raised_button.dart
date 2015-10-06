// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/gestures.dart';
import 'package:sky/material.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/material_button.dart';
import 'package:sky/src/widgets/theme.dart';

class RaisedButton extends MaterialButton {
  RaisedButton({
    Key key,
    Widget child,
    bool enabled: true,
    GestureTapCallback onPressed
  }) : super(key: key,
             child: child,
             enabled: enabled,
             onPressed: onPressed) {
    assert(enabled != null);
  }

  _RaisedButtonState createState() => new _RaisedButtonState();
}

class _RaisedButtonState extends MaterialButtonState<RaisedButton> {
  Color getColor(BuildContext context) {
    if (config.enabled) {
      switch (Theme.of(context).brightness) {
        case ThemeBrightness.light:
          if (highlight)
            return Colors.grey[350];
          else
            return Colors.grey[300];
          break;
        case ThemeBrightness.dark:
          if (highlight)
            return Theme.of(context).primarySwatch[700];
          else
            return Theme.of(context).primarySwatch[600];
          break;
      }
    } else {
      return Colors.grey[350];
    }
  }

  int get level => config.enabled ? (highlight ? 2 : 1) : 0;
}
