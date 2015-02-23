// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:math" as math;
import "dart:sky";

abstract class AnimationDelegate {
  void updateAnimation(double t);
}

class AnimationTimer {
  final AnimationDelegate _delegate;
  double _startTime = 0.0;
  double _duration = 0.0;
  int _animationId = 0;

  AnimationTimer(this._delegate);

  void start(double duration) {
    if (_animationId != 0)
      stop();
    _duration = duration;
    _scheduleTick();
  }

  void stop() {
    window.cancelAnimationFrame(_animationId);
    _startTime = 0.0;
    _duration = 0.0;
    _animationId = 0;
  }

  void _scheduleTick() {
    assert(_animationId == 0);
    _animationId = window.requestAnimationFrame(_tick);
  }

  void _tick(double timeStamp) {
    _animationId = 0;
    if (_startTime == 0.0)
      _startTime = timeStamp;
    double elapsedTime = timeStamp - _startTime;
    double t = math.max(0.0, math.min(1.0, elapsedTime / _duration));
    if (t < 1.0)
      _scheduleTick();
    else
      stop();
    _delegate.updateAnimation(t);
  }
}
