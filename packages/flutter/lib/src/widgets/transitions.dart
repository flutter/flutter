// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/global_key_watcher.dart';
import 'package:vector_math/vector_math.dart';

export 'package:sky/animation.dart' show Direction;

class TransitionProxy extends GlobalKeyWatcher {

  TransitionProxy({
    Key key,
    GlobalKey transitionKey,
    this.child
  }) : super(key: key, watchedKey: transitionKey);

  Widget child;

  void syncConstructorArguments(TransitionProxy source) {
    child = source.child;
    super.syncConstructorArguments(source);
  }

  bool debugValidateWatchedWidget(Widget candidate) {
    return candidate is TransitionBaseWithChild;
  }

  TransitionBaseWithChild get transition => this.watchedWidget;

  void startWatching() {
    transition.performance.addListener(_performanceChanged);
  }

  void stopWatching() {
    transition.performance.removeListener(_performanceChanged);
  }

  void _performanceChanged() {
    setState(() {
      // The performance changed, so we probably need to ask the transition
      // we're watching for a rebuild.
    });
  }

  Widget build() {
    if (transition != null)
      return transition.buildWithChild(child);
    return child;
  }

}

abstract class TransitionBase extends StatefulComponent {

  TransitionBase({
    Key key,
    this.performance
  }) : super(key: key) {
    assert(performance != null);
  }

  WatchableAnimationPerformance performance;

  void syncConstructorArguments(TransitionBase source) {
    if (performance != source.performance) {
      if (mounted)
        performance.removeListener(_performanceChanged);
      performance = source.performance;
      if (mounted)
        performance.addListener(_performanceChanged);
    }
  }

  void _performanceChanged() {
    setState(() {
      // The performance's state is our build state, and it changed already.
    });
  }

  void didMount() {
    performance.addListener(_performanceChanged);
    super.didMount();
  }

  void didUnmount() {
    performance.removeListener(_performanceChanged);
    super.didUnmount();
  }

}

abstract class TransitionBaseWithChild extends TransitionBase {

  TransitionBaseWithChild({
    Key key,
    this.child,
    WatchableAnimationPerformance performance
  }) : super(key: key, performance: performance);

  Widget child;

  void syncConstructorArguments(TransitionBaseWithChild source) {
    child = source.child;
    super.syncConstructorArguments(source);
  }

  Widget build() {
    return buildWithChild(child);
  }

  Widget buildWithChild(Widget child);

}

class SlideTransition extends TransitionBaseWithChild {
  SlideTransition({
    Key key,
    this.position,
    WatchableAnimationPerformance performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  AnimatedValue<Point> position;

  void syncConstructorArguments(SlideTransition source) {
    position = source.position;
    super.syncConstructorArguments(source);
  }

  Widget buildWithChild(Widget child) {
    performance.updateVariable(position);
    Matrix4 transform = new Matrix4.identity()
      ..translate(position.value.x, position.value.y);
    return new Transform(transform: transform, child: child);
  }
}

class FadeTransition extends TransitionBaseWithChild {
  FadeTransition({
    Key key,
    this.opacity,
    WatchableAnimationPerformance performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  AnimatedValue<double> opacity;

  void syncConstructorArguments(FadeTransition source) {
    opacity = source.opacity;
    super.syncConstructorArguments(source);
  }

  Widget buildWithChild(Widget child) {
    performance.updateVariable(opacity);
    return new Opacity(opacity: opacity.value, child: child);
  }
}

class ColorTransition extends TransitionBaseWithChild {
  ColorTransition({
    Key key,
    this.color,
    WatchableAnimationPerformance performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  AnimatedColorValue color;

  void syncConstructorArguments(ColorTransition source) {
    color = source.color;
    super.syncConstructorArguments(source);
  }

  Widget buildWithChild(Widget child) {
    performance.updateVariable(color);
    return new DecoratedBox(
      decoration: new BoxDecoration(backgroundColor: color.value),
      child: child
    );
  }
}

class SquashTransition extends TransitionBaseWithChild {
  SquashTransition({
    Key key,
    this.width,
    this.height,
    WatchableAnimationPerformance performance,
    Widget child
  }) : super(key: key,
             performance: performance,
             child: child);

  AnimatedValue<double> width;
  AnimatedValue<double> height;

  void syncConstructorArguments(SquashTransition source) {
    width = source.width;
    height = source.height;
    super.syncConstructorArguments(source);
  }

  Widget buildWithChild(Widget child) {
    if (width != null)
      performance.updateVariable(width);
    if (height != null)
      performance.updateVariable(height);
    return new SizedBox(width: width?.value, height: height?.value, child: child);
  }
}

typedef Widget BuilderFunction();

class BuilderTransition extends TransitionBase {
  BuilderTransition({
    Key key,
    this.variables,
    this.builder,
    WatchableAnimationPerformance performance
  }) : super(key: key,
             performance: performance);

  List<AnimatedValue> variables;
  BuilderFunction builder;

  void syncConstructorArguments(BuilderTransition source) {
    variables = source.variables;
    builder = source.builder;
    super.syncConstructorArguments(source);
  }

  Widget build() {
    for (int i = 0; i < variables.length; ++i)
      performance.updateVariable(variables[i]);
    return builder();
  }
}
