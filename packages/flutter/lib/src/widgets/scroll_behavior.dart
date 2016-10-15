// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:meta/meta.dart';

import 'scroll_simulation.dart';

export 'package:flutter/foundation.dart' show TargetPlatform;

Simulation _createSnapScrollSimulation(double startOffset, double endOffset, double startVelocity, double endVelocity) {
  return new FrictionSimulation.through(startOffset, endOffset, startVelocity, endVelocity);
}

// TODO(hansmuller): Simplify these classes. We're no longer using the ScrollBehavior<T, U>
// base class directly. Only LazyBlock uses BoundedBehavior's updateExtents minScrollOffset
// parameter; simpler to move that into ExtentScrollBehavior.  All of the classes should
// be called FooScrollBehavior. See https://github.com/flutter/flutter/issues/5281

/// An interface for controlling the behavior of scrollable widgets.
///
/// The type argument T is the type that describes the scroll offset.
/// The type argument U is the type that describes the scroll velocity.
abstract class ScrollBehavior<T, U> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  ///
  /// The [platform] must not be null.
  const ScrollBehavior({
    @required this.platform
  });

  /// The platform for which physics constants should be approximated.
  ///
  /// This is what makes flings go further on iOS than Android.
  ///
  /// Must not be null.
  final TargetPlatform platform;

  /// Returns a simulation that propels the scrollOffset.
  ///
  /// This function is called when a drag gesture ends.
  ///
  /// Returns `null` if the behavior is to do nothing.
  Simulation createScrollSimulation(T position, U velocity) => null;

  /// Returns an animation that ends at the snap offset.
  ///
  /// This function is called when a drag gesture ends and a
  /// [SnapOffsetCallback] is specified for the scrollable.
  ///
  /// Returns `null` if the behavior is to do nothing.
  Simulation createSnapScrollSimulation(T startOffset, T endOffset, U startVelocity, U endVelocity) => null;

  /// Returns the scroll offset to use when the user attempts to scroll
  /// from the given offset by the given delta.
  T applyCurve(T scrollOffset, T scrollDelta) => scrollOffset;

  /// Whether this scroll behavior currently permits scrolling.
  bool get isScrollable => true;

  @override
  String toString() {
    List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType(${description.join("; ")})';
  }

  /// Accumulates a list of strings describing the current node's fields, one
  /// field per string. Subclasses should override this to have their
  /// information included in [toString].
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    description.add(isScrollable ? 'scrollable' : 'not scrollable');
  }
}

/// A scroll behavior for a scrollable widget with linear extent (i.e.
/// that only scrolls along one axis).
abstract class ExtentScrollBehavior extends ScrollBehavior<double, double> {
  /// Creates a scroll behavior for a scrollable widget with linear extent.
  /// We start with an INFINITE contentExtent so that we don't accidentally
  /// clamp a scrollOffset until we receive an accurate value in updateExtents.
  ///
  /// The extents and the [platform] must not be null.
  ExtentScrollBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    @required TargetPlatform platform
  }) : _contentExtent = contentExtent,
       _containerExtent = containerExtent,
       super(platform: platform);

  /// The linear extent of the content inside the scrollable widget.
  double get contentExtent => _contentExtent;
  double _contentExtent;

  /// The linear extent of the exterior of the scrollable widget.
  double get containerExtent => _containerExtent;
  double _containerExtent;

  /// Updates either content or container extent (or both)
  ///
  /// Returns the new scroll offset of the widget after the change in extent.
  ///
  /// The [scrollOffset] parameter is the scroll offset of the widget before the
  /// change in extent.
  double updateExtents({
    double contentExtent,
    double containerExtent,
    double scrollOffset: 0.0
  }) {
    assert(minScrollOffset <= maxScrollOffset);
    if (contentExtent != null)
      _contentExtent = contentExtent;
    if (containerExtent != null)
      _containerExtent = containerExtent;
    return scrollOffset.clamp(minScrollOffset, maxScrollOffset);
  }

  /// The minimum value the scroll offset can obtain.
  double get minScrollOffset;

  /// The maximum value the scroll offset can obtain.
  double get maxScrollOffset;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('content: ${contentExtent.toStringAsFixed(1)}');
    description.add('container: ${containerExtent.toStringAsFixed(1)}');
    description.add('range: ${minScrollOffset?.toStringAsFixed(1)} .. ${maxScrollOffset?.toStringAsFixed(1)}');
  }
}

