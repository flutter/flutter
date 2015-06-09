// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../animation/curves.dart';
import '../fn2.dart';
import '../theme2/colors.dart';
import '../theme2/shadows.dart';
import 'animated_component.dart';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'material.dart';
import 'package:vector_math/vector_math.dart';

const double _kWidth = 304.0;
const double _kMinFlingVelocity = 0.4;
const double _kBaseSettleDurationMS = 246.0;
const double _kMaxSettleDurationMS = 600.0;
const Curve _kAnimationCurve = parabolicRise;

typedef void DrawerStatusChangeHandler (bool showing);

class DrawerController {

  DrawerController(this.onStatusChange) {
    position = new AnimatedValue(-_kWidth, onChange: _checkValue);
  }
  final DrawerStatusChangeHandler onStatusChange;
  AnimatedValue position;

  bool _oldClosedState = true;
  void _checkValue() {
    var newClosedState = isClosed;
    if (onStatusChange != null && _oldClosedState != newClosedState) {
      onStatusChange(!newClosedState);
      _oldClosedState = newClosedState;
    }
  }

  bool get isClosed => position.value == -_kWidth;
  bool get _isMostlyClosed => position.value <= -_kWidth / 2;
  void toggle() => _isMostlyClosed ? _open() : _close();

  void handleMaskTap(_) => _close();
  void handlePointerDown(_) => position.stop();

  void handlePointerMove(sky.PointerEvent event) {
    if (position.isAnimating)
      return;
    position.value = math.min(0.0, math.max(position.value + event.dx, -_kWidth));
  }

  void handlePointerUp(_) {
    if (!position.isAnimating)
      _settle();
  }

  void handlePointerCancel(_) {
    if (!position.isAnimating)
      _settle();
  }

  void _open() => _animateToPosition(0.0);

  void _close() => _animateToPosition(-_kWidth);

  void _settle() => _isMostlyClosed ? _close() : _open();

  void _animateToPosition(double targetPosition) {
    double distance = (targetPosition - position.value).abs();
    if (distance != 0) {
      double targetDuration = distance / _kWidth * _kBaseSettleDurationMS;
      double duration = math.min(targetDuration, _kMaxSettleDurationMS);
      position.animateTo(targetPosition, duration, curve: _kAnimationCurve);
    }
  }

  void handleFlingStart(event) {
    double direction = event.velocityX.sign;
    double velocityX = event.velocityX.abs() / 1000;
    if (velocityX < _kMinFlingVelocity)
      return;

    double targetPosition = direction < 0.0 ? -_kWidth : 0.0;
    double distance = (targetPosition - position.value).abs();
    double duration = distance / velocityX;

    if (distance > 0)
      position.animateTo(targetPosition, duration, curve: linear);
  }
}

class Drawer extends AnimatedComponent {
  List<UINode> children;
  int level;
  DrawerController controller;

  double _position;

  Drawer({
    Object key,
    this.controller,
    this.children,
    this.level: 0
  }) : super(key: key) {
    animateField(controller.position, #_position);
  }

  UINode build() {
    Matrix4 transform = new Matrix4.identity();
    transform.translate(_position);

    double scaler = _position / _kWidth + 1;
    Color maskColor = new Color.fromARGB((0x7F * scaler).floor(), 0, 0, 0);

    var mask = new EventListenerNode(
      new Container(decoration: new BoxDecoration(backgroundColor: maskColor)),
      onGestureTap: controller.handleMaskTap,
      onGestureFlingStart: controller.handleFlingStart
    );

    Container content = new Container(
      decoration: new BoxDecoration(
        backgroundColor: Grey[50],
        boxShadow: Shadow[level]),
      width: _kWidth,
      transform: transform,
      child: new BlockContainer(children: children)
    );

    return new EventListenerNode(
      new StackContainer(
        children: [ mask, content ]
      ),
      onPointerDown: controller.handlePointerDown,
      onPointerMove: controller.handlePointerMove,
      onPointerUp: controller.handlePointerUp,
      onPointerCancel: controller.handlePointerCancel
    );
  }
}
