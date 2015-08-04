// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/animated_component.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/widgets/basic.dart';
import 'package:vector_math/vector_math.dart';

dynamic _maybe(AnimatedValue x) => x != null ? x.value : null;

abstract class TransitionBase extends AnimatedComponent {
  TransitionBase({
    Key key,
    this.child,
    this.direction,
    this.duration,
    this.performance,
    this.onDismissed,
    this.onCompleted
  }) : super(key: key);

  Widget child;
  Direction direction;
  Duration duration;
  AnimationPerformance performance;
  Function onDismissed;
  Function onCompleted;

  void initState() {
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

  void syncFields(TransitionBase source) {
    child = source.child;
    onCompleted = source.onCompleted;
    onDismissed = source.onDismissed;
    duration = source.duration;
    if (direction != source.direction) {
      direction = source.direction;
      _start();
    }
    super.syncFields(source);
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

  Widget build();
}

class SlideTransition extends TransitionBase {
  // TODO(mpcomplete): this constructor is mostly boilerplate, passing values
  // to super. Is there a simpler way?
  SlideTransition({
    Key key,
    this.position,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
             child: child);

  AnimatedValue<Point> position;

  void syncFields(SlideTransition updated) {
    position = updated.position;
    super.syncFields(updated);
  }

  Widget build() {
    performance.updateVariable(position);
    Matrix4 transform = new Matrix4.identity()
      ..translate(position.value.x, position.value.y);
    return new Transform(transform: transform, child: child);
  }
}

class FadeTransition extends TransitionBase {
  FadeTransition({
    Key key,
    this.opacity,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
             child: child);

  AnimatedValue<double> opacity;

  void syncFields(FadeTransition updated) {
    opacity = updated.opacity;
    super.syncFields(updated);
  }

  Widget build() {
    performance.updateVariable(opacity);
    return new Opacity(opacity: opacity.value, child: child);
  }
}

class ColorTransition extends TransitionBase {
  ColorTransition({
    Key key,
    this.color,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
             child: child);

  AnimatedColorValue color;

  void syncFields(ColorTransition updated) {
    color = updated.color;
    super.syncFields(updated);
  }

  Widget build() {
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
    this.width,
    this.height,
    Duration duration,
    AnimationPerformance performance,
    Direction direction,
    Function onDismissed,
    Function onCompleted,
    Widget child
  }) : super(key: key,
             duration: duration,
             performance: performance,
             direction: direction,
             onDismissed: onDismissed,
             onCompleted: onCompleted,
             child: child);

  AnimatedValue<double> width;
  AnimatedValue<double> height;

  void syncFields(SquashTransition updated) {
    width = updated.width;
    height = updated.height;
    super.syncFields(updated);
  }

  Widget build() {
    if (width != null)
      performance.updateVariable(width);
    if (height != null)
      performance.updateVariable(height);
    return new SizedBox(width: _maybe(width), height: _maybe(height), child: child);
  }
}