/// A scroll behavior that prevents the user from exceeding scroll bounds.
class BoundedBehavior extends ExtentScrollBehavior {
  /// Creates a scroll behavior that does not overscroll.
  BoundedBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    double minScrollOffset: 0.0,
    @required TargetPlatform platform
  }) : _minScrollOffset = minScrollOffset,
       super(
         contentExtent: contentExtent,
         containerExtent: containerExtent,
         platform: platform
       );

  double _minScrollOffset;

  @override
  double updateExtents({
    double contentExtent,
    double containerExtent,
    double minScrollOffset,
    double scrollOffset: 0.0
  }) {
    if (minScrollOffset != null) {
      _minScrollOffset = minScrollOffset;
      assert(minScrollOffset <= maxScrollOffset);
    }
    return super.updateExtents(
      contentExtent: contentExtent,
      containerExtent: containerExtent,
      scrollOffset: scrollOffset
    );
  }

  @override
  double get minScrollOffset => _minScrollOffset;

  @override
  double get maxScrollOffset => math.max(minScrollOffset, minScrollOffset + _contentExtent - _containerExtent);

  @override
  double applyCurve(double scrollOffset, double scrollDelta) {
    return (scrollOffset + scrollDelta).clamp(minScrollOffset, maxScrollOffset);
  }
}

/// A scroll behavior that does not prevent the user from exceeding scroll bounds.
class UnboundedBehavior extends ExtentScrollBehavior {
  /// Creates a scroll behavior with no scrolling limits.
  UnboundedBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    @required TargetPlatform platform
  }) : super(
    contentExtent: contentExtent,
    containerExtent: containerExtent,
    platform: platform
  );

  @override
  Simulation createScrollSimulation(double position, double velocity) {
    return new ScrollSimulation(
      position: position,
      velocity: velocity,
      leadingExtent: double.NEGATIVE_INFINITY,
      trailingExtent: double.INFINITY,
      platform: platform,
    );
  }

  @override
  Simulation createSnapScrollSimulation(double startOffset, double endOffset, double startVelocity, double endVelocity) {
    return _createSnapScrollSimulation(startOffset, endOffset, startVelocity, endVelocity);
  }

  @override
  double get minScrollOffset => double.NEGATIVE_INFINITY;

  @override
  double get maxScrollOffset => double.INFINITY;

  @override
  double applyCurve(double scrollOffset, double scrollDelta) {
    return scrollOffset + scrollDelta;
  }
}

/// A scroll behavior that lets the user scroll beyond the scroll bounds with some resistance.
class OverscrollBehavior extends BoundedBehavior {
  /// Creates a scroll behavior that resists, but does not prevent, scrolling beyond its limits.
  OverscrollBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    double minScrollOffset: 0.0,
    @required TargetPlatform platform
  }) : super(
    contentExtent: contentExtent,
    containerExtent: containerExtent,
    minScrollOffset: minScrollOffset,
    platform: platform
  );

  @override
  Simulation createScrollSimulation(double position, double velocity) {
    return new ScrollSimulation(
      position: position,
      velocity: velocity,
      leadingExtent: minScrollOffset,
      trailingExtent: maxScrollOffset,
      platform: platform,
    );
  }

  @override
  Simulation createSnapScrollSimulation(double startOffset, double endOffset, double startVelocity, double endVelocity) {
    return _createSnapScrollSimulation(startOffset, endOffset, startVelocity, endVelocity);
  }

  @override
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

/// A scroll behavior that lets the user scroll beyond the scroll bounds only when the bounds are disjoint.
class OverscrollWhenScrollableBehavior extends OverscrollBehavior {
  /// Creates a scroll behavior that allows overscrolling only when some amount of scrolling is already possible.
  OverscrollWhenScrollableBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    double minScrollOffset: 0.0,
    @required TargetPlatform platform
  }) : super(
    contentExtent: contentExtent,
    containerExtent: containerExtent,
    minScrollOffset: minScrollOffset,
    platform: platform
  );

  @override
  bool get isScrollable => contentExtent > containerExtent;

  @override
  Simulation createScrollSimulation(double position, double velocity) {
    if ((isScrollable && velocity.abs() > 0) || position < minScrollOffset || position > maxScrollOffset) {
      // If the triggering gesture starts at or beyond the contentExtent's limits
      // then the simulation only serves to settle the scrollOffset back to its
      // minimum or maximum value.
      if (position < minScrollOffset || position > maxScrollOffset)
        velocity = 0.0;
      return super.createScrollSimulation(position, velocity);
    }
    return null;
  }

  @override
  double applyCurve(double scrollOffset, double scrollDelta) {
    if (isScrollable)
      return super.applyCurve(scrollOffset, scrollDelta);
    return minScrollOffset;
  }
}
