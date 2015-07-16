// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/button_base.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/theme.dart';

// TODO(eseidel): This needs to change based on device size?
// http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;

class FloatingActionButton extends ButtonBase {

  FloatingActionButton({
    String key,
    this.child,
    this.backgroundColor,
    this.onPressed
  }) : super(key: key);

  Widget child;
  Color backgroundColor;
  Function onPressed;

  void syncFields(FloatingActionButton source) {
    super.syncFields(source);
    child = source.child;
    backgroundColor = source.backgroundColor;
    onPressed = source.onPressed;
  }

  Widget buildContent() {
    IconThemeColor iconThemeColor = IconThemeColor.white;
    Color materialColor = backgroundColor;
    if (materialColor == null) {
      ThemeData themeData = Theme.of(this);
      materialColor = themeData.accentColor;
      iconThemeColor = themeData.accentColorBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }

    return new Material(
      color: materialColor,
      type: MaterialType.circle,
      level: highlight ? 3 : 2,
      child: new ClipOval(
        child: new Listener(
          onGestureTap: (_) {
            if (onPressed != null)
              onPressed();
          },
          child: new Container(
            width: _kSize,
            height: _kSize,
            child: new InkWell(
              child: new Center(
                child: new IconTheme(
                  data: new IconThemeData(color: iconThemeColor),
                  child: child
                )
              )
            )
          )
        )
      )
    );
  }

}
