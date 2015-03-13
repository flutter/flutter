// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'generator.dart';
import 'mechanics.dart';

class Simulation {
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
