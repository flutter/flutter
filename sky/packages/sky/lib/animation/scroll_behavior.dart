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
    : _contentsExtents = contentsSize,
      _containerExtents = containerSize;

  double _contentsExtents;
  double get contentsExtents => _contentsExtents;

  double _containerExtents;
  double get containerExtents => _containerExtents;

  /// Returns the new scrollOffset.
  double updateExtents({
    double contentsExtents,
    double containerExtents,
    double scrollOffset: 0.0
  }) {
    if (contentsExtents != null)
      _contentsExtents = contentsExtents;
    if (containerExtents != null)
      _containerExtents = containerExtents;
    return scrollOffset.clamp(minScrollOffset, maxScrollOffset);
  }

  final double minScrollOffset = 0.0;
  double get maxScrollOffset => math.max(0.0, _contentsExtents - _containerExtents);

  double applyCurve(double scrollOffset, double scrollDelta) {
    return (scrollOffset + scrollDelta).clamp(minScrollOffset, maxScrollOffset);
  }
}

Simulation createDefaultScrollSimulation(double position, double velocity, double minScrollOffset, double maxScrollOffset) {
  double velocityPerSecond = velocity * _kSecondsPerMillisecond;
  SpringDescription spring = new SpringDescription.withDampingRatio(
      mass: 1.0, springConstant: 170.0, ratio: 1.1);
  double drag = 0.025;
  return new ScrollSimulation(position, velocityPerSecond, minScrollOffset, maxScrollOffset, spring, drag);
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
    // Notice that we clamp the "old" value to 0.0 so that we only
    // reduce the portion of scrollDelta that's applied beyond 0.0. We
    // do similar things for overscroll in the other direction.
    if (newScrollOffset < minScrollOffset) {
      newScrollOffset -= (newScrollOffset - math.min(minScrollOffset, scrollOffset)) / 2.0;
    } else if (newScrollOffset > maxScrollOffset) {
      newScrollOffset -= (newScrollOffset - math.max(maxScrollOffset, scrollOffset)) / 2.0;
    }
    return newScrollOffset;
  }
}

class OverscrollWhenScrollableBehavior extends OverscrollBehavior {
  bool get isScrollable => contentsExtents > containerExtents;

  Simulation release(double position, double velocity) {
    if (isScrollable || position < minScrollOffset || position > maxScrollOffset)
      return super.release(position, velocity);
    return null;
  }

  double applyCurve(double scrollOffset, double scrollDelta) {
    if (isScrollable)
      return super.applyCurve(scrollOffset, scrollDelta);
    return minScrollOffset;
  }
}
