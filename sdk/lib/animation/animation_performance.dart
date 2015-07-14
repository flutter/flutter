// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/timeline.dart';
import 'package:sky/animation/curves.dart';

abstract class AnimatedVariable {
  void setFraction(double t);
  String toString();
}

class Interval {
  final double start;
  final double end;

  double adjustTime(double t) {
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  Interval(this.start, this.end) {
    assert(start >= 0.0);
    assert(start <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
  }
}

class AnimatedType<T extends dynamic> extends AnimatedVariable {
  AnimatedType(this.begin, { this.end, this.interval, this.curve: linear }) {
    value = begin;
  }

  T value;
  T begin;
  T end;
  Interval interval;
  Curve curve;

  void setFraction(double t) {
    if (end != null) {
      double adjustedTime = interval == null ? t : interval.adjustTime(t);
      if (adjustedTime == 1.0) {
        value = end;
      } else {
        // TODO(mpcomplete): Reverse the timeline and curve.
        value = begin + (end - begin) * curve.transform(adjustedTime);
      }
    }
  }

  String toString() => 'AnimatedType(begin=$begin, end=$end, value=$value)';
}

class AnimatedList extends AnimatedVariable {
  List<AnimatedVariable> variables;
  AnimatedList(this.variables);
  void setFraction(double t) {
    for (AnimatedVariable variable in variables)
      variable.setFraction(t);
  }
  String toString() => 'AnimatedList([$variables])';
}

// This class manages a "performance" - a collection of values that change
// based on a timeline. For example, a performance may handle an animation
// of a menu opening by sliding and fading in (changing Y value and opacity)
// over .5 seconds. The performance can move forwards (present) or backwards
// (dismiss). A consumer may also take direct control of the timeline by
// manipulating |progress|, or |fling| the timeline causing a physics-based
// simulation to take over the progression.
class AnimationPerformance {
  AnimationPerformance() {
    _timeline = new Timeline(_tick);
  }

  // TODO(mpcomplete): make this a list, or composable somehow.
  AnimatedVariable variable;
  // TODO(mpcomplete): duration should be on a director.
  Duration duration;

  // Advances from 0 to 1. On each tick, we'll update our variable's values.
  Timeline _timeline;
  Timeline get timeline => _timeline;

  double get progress => timeline.value;
  void set progress(double t) {
    stop();
    timeline.value = t.clamp(0.0, 1.0);
  }

  bool get isDismissed => progress == 0.0;
  bool get isCompleted => progress == 1.0;
  bool get isAnimating => timeline.isAnimating;

  void play() {
    _animateTo(1.0);
  }
  void reverse() {
    _animateTo(0.0);
  }

  void stop() {
    timeline.stop();
  }

  // Resume animating in a direction, with the given velocity.
  // TODO(mpcomplete): this should be a force with friction so it slows over
  // time.
  void fling({double velocity: 1.0}) {
    double target = velocity.sign < 0.0 ? 0.0 : 1.0;
    double distance = (target - timeline.value).abs();
    double duration = distance / velocity.abs();

    if (distance > 0.0)
      timeline.animateTo(target, duration: duration);
  }

  final List<Function> _listeners = new List<Function>();

  void addListener(Function listener) {
    _listeners.add(listener);
  }

  void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    List<Function> localListeners = new List<Function>.from(_listeners);
    for (Function listener in localListeners)
      listener();
  }

  void _animateTo(double target) {
    double remainingDistance = (target - timeline.value).abs();
    timeline.stop();
    if (remainingDistance != 0.0)
      timeline.animateTo(target, duration: remainingDistance * duration.inMilliseconds);
  }

  void _tick(double t) {
    variable.setFraction(t);
    _notifyListeners();
  }
}
