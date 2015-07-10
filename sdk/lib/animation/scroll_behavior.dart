// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:newton/newton.dart';

const double _kSecondsPerMillisecond = 1000.0;

abstract class ScrollBehavior {
  Simulation release(double position, double velocity) => null;

  // Returns the new scroll offset.
  double applyCurve(double scrollOffset, double scrollDelta);
}

class BoundedBehavior extends ScrollBehavior {
  BoundedBehavior({ double contentsSize: 0.0, double containerSize: 0.0 })
    : _contentsSize = contentsSize,
      _containerSize = containerSize;

  double _contentsSize;
  double get contentsSize => _contentsSize;
  void set contentsSize (double value) {
    if (_contentsSize != value) {
      _contentsSize = value;
      // TODO(ianh) now what? what if we have a simulation ongoing?
    }
  }

  double _containerSize;
  double get containerSize => _containerSize;
  void set containerSize (double value) {
    if (_containerSize != value) {
      _containerSize = value;
      // TODO(ianh) now what? what if we have a simulation ongoing?
    }
  }

  final double minScrollOffset = 0.0;
  double get maxScrollOffset => math.max(0.0, _contentsSize - _containerSize);

  double applyCurve(double scrollOffset, double scrollDelta) {
    return (scrollOffset + scrollDelta).clamp(0.0, maxScrollOffset);
  }
}

Simulation createDefaultScrollSimulation(double position, double velocity, double minScrollOffset, double maxScrollOffset) {
  double velocityPerSecond = velocity * _kSecondsPerMillisecond;
  SpringDescription spring = new SpringDescription.withDampingRatio(
      mass: 1.0, springConstant: 85.0, ratio: 1.1);
  double drag = 0.4;
  return new ScrollSimulation(position, velocityPerSecond, minScrollOffset, maxScrollOffset, spring, drag);
}

class FlingBehavior extends BoundedBehavior {
  FlingBehavior({ double contentsSize: 0.0, double containerSize: 0.0 })
    : super(contentsSize: contentsSize, containerSize: containerSize);

  Simulation release(double position, double velocity) {
    return createDefaultScrollSimulation(position, 0.0, minScrollOffset, maxScrollOffset);
  }
}

class OverscrollBehavior extends BoundedBehavior {
  OverscrollBehavior({ double contentsSize: 0.0, double containerSize: 0.0 })
    : super(contentsSize: contentsSize, containerSize: containerSize);

  Simulation release(double position, double velocity) {
    return createDefaultScrollSimulation(position, velocity, minScrollOffset, maxScrollOffset);
  }

  double applyCurve(double scrollOffset, double scrollDelta) {
    double newScrollOffset = scrollOffset + scrollDelta;
    // If we're overscrolling, we want move the scroll offset 2x
    // slower than we would otherwise. Therefore, we "rewind" the
    // newScrollOffset by half the amount that we moved it above.
    // Notice that we clap the "old" value to 0.0 so that we only
    // reduce the portion of scrollDelta that's applied beyond 0.0. We
    // do similar things for overscroll in the other direction.
    if (newScrollOffset < 0.0) {
      newScrollOffset -= (newScrollOffset - math.min(0.0, scrollOffset)) / 2.0;
    } else if (newScrollOffset > maxScrollOffset) {
      newScrollOffset -= (newScrollOffset - math.max(maxScrollOffset, scrollOffset)) / 2.0;
    }
    return newScrollOffset;
  }
}
