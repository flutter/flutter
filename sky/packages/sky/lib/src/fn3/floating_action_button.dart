// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/gestures.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/button_state.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';
import 'package:sky/src/fn3/icon.dart';
import 'package:sky/src/fn3/ink_well.dart';
import 'package:sky/src/fn3/material.dart';
import 'package:sky/src/fn3/theme.dart';

// TODO(eseidel): This needs to change based on device size?
// http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;

class FloatingActionButton extends StatefulComponent {
  const FloatingActionButton({
    Key key,
    this.child,
    this.backgroundColor,
    this.onPressed
  }) : super(key: key);

  final Widget child;
  final Color backgroundColor;
  final GestureTapListener onPressed;

  FloatingActionButtonState createState() => new FloatingActionButtonState(this);
}

class FloatingActionButtonState extends ButtonState<FloatingActionButton> {
  FloatingActionButtonState(FloatingActionButton config) : super(config);

  Widget buildContent(BuildContext context) {
    IconThemeColor iconThemeColor = IconThemeColor.white;
    Color materialColor = config.backgroundColor;
    if (materialColor == null) {
      ThemeData themeData = Theme.of(context);
      materialColor = themeData.accentColor;
      iconThemeColor = themeData.accentColorBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }

    return new Material(
      color: materialColor,
      type: MaterialType.circle,
      level: highlight ? 3 : 2,
      child: new ClipOval(
        child: new GestureDetector(
          onTap: config.onPressed,
          child: new Container(
            width: _kSize,
            height: _kSize,
            child: new InkWell(
              child: new Center(
                child: new IconTheme(
                  data: new IconThemeData(color: iconThemeColor),
                  child: config.child
                )
              )
            )
          )
        )
      )
    );
  }
}
