// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'curves.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

class FrameGenerator {
  Function onDone;
  StreamController _controller;

  Stream<double> get onTick => _controller.stream;

  int _animationId = 0;
  bool _cancelled = false;

  FrameGenerator({this.onDone}) {
    _controller = new StreamController(
      sync: true,
      onListen: _scheduleTick,
      onCancel: cancel);
  }

  void cancel() {
    if (_cancelled) {
      return;
    }
    if (_animationId != 0) {
      sky.window.cancelAnimationFrame(_animationId);
    }
    _animationId = 0;
    _cancelled = true;
    if (onDone != null) {
      onDone();
    }
  }

  void _scheduleTick() {
    assert(_animationId == 0);
    _animationId = sky.window.requestAnimationFrame(_tick);
  }

  void _tick(double timeStamp) {
    _animationId = 0;
    _controller.add(timeStamp);
    if (!_cancelled) {
      _scheduleTick();
    }
  }
}

class AnimationGenerator extends FrameGenerator {
  Stream<double> get onTick => _stream;
  final double initialDelay;
  final double duration;
  final double begin;
  final double end;
  final Curve curve;
  Stream<double> _stream;
  bool _done = false;

  AnimationGenerator({
    this.initialDelay: 0.0,
    this.duration,
    this.begin: 0.0,
    this.end: 1.0,
    this.curve: linear,
    Function onDone
  }):super(onDone: onDone) {
    assert(duration != null && duration > 0.0);
    double startTime = 0.0;
    _stream = super.onTick.map((timeStamp) {
      if (startTime == 0.0)
        startTime = timeStamp;

      double t = (timeStamp - (startTime + initialDelay)) / duration;
      return math.max(0.0, math.min(t, 1.0));
    })
    .takeWhile(_checkForCompletion) //
    .where((t) => t >= 0.0)
    .map(_transform);
  }

  double _transform(double t) {
    if (_done)
      return end;
    return begin + (end - begin) * curve.transform(t);
  }

  // This is required because Dart Streams don't have takeUntil (inclusive).
  bool _checkForCompletion(double t) {
    if (_done)
      return false;

    _done = t >= 1;
    return true;
  }
}

class Animation {
  Stream<double> get onValueChanged => _controller.stream;

  double get value => _value;

  void set value(double value) {
    stop();
   _setValue(value);
  }

  bool get isAnimating => _animation != null;

  StreamController _controller = new StreamController(sync: true);

  AnimationGenerator _animation;

  double _value;

  void _setValue(double value) {
    _value = value;
    _controller.add(_value);
  }

  void stop() {
    if (_animation != null) {
      _animation.cancel();
      _animation = null;
    }
  }

  void animateTo(double newValue, double duration,
      { Curve curve: linear, double initialDelay: 0.0 }) {
    stop();

    _animation = new AnimationGenerator(
        duration: duration,
        begin: _value,
        end: newValue,
        curve: curve,
        initialDelay: initialDelay);

    _animation.onTick.listen(_setValue, onDone: () {
      _animation = null;
    });
  }
}
