// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'theme.dart';

class CircleAvatar extends StatelessWidget {
  CircleAvatar({
    Key key,
    this.child,
    this.backgroundColor,
    this.radius: 40.0
  }) : super(key: key);

  final Widget child;
  final Color backgroundColor;
  final double radius;

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = backgroundColor ?? theme.primaryColor;

    return new AnimatedContainer(
      width: radius,
      height: radius,
      duration: kThemeChangeDuration,
      decoration: new BoxDecoration(
        backgroundColor: color,
        shape: BoxShape.circle
      ),
      child: new Center(
        child: new DefaultTextStyle(
          style: theme.primaryTextTheme.title,
          child: child
        )
      )
    );
  }
}
