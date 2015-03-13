// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'curves.dart';
import 'dart:async';
import 'generators.dart';

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
