// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'animated_component.dart';
import '../animation/animated_value.dart';
import '../animation/curves.dart';
import '../fn.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'material.dart';

const double _kWidth = 304.0;
const double _kMinFlingVelocity = 0.4;
const double _kBaseSettleDurationMS = 246.0;
const double _kMaxSettleDurationMS = 600.0;
const Curve _kAnimationCurve = parabolicRise;

class DrawerController {
  final AnimatedValue position = new AnimatedValue(-_kWidth);

  bool get _isMostlyClosed => position.value <= -_kWidth / 2;

  void toggle(_) => _isMostlyClosed ? _open() : _close();

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

    position.animateTo(targetPosition, duration, curve: linear);
  }
}

class Drawer extends AnimatedComponent {
  // TODO(abarth): We need a better way to become a container for absolutely
  // positioned elements.
  static final Style _style = new Style('''
    transform: translateX(0);''');

  static final Style _maskStyle = new Style('''
    background-color: black;
    will-change: opacity;
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;'''
  );

  static final Style _contentStyle = new Style('''
    background-color: ${Grey[50]};
    will-change: transform;
    position: absolute;
    width: ${_kWidth}px;
    top: 0;
    left: 0;
    bottom: 0;'''
  );

  List<Node> children;
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

  Node build() {
    bool isClosed = _position <= -_kWidth;
    String inlineStyle = 'display: ${isClosed ? 'none' : ''}';
    String maskInlineStyle = 'opacity: ${(_position / _kWidth + 1) * 0.5}';
    String contentInlineStyle = 'transform: translateX(${_position}px)';

    var mask = new EventTarget(
      new Container(
        key: 'Mask',
        style: _maskStyle,
        inlineStyle: maskInlineStyle
      ),
      onGestureTap: controller.handleMaskTap,
      onGestureFlingStart: controller.handleFlingStart
    );

    Material content = new Material(
      key: 'Content',
      style: _contentStyle,
      inlineStyle: contentInlineStyle,
      children: children,
      level: level
    );

    return new EventTarget(
      new Container(
        style: _style,
        inlineStyle: inlineStyle,
        children: [ mask, content ]
      ),
      onPointerDown: controller.handlePointerDown,
      onPointerMove: controller.handlePointerMove,
      onPointerUp: controller.handlePointerUp,
      onPointerCancel: controller.handlePointerCancel
    );
  }
}
