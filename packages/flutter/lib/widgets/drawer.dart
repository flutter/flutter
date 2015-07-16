// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/animation_builder.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scrollable_viewport.dart';
import 'package:sky/widgets/theme.dart';
import 'package:vector_math/vector_math.dart';

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
const double _kMinFlingVelocity = 1.2;
const Duration _kBaseSettleDuration = const Duration(milliseconds: 246);
// TODO(mpcomplete): The curve must be linear if we want the drawer to track
// the user's finger. Odeon remedies this by attaching spring forces to the
// initial timeline when animating (so it doesn't look linear).
const Point _kOpenPosition = Point.origin;
const Point _kClosedPosition = const Point(-_kWidth, 0.0);
const Curve _kAnimationCurve = linear;

typedef void DrawerStatusChangeHandler (bool showing);

enum DrawerStatus {
  active,
  inactive,
}

typedef void DrawerStatusChangedCallback(DrawerStatus status);

class Drawer extends AnimatedComponent {
  Drawer({
    String key,
    this.children,
    this.showing: false,
    this.level: 0,
    this.onStatusChanged,
    this.navigator
  }) : super(key: key);

  List<Widget> children;
  bool showing;
  int level;
  DrawerStatusChangedCallback onStatusChanged;
  Navigator navigator;

  AnimatedType<Point> _position;
  AnimatedColor _maskColor;
  AnimationPerformance _performance;

  void initState() {
    _position = new AnimatedType<Point>(_kClosedPosition, end: _kOpenPosition, curve: _kAnimationCurve);
    _maskColor = new AnimatedColor(colors.transparent, end: const Color(0x7F000000));
    _performance = new AnimationPerformance()
      ..duration = _kBaseSettleDuration
      ..variable = new AnimatedList([_position, _maskColor])
      ..addListener(_checkForStateChanged);
    watch(_performance);
    if (showing)
      _show();
  }

  void syncFields(Drawer source) {
    children = source.children;
    level = source.level;
    navigator = source.navigator;
    if (showing != source.showing) {
      showing = source.showing;
      showing ? _show() : _hide();
    }
    onStatusChanged = source.onStatusChanged;
    super.syncFields(source);
  }

  void _show() {
    if (navigator != null)
      navigator.pushState(this, (_) => _performance.reverse());
    _performance.play();
  }

  void _hide() {
    _performance.reverse();
  }

  Widget build() {
    var mask = new Listener(
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: _maskColor.value)
      ),
      onGestureTap: handleMaskTap
    );

    Matrix4 transform = new Matrix4.identity();
    transform.translate(_position.value.x, _position.value.y);
    Widget content = new Transform(
      transform: transform,
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(this).canvasColor,
          boxShadow: shadows[level]),
        width: _kWidth,
        child: new ScrollableBlock(children)
      ));

    return new Listener(
      child: new Stack([ mask, content ]),
      onPointerDown: handlePointerDown,
      onPointerMove: handlePointerMove,
      onPointerUp: handlePointerUp,
      onPointerCancel: handlePointerCancel,
      onGestureFlingStart: handleFlingStart
    );
  }

  double get xPosition => _position.value.x;

  DrawerStatus _lastStatus;
  void _checkForStateChanged() {
    DrawerStatus status = _status;
    if (_lastStatus != null && status != _lastStatus) {
      if (status == DrawerStatus.inactive &&
          navigator != null &&
          navigator.currentRoute.key == this)
        navigator.pop();
      if (onStatusChanged != null)
        onStatusChanged(status);
    }
    _lastStatus = status;
  }

  DrawerStatus get _status => _performance.isDismissed ? DrawerStatus.inactive : DrawerStatus.active;
  bool get _isMostlyClosed => xPosition <= -_kWidth/2;

  void _settle() => _isMostlyClosed ? _performance.reverse() : _performance.play();

  void handleMaskTap(_) => _performance.reverse();

  // TODO(mpcomplete): Figure out how to generalize these handlers on a
  // "PannableThingy" interface.
  void handlePointerDown(_) => _performance.stop();

  void handlePointerMove(sky.PointerEvent event) {
    if (_performance.isAnimating)
      return;
    _performance.progress += event.dx / _kWidth;
  }

  void handlePointerUp(_) {
    if (!_performance.isAnimating)
      _settle();
  }

  void handlePointerCancel(_) {
    if (!_performance.isAnimating)
      _settle();
  }

  void handleFlingStart(event) {
    double velocityX = event.velocityX / _kWidth;
    if (velocityX.abs() >= _kMinFlingVelocity)
      _performance.fling(velocity: velocityX);
  }
}
