// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'curves.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:sky' as sky;

abstract class Generator {
  Stream<double> get onTick;
  void cancel();
}

class FrameGenerator extends Generator {
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

class AnimationGenerator extends Generator {
  Stream<double> get onTick => _stream;
  final double initialDelay;
  final double duration;
  final double begin;
  final double end;
  final Curve curve;

  FrameGenerator _generator;
  Stream<double> _stream;
  bool _done = false;

  AnimationGenerator({
    this.initialDelay: 0.0,
    this.duration,
    this.begin: 0.0,
    this.end: 1.0,
    this.curve: linear,
    Function onDone
  }) {
    assert(duration != null && duration > 0.0);
    _generator = new FrameGenerator(onDone: onDone);

    double startTime = 0.0;
    _stream = _generator.onTick.map((timeStamp) {
      if (startTime == 0.0)
        startTime = timeStamp;

      double t = (timeStamp - (startTime + initialDelay)) / duration;
      return math.max(0.0, math.min(t, 1.0));
    })
    .takeWhile(_checkForCompletion)
    .where((t) => t >= 0.0)
    .map(_transform);
  }

  void cancel() {
    _generator.cancel();
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

class Simulation extends Generator {
  Stream<double> get onTick => _stream;
  final System system;

  FrameGenerator _generator;
  Stream<double> _stream;
  double _previousTime = 0.0;

  Simulation(this.system, {Function terminationCondition, Function onDone}) {
    _generator = new FrameGenerator(onDone: onDone);
    _stream = _generator.onTick.map(_update);

    if (terminationCondition != null) {
      bool done = false;
      _stream = _stream.takeWhile((_) {
        if (done)
          return false;
        done = terminationCondition();
        return true;
      });
    }
  }

  void cancel() {
    _generator.cancel();
  }

  double _update(double timeStamp) {
    double previousTime = _previousTime;
    _previousTime = timeStamp;
    if (previousTime == 0.0)
      return timeStamp;
    double deltaT = timeStamp - previousTime;
    system.update(deltaT);
    return timeStamp;
  }
}
