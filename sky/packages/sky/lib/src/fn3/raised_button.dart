// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/material.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/material_button.dart';
import 'package:sky/src/fn3/theme.dart';

class RaisedButton extends MaterialButton {
  RaisedButton({
    Key key,
    Widget child,
    bool enabled: true,
    Function onPressed
  }) : super(key: key,
             child: child,
             enabled: enabled,
             onPressed: onPressed) {
    assert(enabled != null);
  }

  RaisedButtonState createState() => new RaisedButtonState();
}

class RaisedButtonState extends MaterialButtonState<RaisedButton> {
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
