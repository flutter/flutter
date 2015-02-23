// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "curves.dart";
import "timer.dart";

class AnimationController extends AnimationDelegate {
  final AnimationDelegate _delegate;
  AnimationTimer _timer;
  double _begin = 0.0;
  double _end = 0.0;
  Curve _curve;
  bool _isAnimating = false;

  AnimationController(this._delegate) {
    _timer = new AnimationTimer(this);
  }

  bool get isAnimating => _isAnimating;

  void start({double begin: 0.0, double end: 0.0, Curve curve: linear,
              double duration: 0.0}) {
    _begin = begin;
    _end = end;
    _curve = curve;
    _isAnimating = true;
    _timer.start(duration);
  }

  void stop() {
    _isAnimating = false;
    _timer.stop();
  }

  double _positionForTime(double t) {
    // Explicitly finish animations at |_end| in case the curve isn't an
    // exact numerical transform.
    if (t == 1)
      return _end;
    double curvedTime = _curve.transform(t);
    return _begin + (_end - _begin) * curvedTime;
  }

  void updateAnimation(double t) {
    _delegate.updateAnimation(_positionForTime(t));
  }
}
