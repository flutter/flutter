// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/animated_component.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/widgets/basic.dart';
import 'package:vector_math/vector_math.dart';

export 'package:sky/animation/direction.dart' show Direction;

dynamic _maybe(AnimatedValue x) => x != null ? x.value : null;

// A helper class to anchor widgets to one another. Pass an instance of this to
// a Transition, then use the build() method to create a child with the same
// transition applied.
class Anchor {
  Anchor();

  TransitionBase transition;

  Widget build(Widget child) {
    return new _AnchorTransition(anchoredTo: this, child: child);
  }
}

// Used with the Anchor class to apply a transition to multiple children.
class _AnchorTransition extends AnimatedComponent {
  _AnchorTransition({
    Key key,
    this.anchoredTo,
    this.child
  }) : super(key: key);

  Anchor anchoredTo;
  Widget child;
  TransitionBase get transition => anchoredTo.transition;

  void initState() {
    if (transition != null)
      watch(transition.performance);
  }

  void syncConstructorArguments(_AnchorTransition source) {
    if (transition != null && isWatching(transition.performance))
      unwatch(transition.performance);
    anchoredTo = source.anchoredTo;
    if (transition != null)
      watch(transition.performance);
    child = source.child;
    super.syncConstructorArguments(source);
  }

  Widget build() {
    if (transition == null)
      return child;
    return transition.buildWithChild(child);
  }
}

abstract class TransitionBase extends AnimatedComponent {
  TransitionBase({
    Key key,
    this.anchor,
    this.child,
    this.direction,
    this.duration,
    this.performance,
    this.onDismissed,
    this.onCompleted
  }) : super(key: key);

  Widget child;
  Anchor anchor;
  Direction direction;
  Duration duration;
  AnimationPerformance performance;
  Function onDismissed;
  Function onCompleted;

  void initState() {
    if (anchor != null)
      anchor.transition = this;

    if (performance == null) {
      assert(duration != null);
      performance = new AnimationPerformance(duration: duration);
    }
    if (direction == Direction.reverse)
      performance.progress = 1.0;
    performance.addStatusListener(_checkStatusChanged);

    watch(performance);
    _start();
  }

  void syncConstructorArguments(TransitionBase source) {
    child = source.child;
    onCompleted = source.onCompleted;
    onDismissed = source.onDismissed;
    duration = source.duration;
    if (direction != source.direction) {
      direction = source.direction;
      _start();
    }
    super.syncConstructorArguments(source);
  }

  void _start() {
    performance.play(direction);
  }

  void _checkStatusChanged(AnimationStatus status) {
    if (performance.isDismissed) {
      if (onDismissed != null)
        onDismissed();
    } else if (performance.isCompleted) {
      if (onCompleted != null)
        onCompleted();
    }
  }

  Widget build() {
    return buildWithChild(child);
  }

  Widget buildWithChild(Widget child);
}

class SlideTransition extends TransitionBase {
  // TODO(mpcomplete): this constructor is mostly boilerplate, passing values
  // to super. Is there a simpler way?
  SlideTransition({
    Key key,
    Anchor anchor,
    this.position,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             anchor: anchor,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
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

class FadeTransition extends TransitionBase {
  FadeTransition({
    Key key,
    Anchor anchor,
    this.opacity,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             anchor: anchor,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
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

class ColorTransition extends TransitionBase {
  ColorTransition({
    Key key,
    Anchor anchor,
    this.color,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             anchor: anchor,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
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

class SquashTransition extends TransitionBase {
  SquashTransition({
    Key key,
    Anchor anchor,
    this.width,
    this.height,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             anchor: anchor,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
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
    return new SizedBox(width: _maybe(width), height: _maybe(height), child: child);
  }
}

typedef Widget BuilderFunction();

class BuilderTransition extends TransitionBase {
  BuilderTransition({
    Key key,
    Anchor anchor,
    this.variables,
    this.builder,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             anchor: anchor,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
             child: child);

  List<AnimatedValue> variables;
  BuilderFunction builder;

  void syncConstructorArguments(BuilderTransition source) {
    variables = source.variables;
    builder = source.builder;
    super.syncConstructorArguments(source);
  }

  Widget buildWithChild(Widget child) {
    for (int i = 0; i < variables.length; ++i)
      performance.updateVariable(variables[i]);
    return builder();
  }
}
