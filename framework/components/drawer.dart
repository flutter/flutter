// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/curves.dart';
import '../animation/generator.dart';
import '../fn.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;
import 'material.dart';

const double _kWidth = 256.0;
const double _kMinFlingVelocity = 0.4;
const double _kBaseSettleDurationMS = 246.0;
const double _kMaxSettleDurationMS = 600.0;
const Cubic _kAnimationCurve = easeOut;

class DrawerAnimation extends Animation {
  Stream<double> get onPositionChanged => onValueChanged;

  bool get _isMostlyClosed => value <= -_kWidth / 2;

  DrawerAnimation() {
    value = -_kWidth;
  }

  void toggle(_) => _isMostlyClosed ? _open() : _close();

  void handleMaskTap(_) => _close();

  void handlePointerDown(_) => stop();

  void handlePointerMove(sky.PointerEvent event) {
    assert(!isAnimating);
    value = math.min(0.0, math.max(value + event.dx, -_kWidth));
  }

  void handlePointerUp(_) {
    if (!isAnimating)
      _settle();
  }

  void handlePointerCancel(_) {
    if (!isAnimating)
      _settle();
  }

  void _open() => _animateToPosition(0.0);

  void _close() => _animateToPosition(-_kWidth);

  void _settle() => _isMostlyClosed ? _close() : _open();

  void _animateToPosition(double targetPosition) {
    double distance = (targetPosition - value).abs();
    if (distance != 0) {
      double targetDuration = distance / _kWidth * _kBaseSettleDurationMS;
      double duration = math.min(targetDuration, _kMaxSettleDurationMS);
      animateTo(targetPosition, duration, curve: _kAnimationCurve);
    }
  }

  void handleFlingStart(event) {
    double direction = event.velocityX.sign;
    double velocityX = event.velocityX.abs() / 1000;
    if (velocityX < _kMinFlingVelocity)
      return;

    double targetPosition = direction < 0.0 ? -_kWidth : 0.0;
    double distance = (targetPosition - value).abs();
    double duration = distance / velocityX;

    animateTo(targetPosition, duration, curve: linear);
  }
}

class Drawer extends Component {
  static final Style _style = new Style('''
    position: absolute;
    z-index: 2;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;'''
  );

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
    z-index: 3;
    width: 256px;
    top: 0;
    left: 0;
    bottom: 0;'''
  );

  DrawerAnimation animation;
  List<Node> children;
  int level;

  Drawer({
    Object key,
    this.animation,
    this.children,
    this.level: 0
  }) : super(key: key) {
    events.listen('pointerdown', animation.handlePointerDown);
    events.listen('pointermove', animation.handlePointerMove);
    events.listen('pointerup', animation.handlePointerUp);
    events.listen('pointercancel', animation.handlePointerCancel);
  }

  double _position = -_kWidth;

  bool _listening = false;

  void _ensureListening() {
    if (_listening)
      return;

    _listening = true;
    animation.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  Node build() {
    _ensureListening();

    bool isClosed = _position <= -_kWidth;
    String inlineStyle = 'display: ${isClosed ? 'none' : ''}';
    String maskInlineStyle = 'opacity: ${(_position / _kWidth + 1) * 0.25}';
    String contentInlineStyle = 'transform: translateX(${_position}px)';

    Container mask = new Container(
      key: 'Mask',
      styles: [_maskStyle],
      inlineStyle: maskInlineStyle
    )..events.listen('gesturetap', animation.handleMaskTap)
     ..events.listen('gestureflingstart', animation.handleFlingStart);

    Material content = new Material(
      key: 'Content',
      styles: [_contentStyle],
      inlineStyle: contentInlineStyle,
      children: children,
      level: level
    );

    return new Container(
      styles: [_style],
      inlineStyle: inlineStyle,
      children: [ mask, content ]
    );
  }
}
