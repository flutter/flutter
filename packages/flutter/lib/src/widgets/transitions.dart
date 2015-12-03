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

abstract class TransitionComponent extends StatefulComponent {
  TransitionComponent({
    Key key,
    this.performance
  }) : super(key: key) {
    assert(performance != null);
  }

  final PerformanceView performance;

  Widget build(BuildContext context);

  _TransitionState createState() => new _TransitionState();

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('performance: $performance');
  }
}

class _TransitionState extends State<TransitionComponent> {
  void initState() {
    super.initState();
    config.performance.addListener(_performanceChanged);
  }

  void didUpdateConfig(TransitionComponent oldConfig) {
    if (config.performance != oldConfig.performance) {
      oldConfig.performance.removeListener(_performanceChanged);
      config.performance.addListener(_performanceChanged);
    }
  }

  void dispose() {
    config.performance.removeListener(_performanceChanged);
    super.dispose();
  }

  void _performanceChanged() {
    setState(() {
      // The performance's state is our build state, and it changed already.
    });
  }

  Widget build(BuildContext context) {
    return config.build(context);
  }
}

abstract class TransitionWithChild extends TransitionComponent {
  TransitionWithChild({
    Key key,
    this.child,
    PerformanceView performance
  }) : super(key: key, performance: performance);

  final Widget child;

  Widget build(BuildContext context) => buildWithChild(context, child);

  Widget buildWithChild(BuildContext context, Widget child);
}

class SlideTransition extends TransitionWithChild {
  SlideTransition({
    Key key,
    this.position,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedValue<Point> position;

  Widget buildWithChild(BuildContext context, Widget child) {
    performance.updateVariable(position);
    Matrix4 transform = new Matrix4.identity()
      ..translate(position.value.x, position.value.y);
    return new Transform(transform: transform, child: child);
  }
}

class RotationTransition extends TransitionWithChild {
  RotationTransition({
    Key key,
    this.turns,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedValue<double> turns;

  Widget buildWithChild(BuildContext context, Widget child) {
    performance.updateVariable(turns);
    Matrix4 transform = new Matrix4.rotationZ(turns.value * math.PI * 2.0);
    return new Transform(
      transform: transform,
      alignment: const FractionalOffset(0.5, 0.5),
      child: child
    );
  }
}

class FadeTransition extends TransitionWithChild {
  FadeTransition({
    Key key,
    this.opacity,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedValue<double> opacity;

  Widget buildWithChild(BuildContext context, Widget child) {
    performance.updateVariable(opacity);
    return new Opacity(opacity: opacity.value, child: child);
  }
}

class ColorTransition extends TransitionWithChild {
  ColorTransition({
    Key key,
    this.color,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedColorValue color;

  Widget buildWithChild(BuildContext context, Widget child) {
    performance.updateVariable(color);
    return new DecoratedBox(
      decoration: new BoxDecoration(backgroundColor: color.value),
      child: child
    );
  }
}

class SquashTransition extends TransitionWithChild {
  SquashTransition({
    Key key,
    this.width,
    this.height,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedValue<double> width;
  final AnimatedValue<double> height;

  Widget buildWithChild(BuildContext context, Widget child) {
    if (width != null)
      performance.updateVariable(width);
    if (height != null)
      performance.updateVariable(height);
    return new SizedBox(width: width?.value, height: height?.value, child: child);
  }
}

class AlignTransition extends TransitionWithChild {
  AlignTransition({
    Key key,
    this.alignment,
    this.widthFactor,
    this.heightFactor,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  final AnimatedValue<FractionalOffset> alignment;
  final AnimatedValue<double> widthFactor;
  final AnimatedValue<double> heightFactor;

  Widget buildWithChild(BuildContext context, Widget child) {
    if (alignment != null)
      performance.updateVariable(alignment);
    if (widthFactor != null)
      performance.updateVariable(widthFactor);
    if (heightFactor != null)
      performance.updateVariable(heightFactor);
    return new Align(
      alignment: alignment?.value,
      widthFactor: widthFactor?.value,
      heightFactor: heightFactor?.value,
      child: child);
  }
}

/// An animated variable containing a RelativeRectangle
///
/// This class specializes the interpolation of AnimatedValue<RelativeRect> to
/// be appropriate for rectangles that are described in terms of offsets from
/// other rectangles.
class AnimatedRelativeRectValue extends AnimatedValue<RelativeRect> {
  AnimatedRelativeRectValue(RelativeRect begin, { RelativeRect end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t);
}

/// Animated version of [Positioned].
/// Only works if it's the child of a [Stack].
class PositionedTransition extends TransitionWithChild {
  PositionedTransition({
    Key key,
    this.rect,
    PerformanceView performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child) {
    assert(rect != null);
  }

  final AnimatedRelativeRectValue rect;

  Widget buildWithChild(BuildContext context, Widget child) {
    performance.updateVariable(rect);
    return new Positioned(
      top: rect.value.top,
      right: rect.value.right,
      bottom: rect.value.bottom,
      left: rect.value.left,
      child: child
    );
  }
}


typedef Widget BuilderFunction(BuildContext context);

class BuilderTransition extends TransitionComponent {
  BuilderTransition({
    Key key,
    this.variables,
    this.builder,
    PerformanceView performance
  }) : super(key: key,
             performance: performance);

  final List<AnimatedValue> variables;
  final BuilderFunction builder;

  Widget build(BuildContext context) {
    for (int i = 0; i < variables.length; ++i)
      performance.updateVariable(variables[i]);
    return builder(context);
  }
}
