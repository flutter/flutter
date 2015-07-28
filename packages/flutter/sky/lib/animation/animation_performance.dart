// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/forces.dart';
import 'package:sky/animation/timeline.dart';

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

  Future play() => _animateTo(1.0);
  Future reverse() => _animateTo(0.0);

  void stop() {
    timeline.stop();
  }

  // Flings the timeline with an optional force (defaults to a critically damped
  // spring) and initial velocity. Negative velocity causes the timeline to go
  // in reverse.
  Future fling({double velocity: 1.0, Force force}) {
    if (force == null)
      force = kDefaultSpringForce;
    return timeline.fling(force.release(progress, velocity));
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

  Future _animateTo(double target) {
    double remainingDistance = (target - timeline.value).abs();
    timeline.stop();
    if (remainingDistance == 0.0)
      return new Future.value();
    return timeline.animateTo(target, duration: duration * remainingDistance);
  }

  void _tick(double t) {
    variable.setProgress(t);
    _notifyListeners();
  }
}
