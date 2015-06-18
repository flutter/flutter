// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme/colors.dart';
import 'basic.dart';
import 'material_button.dart';

export 'material_button.dart' show MaterialButtonTheme;

class RaisedButton extends MaterialButton {

  RaisedButton({
    String key,
    Widget child,
    bool enabled: true,
    Function onPressed,
    MaterialButtonTheme theme: MaterialButtonTheme.light
  }) : super(key: key,
             child: child,
             enabled: enabled,
             onPressed: onPressed,
             theme: theme);

  Color get color {
    if (enabled) {
      switch (theme) {
        case MaterialButtonTheme.light:
          if (highlight)
            return Grey[350];
          else
            return Grey[300];
          break;
        case MaterialButtonTheme.dark:
          if (highlight)
            return Blue[700];
          else
            return Blue[600];
          break;
      }
    } else {
      return Grey[350];
    }
  }

  int get level => enabled ? (highlight ? 2 : 1) : 0;
}
