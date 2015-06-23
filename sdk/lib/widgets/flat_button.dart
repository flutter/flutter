// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme/colors.dart';
import 'basic.dart';
import 'material_button.dart';
import 'theme.dart';

class FlatButton extends MaterialButton {
  FlatButton({
    String key,
    Widget child,
    bool enabled: true,
    Function onPressed
  }) : super(key: key,
             child: child,
             enabled: enabled,
             onPressed: onPressed);

  Color get color {
    if (!enabled || !highlight)
      return const Color(0x00000000);
    switch (Theme.of(this).brightness) {
      case ThemeBrightness.light:
        return Grey[400];
      case ThemeBrightness.dark:
        return Grey[200];
    }
  }

  int get level => null;
}
