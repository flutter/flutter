// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/base/scheduler.dart' as scheduler;

class Ticker {
  Ticker(Function onTick) : _onTick = onTick;

  final Function _onTick;

  Completer _completer;
  int _animationId;

  Future start() {
    assert(!isTicking);
    _completer = new Completer();
    _scheduleTick();
    return _completer.future;
  }

  void stop() {
    if (!isTicking)
      return;

    if (_animationId != null) {
      scheduler.cancelAnimationFrame(_animationId);
      _animationId = null;
    }

    Completer localCompleter = _completer;
    _completer = null;

    // We take the _completer into a local variable so that !isTicking when we
    // actually complete the future.
    assert(!isTicking);
    localCompleter.complete();
  }

  bool get isTicking => _completer != null;

  void _tick(double timeStamp) {
    assert(isTicking);
    assert(_animationId != null);
    _animationId = null;

    _onTick(timeStamp);

    if (isTicking)
      _scheduleTick();
  }

  void _scheduleTick() {
    assert(isTicking);
    assert(_animationId == null);
    _animationId = scheduler.requestAnimationFrame(_tick);
  }
}

class Timeline {

  Timeline(Function onTick) : _onTick = onTick {
    _ticker = new Ticker(_tick);
  }

  final Function _onTick;
  Ticker _ticker;

  double _value = 0.0;
  double get value => _value;
  void set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    assert(!_ticker.isTicking);
    _value = newValue;
    _onTick(_value);
  }

  double _duration;
  double _begin;
  double _end;

  double _startTime;

  Future start({
    double duration,
    double begin: 0.0,
    double end: 1.0
  }) {
    assert(duration != null && duration > 0.0);
    assert(begin != null && begin >= 0.0 && begin <= 1.0);
    assert(end != null && end >= 0.0 && end <= 1.0);

    assert(!_ticker.isTicking);

    _duration = duration;
    _begin = begin;
    _end = end;

    _startTime = null;
    _value = begin;

    return _ticker.start();
  }

  Future animateTo(double target, { double duration }) {
    return start(duration: duration, begin: _value, end: target);
  }

  void stop() {
    _duration = null;
    _begin = null;
    _end = null;
    _startTime = null;
    _ticker.stop();
  }

  bool get isAnimating => _ticker.isTicking;

  void _tick(double timeStamp) {
    if (_startTime == null)
      _startTime = timeStamp;

    final double t = ((timeStamp - _startTime) / _duration).clamp(0.0, 1.0);
    final bool isLastTick = t >= 1.0;

    _value = isLastTick ? _end : _begin + (_end - _begin) * t;
    _onTick(_value);

    if (isLastTick)
      stop();
  }
}
