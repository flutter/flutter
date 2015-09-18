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

typedef void DrawerDismissedCallback();

class Drawer extends StatefulComponent {
  Drawer({
    Key key,
    this.children,
    this.showing: false,
    this.level: 0,
    this.onDismissed,
    this.navigator
  }) : super(key: key);

  List<Widget> children;
  bool showing;
  int level;
  DrawerDismissedCallback onDismissed;
  Navigator navigator;

  AnimationPerformance _performance;

  void initState() {
    _performance = new AnimationPerformance(duration: _kBaseSettleDuration);
    _performance.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed)
        _handleDismissed();
    });
    // Use a spring force for animating the drawer. We can't use curves for
    // this because we need a linear curve in order to track the user's finger
    // while dragging.
    _performance.attachedForce = kDefaultSpringForce;
    if (navigator != null) {
      // TODO(ianh): This is crazy. We should convert drawer to use a pattern like openDialog().
      // https://github.com/domokit/sky_engine/pull/1186
      scheduleMicrotask(() {
        navigator.pushState(this, (_) => _performance.reverse());
      });
    }
    _performance.play(_direction);
  }

  Direction get _direction => showing ? Direction.forward : Direction.reverse;

  void syncConstructorArguments(Drawer source) {
    children = source.children;
    if (showing != source.showing) {
      showing = source.showing;
      _performance.play(_direction);
    }
    level = source.level;
    onDismissed = source.onDismissed;
    navigator = source.navigator;
  }

  Widget build() {
    var mask = new GestureDetector(
      child: new ColorTransition(
        performance: _performance.view,
        color: new AnimatedColorValue(Colors.transparent, end: const Color(0x7F000000)),
        child: new Container()
      ),
      onTap: () {
        _performance.reverse();
      }
    );

    Widget content = new SlideTransition(
      performance: _performance.view,
      position: new AnimatedValue<Point>(_kClosedPosition, end: _kOpenPosition),
      child: new AnimatedContainer(
        behavior: implicitlyAnimate(const Duration(milliseconds: 200)),
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(this).canvasColor,
          boxShadow: shadows[level]),
        width: _kWidth,
        child: new Block(children)
      )
    );

    return new GestureDetector(
      onHorizontalDragStart: _performance.stop,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: new Stack([ mask, content ])
    );
  }

  void _handleDismissed() {
    if (navigator != null &&
        navigator.currentRoute is RouteState &&
        (navigator.currentRoute as RouteState).owner == this) // TODO(ianh): remove cast once analyzer is cleverer
      navigator.pop();
    if (onDismissed != null)
      onDismissed();
  }

  bool get _isMostlyClosed => _performance.progress < 0.5;

  void _settle() { _isMostlyClosed ? _performance.reverse() : _performance.play(); }

  void _handleDragUpdate(double delta) {
    _performance.progress += delta / _kWidth;
  }

  void _handleDragEnd(Offset velocity) {
    if (velocity.dx.abs() >= _kMinFlingVelocity) {
      _performance.fling(velocity: velocity.dx * _kFlingVelocityScale);
    } else {
      _settle();
    }
  }

}
