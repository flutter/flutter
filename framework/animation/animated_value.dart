// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'curves.dart';
import 'dart:async';
import 'generators.dart';

class AnimatedValue {
  StreamController _controller = new StreamController(sync: true);
  AnimationGenerator _animation;
  Completer _completer;
  double _value;

  AnimatedValue(double initial) {
    _value = initial;
  }

  // A stream of change in value from |initial|. The stream does not
  // contain the initial value. Consumers should check the initial value via
  // the |value| accessor.
  Stream<double> get onValueChanged => _controller.stream;

  double get value => _value;

  void set value(double value) {
    stop();
   _setValue(value);
  }

  bool get isAnimating => _animation != null;

  void _setValue(double value) {
    _value = value;
    _controller.add(_value);
  }

  void _done() {
    _animation = null;
    if (_completer == null)
      return;
    Completer completer = _completer;
    _completer = null;
    completer.complete(_value);
  }

  void stop() {
    if (_animation != null) {
      _animation.cancel();
      _done();
    }
  }

  Future<double> animateTo(double newValue, double duration,
      { Curve curve: linear, double initialDelay: 0.0 }) {
    stop();

    _animation = new AnimationGenerator(
        duration: duration,
        begin: _value,
        end: newValue,
        curve: curve,
        initialDelay: initialDelay)
      ..onTick.listen(_setValue, onDone: _done);

    _completer = new Completer();
    return _completer.future;
  }

  double get remainingTime {
    if (_animation == null)
      return 0.0;
    return _animation.remainingTime;
  }

}
