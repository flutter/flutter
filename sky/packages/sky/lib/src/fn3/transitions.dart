// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:vector_math/vector_math.dart';

export 'package:sky/animation.dart' show Direction;

abstract class TransitionComponent extends StatefulComponent {
  TransitionComponent({
    Key key,
    this.performance
  }) : super(key: key) {
    assert(performance != null);
  }

  final WatchableAnimationPerformance performance;

  Widget build(BuildContext context);

  TransitionState createState() => new TransitionState();
}

class TransitionState extends State<TransitionComponent> {
  void initState(BuildContext context) {
    super.initState(context);
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
    WatchableAnimationPerformance performance
  }) : super(key: key, performance: performance);

  final Widget child;

  Widget build(BuildContext context) => buildWithChild(context, child);

  Widget buildWithChild(BuildContext context, Widget child);
}

class SlideTransition extends TransitionWithChild {
  SlideTransition({
    Key key,
    this.position,
    WatchableAnimationPerformance performance,
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
    WatchableAnimationPerformance performance,
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
    WatchableAnimationPerformance performance,
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
    WatchableAnimationPerformance performance,
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
    WatchableAnimationPerformance performance
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
