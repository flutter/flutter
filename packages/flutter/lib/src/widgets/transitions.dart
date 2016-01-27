// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/animation.dart' show AnimationDirection;
export 'package:flutter/rendering.dart' show RelativeRect;

abstract class AnimatedComponent extends StatefulComponent {
  AnimatedComponent({
    Key key,
    this.animation
  }) : super(key: key) {
    assert(animation != null);
  }

  final Animation<Object> animation;

  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  _AnimatedComponentState createState() => new _AnimatedComponentState();

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('animation: $animation');
  }
}

class _AnimatedComponentState extends State<AnimatedComponent> {
  void initState() {
    super.initState();
    config.animation.addListener(_handleTick);
  }

  void didUpdateConfig(AnimatedComponent oldConfig) {
    if (config.animation != oldConfig.animation) {
      oldConfig.animation.removeListener(_handleTick);
      config.animation.addListener(_handleTick);
    }
  }

  void dispose() {
    config.animation.removeListener(_handleTick);
    super.dispose();
  }

  void _handleTick() {
    setState(() {
      // The animation's state is our build state, and it changed already.
    });
  }

  Widget build(BuildContext context) {
    return config.build(context);
  }
}

class SlideTransition extends AnimatedComponent {
  SlideTransition({
    Key key,
    Animation<FractionalOffset> position,
    this.transformHitTests: true,
    this.child
  }) : position = position, super(key: key, animation: position);

  final Animation<FractionalOffset> position;
  final bool transformHitTests;
  final Widget child;

  Widget build(BuildContext context) {
    return new FractionalTranslation(
      translation: position.value,
      transformHitTests: transformHitTests,
      child: child
    );
  }
}

class ScaleTransition extends AnimatedComponent {
  ScaleTransition({
    Key key,
    Animation<double> scale,
    this.alignment: const FractionalOffset(0.5, 0.5),
    this.child
  }) : scale = scale, super(key: key, animation: scale);

  final Animation<double> scale;
  final FractionalOffset alignment;
  final Widget child;

  Widget build(BuildContext context) {
    double scaleValue = scale.value;
    Matrix4 transform = new Matrix4.identity()
      ..scale(scaleValue, scaleValue);
    return new Transform(
      transform: transform,
      alignment: alignment,
      child: child
    );
  }
}

class RotationTransition extends AnimatedComponent {
  RotationTransition({
    Key key,
    Animation<double> turns,
    this.child
  }) : turns = turns, super(key: key, animation: turns);

  final Animation<double> turns;
  final Widget child;

  Widget build(BuildContext context) {
    double turnsValue = turns.value;
    Matrix4 transform = new Matrix4.rotationZ(turnsValue * math.PI * 2.0);
    return new Transform(
      transform: transform,
      alignment: const FractionalOffset(0.5, 0.5),
      child: child
    );
  }
}

class FadeTransition extends AnimatedComponent {
  FadeTransition({
    Key key,
    Animation<double> opacity,
    this.child
  }) : opacity = opacity, super(key: key, animation: opacity);

  final Animation<double> opacity;
  final Widget child;

  Widget build(BuildContext context) {
    return new Opacity(opacity: opacity.value, child: child);
  }
}

class ColorTransition extends AnimatedComponent {
  ColorTransition({
    Key key,
    Animation<Color> color,
    this.child
  }) : color = color, super(key: key, animation: color);

  final Animation<Color> color;
  final Widget child;

  Widget build(BuildContext context) {
    return new DecoratedBox(
      decoration: new BoxDecoration(backgroundColor: color.value),
      child: child
    );
  }
}

/// An animated variable containing a RelativeRectangle
///
/// This class specializes the interpolation of AnimatedValue<RelativeRect> to
/// be appropriate for rectangles that are described in terms of offsets from
/// other rectangles.
class RelativeRectTween extends Tween<RelativeRect> {
  RelativeRectTween({ RelativeRect begin, RelativeRect end })
    : super(begin: begin, end: end);

  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t);
}

/// Animated version of [Positioned] which takes a specific
/// [Animation<RelativeRect>] to transition the child's position from a start
/// position to and end position over the lifetime of the animation.
///
/// Only works if it's the child of a [Stack].
class PositionedTransition extends AnimatedComponent {
  PositionedTransition({
    Key key,
    Animation<RelativeRect> rect,
    this.child
  }) : rect = rect, super(key: key, animation: rect) {
    assert(rect != null);
  }

  final Animation<RelativeRect> rect;
  final Widget child;

  Widget build(BuildContext context) {
    return new Positioned(
      top: rect.value.top,
      right: rect.value.right,
      bottom: rect.value.bottom,
      left: rect.value.left,
      child: child
    );
  }
}

typedef Widget TransitionBuilder(BuildContext context, Widget child);

class AnimatedBuilder extends AnimatedComponent {
  AnimatedBuilder({
    Key key,
    Animation<Object> animation,
    this.builder,
    this.child
  }) : super(key: key, animation: animation);

  final TransitionBuilder builder;
  final Widget child;

  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
