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
  final double duration;
  final double begin;
  final double end;
  final Curve curve;
  Stream<double> _stream;
  bool _done = false;

  AnimationGenerator(this.duration, {
    this.begin: 0.0,
    this.end: 1.0,
    this.curve: linear,
    Function onDone
  }):super(onDone: onDone) {
    assert(duration > 0);
    double startTime = 0.0;
    _stream = super.onTick.map((timeStamp) {
      if (startTime == 0.0)
        startTime = timeStamp;
      return math.min((timeStamp - startTime) / duration, 1.0);
    })
    .takeWhile(_checkForCompletion)
    .map(_transform);
  }

  double _transform(double t) {
    if (_done)
      return end;
    return begin + (end - begin) * curve.transform(t);
  }

  bool _checkForCompletion(double t) {
    if (_done)
      return false;
    _done = t >= 1;
    return true;
  }
}
