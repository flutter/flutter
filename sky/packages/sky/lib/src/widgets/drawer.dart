// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/animation.dart';
import 'package:sky/material.dart';
import 'package:sky/src/widgets/animated_container.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/gesture_detector.dart';
import 'package:sky/src/widgets/navigator.dart';
import 'package:sky/src/widgets/scrollable.dart';
import 'package:sky/src/widgets/theme.dart';
import 'package:sky/src/widgets/transitions.dart';
import 'package:sky/src/widgets/focus.dart';

// TODO(eseidel): Draw width should vary based on device size:
// http://www.google.com/design/spec/layout/structure.html#structure-side-nav

// Mobile:
// Width = Screen width − 56 dp
// Maximum width: 320dp
// Maximum width applies only when using a left nav. When using a right nav,
// the panel can cover the full width of the screen.

// Desktop/Tablet:
// Maximum width for a left nav is 400dp.
// The right nav can vary depending on content.

const double _kWidth = 304.0;
const double _kMinFlingVelocity = 365.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const Duration _kBaseSettleDuration = const Duration(milliseconds: 246);
const Duration _kThemeChangeDuration = const Duration(milliseconds: 200);
const Point _kOpenPosition = Point.origin;
const Point _kClosedPosition = const Point(-_kWidth, 0.0);

class Drawer extends StatefulComponent {
  Drawer({
    Key key,
    this.child,
    this.level: 3,
    this.navigator
  }) : super(key: key);

  final Widget child;
  final int level;
  final NavigatorState navigator;

  DrawerState createState() => new DrawerState();
}

class DrawerState extends State<Drawer> {
  void initState() {
    super.initState();
    _performance = new Performance(duration: _kBaseSettleDuration)
      ..addStatusListener((PerformanceStatus status) {
        if (status == PerformanceStatus.dismissed)
          config.navigator.pop();
      });
    _open();
  }

  Performance _performance;

  Widget build(BuildContext context) {
    Widget mask = new GestureDetector(
      onTap: _close,
      child: new ColorTransition(
        performance: _performance.view,
        color: new AnimatedColorValue(Colors.transparent, end: Colors.black54),
        child: new Container()
      )
    );

    Widget content = new SlideTransition(
      performance: _performance.view,
      position: new AnimatedValue<Point>(_kClosedPosition, end: _kOpenPosition),
      child: new AnimatedContainer(
        curve: ease,
        duration: _kThemeChangeDuration,
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(context).canvasColor,
          boxShadow: shadows[config.level]),
        width: _kWidth,
        child: config.child
      )
    );

    return new GestureDetector(
      onHorizontalDragStart: _performance.stop,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: new Stack([
        mask,
        new Positioned(
          top: 0.0,
          left: 0.0,
          bottom: 0.0,
          child: content
        )
      ])
    );
  }

  bool get _isMostlyClosed => _performance.progress < 0.5;

  void _handleDragUpdate(double delta) {
    _performance.progress += delta / _kWidth;
  }

  void _open() {
    _performance.fling(velocity: 1.0);
  }

  void _close() {
    _performance.fling(velocity: -1.0);
  }

  void _handleDragEnd(Offset velocity) {
    if (velocity.dx.abs() >= _kMinFlingVelocity) {
      _performance.fling(velocity: velocity.dx * _kFlingVelocityScale);
    } else if (_isMostlyClosed) {
      _close();
    } else {
      _open();
    }
  }
}

class DrawerRoute extends Route {
  DrawerRoute({ this.child, this.level });

  final Widget child;
  final int level;

  bool get opaque => false;

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) {
    return new Focus(
      key: new GlobalObjectKey(this),
      autofocus: true,
      child: new Drawer(
        child: child,
        level: level,
        navigator: navigator
      )
    );
  }
}

void showDrawer({ NavigatorState navigator, Widget child, int level: 3 }) {
  navigator.push(new DrawerRoute(child: child, level: level));
}
