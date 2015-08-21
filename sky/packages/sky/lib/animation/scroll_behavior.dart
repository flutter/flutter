// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:newton/newton.dart';

const double _kSecondsPerMillisecond = 1000.0;
const double _kScrollDrag = 0.025;

abstract class ScrollBehavior {
  Simulation release(double position, double velocity) => null;

  // Returns the new scroll offset.
  double applyCurve(double scrollOffset, double scrollDelta);
}

abstract class ExtentScrollBehavior extends ScrollBehavior {
  ExtentScrollBehavior({ double contentExtent: 0.0, double containerExtent: 0.0 })
    : _contentExtent = contentExtent, _containerExtent = containerExtent;

  double _contentExtent;
  double get contentExtent => _contentExtent;

  double _containerExtent;
  double get containerExtent => _containerExtent;

  /// Returns the new scrollOffset.
  double updateExtents({
    double contentExtent,
    double containerExtent,
    double scrollOffset: 0.0
  }) {
    if (contentExtent != null)
      _contentExtent = contentExtent;
    if (containerExtent != null)
      _containerExtent = containerExtent;
    return scrollOffset.clamp(minScrollOffset, maxScrollOffset);
  }

  double get minScrollOffset;
  double get maxScrollOffset;
}

class BoundedBehavior extends ExtentScrollBehavior {
  BoundedBehavior({ double contentExtent: 0.0, double containerExtent: 0.0 })
    : super(contentExtent: contentExtent, containerExtent: containerExtent);

  double minScrollOffset = 0.0;
  double get maxScrollOffset => math.max(minScrollOffset, minScrollOffset + _contentExtent - _containerExtent);

  double applyCurve(double scrollOffset, double scrollDelta) {
    return (scrollOffset + scrollDelta).clamp(minScrollOffset, maxScrollOffset);
  }
}

class UnboundedBehavior extends ExtentScrollBehavior {
  UnboundedBehavior({ double contentExtent: 0.0, double containerExtent: 0.0 })
    : super(contentExtent: contentExtent, containerExtent: containerExtent);

  Simulation release(double position, double velocity) {
    double velocityPerSecond = velocity * 1000.0;
    return new BoundedFrictionSimulation(
      _kScrollDrag, position, velocityPerSecond, double.NEGATIVE_INFINITY, double.INFINITY
    );
  }

  double get minScrollOffset => double.NEGATIVE_INFINITY;
  double get maxScrollOffset => double.INFINITY;

  double applyCurve(double scrollOffset, double scrollDelta) {
    return scrollOffset + scrollDelta;
  }
}

Simulation createDefaultScrollSimulation(double position, double velocity, double minScrollOffset, double maxScrollOffset) {
  double velocityPerSecond = velocity * _kSecondsPerMillisecond;
  SpringDescription spring = new SpringDescription.withDampingRatio(
      mass: 1.0, springConstant: 170.0, ratio: 1.1);
  return new ScrollSimulation(position, velocityPerSecond, minScrollOffset, maxScrollOffset, spring, _kScrollDrag);
}

class OverscrollBehavior extends BoundedBehavior {
  OverscrollBehavior({ double contentExtent: 0.0, double containerExtent: 0.0 })
    : super(contentExtent: contentExtent, containerExtent: containerExtent);

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
  bool get isScrollable => contentExtent > containerExtent;

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
