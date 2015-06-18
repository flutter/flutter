// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme/colors.dart';
import 'basic.dart';
import 'material_button.dart';

export 'material_button.dart' show MaterialButtonTheme;

class FlatButton extends MaterialButton {
  FlatButton({
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
    if (!enabled || !highlight)
      return null;
    switch (theme) {
      case MaterialButtonTheme.light:
        return Grey[400];
      case MaterialButtonTheme.dark:
        return Grey[200];
    }
  }

  int get level => null;
}
