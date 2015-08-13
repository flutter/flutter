// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/forces.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/animated_container.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/transitions.dart';

export 'package:sky/animation/animation_performance.dart' show AnimationStatus;

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

    // Use a spring force for animating the drawer. We can't use curves for
    // this because we need a linear curve in order to track the user's finger
    // while dragging.
    _performance.attachedForce = kDefaultSpringForce;

    if (navigator != null) {
      navigator.pushState(this, (_) => _performance.reverse());
    }
  }

  void syncFields(Drawer source) {
    children = source.children;
    level = source.level;
    navigator = source.navigator;
    showing = source.showing;
    onDismissed = source.onDismissed;
  }

  Widget build() {
    var mask = new Listener(
      child: new ColorTransition(
        performance: _performance,
        direction: showing ? Direction.forward : Direction.reverse,
        color: new AnimatedColorValue(colors.transparent, end: const Color(0x7F000000)),
        child: new Container()
      ),
      onGestureTap: handleMaskTap
    );

    Widget content = new SlideTransition(
      performance: _performance,
      direction: showing ? Direction.forward : Direction.reverse,
      position: new AnimatedValue<Point>(_kClosedPosition, end: _kOpenPosition),
      onDismissed: _onDismissed,
      child: new AnimatedContainer(
        behavior: implicitlyAnimate(const Duration(milliseconds: 200)),
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(this).canvasColor,
          boxShadow: shadows[level]),
        width: _kWidth,
        child: new ScrollableBlock(children)
      )
    );

    return new Listener(
      child: new Stack([ mask, content ]),
      onPointerDown: handlePointerDown,
      onPointerMove: handlePointerMove,
      onPointerUp: handlePointerUp,
      onPointerCancel: handlePointerCancel,
      onGestureFlingStart: handleFlingStart
    );
  }

  void _onDismissed() {
    if (navigator != null &&
        navigator.currentRoute is RouteState &&
        (navigator.currentRoute as RouteState).owner == this) // TODO(ianh): remove cast once analyzer is cleverer
      navigator.pop();
    if (onDismissed != null)
      onDismissed();
  }

  bool get _isMostlyClosed => _performance.progress < 0.5;

  void _settle() { _isMostlyClosed ? _performance.reverse() : _performance.play(); }

  EventDisposition handleMaskTap(_) {
    _performance.reverse();
    return EventDisposition.consumed;
  }

  // TODO(mpcomplete): Figure out how to generalize these handlers on a
  // "PannableThingy" interface.
  EventDisposition handlePointerDown(_) {
    _performance.stop();
    return EventDisposition.processed;
 }

  EventDisposition handlePointerMove(sky.PointerEvent event) {
    if (_performance.isAnimating)
      return EventDisposition.ignored;
    _performance.progress += event.dx / _kWidth;
    return EventDisposition.processed;
  }

  EventDisposition handlePointerUp(_) {
    if (!_performance.isAnimating) {
      _settle();
      return EventDisposition.processed;
    }
    return EventDisposition.ignored;
  }

  EventDisposition handlePointerCancel(_) {
    if (!_performance.isAnimating) {
      _settle();
      return EventDisposition.processed;
    }
    return EventDisposition.ignored;
  }

  EventDisposition handleFlingStart(event) {
    if (event.velocityX.abs() >= _kMinFlingVelocity) {
      _performance.fling(velocity: event.velocityX * _kFlingVelocityScale);
      return EventDisposition.processed;
    }
    return EventDisposition.ignored;
  }
}
