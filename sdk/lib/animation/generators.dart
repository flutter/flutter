// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/scheduler.dart' as scheduler;
import 'mechanics.dart';

abstract class Generator {
  Stream<double> get onTick; // TODO(ianh): rename this to tickStream
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
      scheduler.cancelAnimationFrame(_animationId);
    }
    _animationId = 0;
    _cancelled = true;
    if (onDone != null) {
      onDone();
    }
  }

  void _scheduleTick() {
    assert(_animationId == 0);
    _animationId = scheduler.requestAnimationFrame(_tick);
  }

  void _tick(double timeStamp) {
    _animationId = 0;
    _controller.add(timeStamp);
    if (!_cancelled) {
      _scheduleTick();
    }
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
