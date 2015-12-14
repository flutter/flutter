// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

// TODO(eseidel): This needs to change based on device size?
// http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;
const double _kSizeMini = 40.0;

class FloatingActionButton extends StatefulComponent {
  const FloatingActionButton({
    Key key,
    this.child,
    this.backgroundColor,
    this.elevation: 6,
    this.highlightElevation: 12,
    this.onPressed,
    this.mini: false
  }) : super(key: key);

  final Widget child;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final int elevation;
  final int highlightElevation;
  final bool mini;

  _FloatingActionButtonState createState() => new _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton> {
  bool _highlight = false;

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  Widget build(BuildContext context) {
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
      elevation: _highlight ? config.highlightElevation : config.elevation,
      child: new Container(
        width: config.mini ? _kSizeMini : _kSize,
        height: config.mini ? _kSizeMini : _kSize,
        child: new InkWell(
          onTap: config.onPressed,
          onHighlightChanged: _handleHighlightChanged,
          child: new Center(
            child: new IconTheme(
              data: new IconThemeData(color: iconThemeColor),
              child: config.child
            )
          )
        )
      )
    );
  }
}
