// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'constants.dart';
import 'scaffold.dart';
import 'theme.dart';

class FlexibleSpaceBar extends StatefulWidget {
  FlexibleSpaceBar({ Key key, this.title, this.image }) : super(key: key);

  final Widget title;
  final Widget image;

  @override
  _FlexibleSpaceBarState createState() => new _FlexibleSpaceBarState();
}

class _FlexibleSpaceBarState extends State<FlexibleSpaceBar> {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasScaffold(context));
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final Animation<double> animation = Scaffold.of(context).appBarAnimation;
    final double appBarHeight = Scaffold.of(context).appBarHeight + statusBarHeight;
    final double toolBarHeight = kToolBarHeight + statusBarHeight;
    final List<Widget> children = <Widget>[];

    // background image
    if (config.image != null) {
      final double fadeStart = (appBarHeight - toolBarHeight * 2.0) / appBarHeight;
      final double fadeEnd = (appBarHeight - toolBarHeight) / appBarHeight;
      final CurvedAnimation opacityCurve = new CurvedAnimation(
        parent: animation,
        curve: new Interval(math.max(0.0, fadeStart), math.min(fadeEnd, 1.0))
      );
      final double parallax = new Tween<double>(begin: 0.0, end: appBarHeight / 4.0).evaluate(animation);
      children.add(new Positioned(
        top: -parallax,
        left: 0.0,
        right: 0.0,
        child: new Opacity(
          opacity: new Tween<double>(begin: 1.0, end: 0.0).evaluate(opacityCurve),
          child: new SizedBox(
            height: appBarHeight + statusBarHeight,
            child: config.image
          )
        )
       ));
    }

    // title
    if (config.title != null) {
      final double fadeStart = (appBarHeight - toolBarHeight) / appBarHeight;
      final double fadeEnd = (appBarHeight - toolBarHeight / 2.0) / appBarHeight;
      final CurvedAnimation opacityCurve = new CurvedAnimation(
        parent: animation,
        curve: new Interval(fadeStart, fadeEnd)
      );
      TextStyle titleStyle = Theme.of(context).primaryTextTheme.title;
      titleStyle = titleStyle.copyWith(
        color: titleStyle.color.withAlpha(new Tween<double>(begin: 255.0, end: 0.0).evaluate(opacityCurve).toInt())
      );
      final double yAlignStart = 1.0;
      final double yAlignEnd = (statusBarHeight + kToolBarHeight / 2.0) / toolBarHeight;
      final double scaleAndAlignEnd = (appBarHeight - toolBarHeight) / appBarHeight;
      final CurvedAnimation scaleAndAlignCurve = new CurvedAnimation(
        parent: animation,
        curve: new Interval(0.0, scaleAndAlignEnd)
      );
      children.add(new Padding(
        padding: const EdgeInsets.only(left: 72.0, bottom: 14.0),
        child: new Align(
          alignment: new Tween<FractionalOffset>(
            begin: new FractionalOffset(0.0, yAlignStart),
            end: new FractionalOffset(0.0, yAlignEnd)
          ).evaluate(scaleAndAlignCurve),
          child: new ScaleTransition(
            alignment: const FractionalOffset(0.0, 1.0),
            scale: new Tween<double>(begin: 1.5, end: 1.0).animate(scaleAndAlignCurve),
            child: new Align(
              alignment: new FractionalOffset(0.0, 1.0),
              child: new DefaultTextStyle(style: titleStyle, child: config.title)
            )
          )
        )
      ));
    }

    return new ClipRect(child: new Stack(children: children));
  }
}
