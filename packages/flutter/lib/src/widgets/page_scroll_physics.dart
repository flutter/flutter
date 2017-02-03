// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';

import 'scroll_absolute.dart';

class PageScrollPhysics extends ScrollPhysicsProxy {
  const PageScrollPhysics({
    ScrollPhysics parent,
    this.springDescription,
  }) : super(parent);

  final SpringDescription springDescription;

  @override
  PageScrollPhysics applyTo(ScrollPhysics parent) {
    return new PageScrollPhysics(
      parent: parent,
      springDescription: springDescription,
    );
  }

  double _roundToPage(AbsoluteScrollPosition position, double pixels, double pageSize) {
    final int index = (pixels + pageSize / 2.0) ~/ pageSize;
    return (pageSize * index).clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  double _getTargetPixels(AbsoluteScrollPosition position, double velocity) {
    final double pageSize = position.viewportDimension;
    if (velocity < -position.scrollTolerances.velocity)
      return _roundToPage(position, position.pixels - pageSize / 2.0, pageSize);
    if (velocity > position.scrollTolerances.velocity)
      return _roundToPage(position, position.pixels + pageSize / 2.0, pageSize);
    return _roundToPage(position, position.pixels, pageSize);
  }

  @override
  Simulation createBallisticSimulation(AbsoluteScrollPosition position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);
    final double target = _getTargetPixels(position, velocity);
    return new ScrollSpringSimulation(scrollSpring, position.pixels, target, velocity);
  }
}
