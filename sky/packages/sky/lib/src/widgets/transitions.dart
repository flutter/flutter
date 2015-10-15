// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/animation.dart' show AnimationDirection;

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
