// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class SnappingScrollPhysics extends ClampingScrollPhysics {
  const SnappingScrollPhysics({
    ScrollPhysics parent,
    @required this.midScrollOffset,
  }) : assert(midScrollOffset != null),
       super(parent: parent);

  /// The offset that determines whether the scroll controller will scroll
  /// all the way to the start or to the end of the scroll boundaries.
  final double midScrollOffset;

  @override
  SnappingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SnappingScrollPhysics(
        parent: buildParent(ancestor), midScrollOffset: midScrollOffset);
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Simulation simulation = super.createBallisticSimulation(position, velocity);
    final double offset = position.pixels;
    if (simulation != null) {
      final double simulationEnd = simulation.x(double.infinity);
      if (simulationEnd >= midScrollOffset) {
        return simulation;
      } else if (velocity > 0.0) {
        return _toMidScrollOffsetSimulation(offset, velocity);
      } else if (velocity < 0.0) {
        return _toZeroScrollOffsetSimulation(offset, velocity);
      }
    } else {
      final double snapThreshold = midScrollOffset / 2.0;
      if (offset >= snapThreshold && offset < midScrollOffset) {
        return _toMidScrollOffsetSimulation(offset, velocity);
      } else if (offset > 0.0 && offset < snapThreshold) {
        return _toZeroScrollOffsetSimulation(offset, velocity);
      }
    }
    return simulation;
  }

  Simulation _toMidScrollOffsetSimulation(double offset, double dragVelocity) {
    final double velocity = math.max(dragVelocity, minFlingVelocity);
    return ScrollSpringSimulation(spring, offset, midScrollOffset, velocity,
        tolerance: tolerance);
  }

  Simulation _toZeroScrollOffsetSimulation(double offset, double dragVelocity) {
    final double velocity = math.max(dragVelocity, minFlingVelocity);
    return ScrollSpringSimulation(spring, offset, 0.0, velocity,
        tolerance: tolerance);
  }
}
