// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'theme.dart';
import 'typography.dart';

class CircleAvatar extends StatelessComponent {
  CircleAvatar({
    Key key,
    this.label,
    this.backgroundColor,
    this.textTheme
  }) : super(key: key);

  final String label;
  final Color backgroundColor;
  final TextTheme textTheme;

  Widget build(BuildContext context) {
    Color color = backgroundColor;
    TextStyle style = textTheme?.title;

    if (color == null || style == null) {
      ThemeData themeData = Theme.of(context);
      color ??= themeData.primaryColor;
      style ??= themeData.primaryTextTheme.title;
    }

    return new AnimatedContainer(
      duration: kThemeChangeDuration,
      decoration: new BoxDecoration(
        backgroundColor: color,
        shape: BoxShape.circle
      ),
      width: 40.0,
      height: 40.0,
      child: new Center(
        child: new Text(label, style: style)
      )
    );
  }
}
