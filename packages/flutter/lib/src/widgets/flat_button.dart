// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/material.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/material_button.dart';
import 'package:sky/src/widgets/theme.dart';

class FlatButton extends MaterialButton {
  FlatButton({
    Key key,
    Widget child,
    bool enabled: true,
    Function onPressed
  }) : super(key: key,
             child: child,
             enabled: enabled,
             onPressed: onPressed);

  Color get color {
    if (!enabled || !highlight)
      return null;
    switch (Theme.of(this).brightness) {
      case ThemeBrightness.light:
        return Colors.grey[400];
      case ThemeBrightness.dark:
        return Colors.grey[200];
    }
  }

  int get level => 0;
}
