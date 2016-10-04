// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'basic.dart';
import 'notification_listener.dart';
import 'scrollable.dart' show Scrollable2, Scrollable2State;

/// A description of a [Scrollable2]'s contents, useful for modelling the state
/// of the viewport, for example by a [Scrollbar].
///
/// The units used by the [extentBefore], [extentInside], and [extentAfter] are
/// not defined, but must be consistent. For example, they could be in pixels,
/// or in percentages, or in units of the [extentInside] (in the latter case,
/// [extentInside] would always be 1.0).
class ScrollableMetrics {
  /// Create a description of the metrics of a [Scrollable2]'s contents.
  ///
  /// The three arguments must be present, non-null, finite, and non-negative.
  const ScrollableMetrics({
    @required this.extentBefore,
    @required this.extentInside,
    @required this.extentAfter,
  });

  /// The quantity of content conceptually "above" the currently visible content
  /// of the viewport in the scrollable. This is the content above the content
  /// described by [extentInside].
  ///
  /// The units are in general arbitrary, and decided by the [ScrollPosition]
  /// that generated the [ScrollableMetrics]. They will be the same units as for
  /// [extentInside] and [extentAfter].
  final double extentBefore;

  /// The quantity of visible content. If [extentBefore] and [extentAfter] are
  /// non-zero, then this is typically the height of the viewport. It could be
  /// less if there is less content visible than the size of the viewport.
  ///
  /// The units are in general arbitrary, and decided by the [ScrollPosition]
  /// that generated the [ScrollableMetrics]. They will be the same units as for
  /// [extentBefore] and [extentAfter].
  final double extentInside;

  /// The quantity of content conceptually "below" the currently visible content
  /// of the viewport in the scrollable. This is the content below the content
  /// described by [extentInside].
  ///
  /// The units are in general arbitrary, and decided by the [ScrollPosition]
  /// that generated the [ScrollableMetrics]. They will be the same units as for
  /// [extentBefore] and [extentInside].
  final double extentAfter;

  @override
  String toString() {
    return '$runtimeType(${extentBefore.toStringAsFixed(1)}..[${extentInside.toStringAsFixed(1)}]..${extentAfter.toStringAsFixed(1)}})';
  }
}

abstract class ScrollNotification2 extends LayoutChangedNotification {
  /// Creates a notification about scrolling.
  ScrollNotification2({
    @required Scrollable2State scrollable,
  }) : axisDirection = scrollable.config.axisDirection,
       metrics = scrollable.position.getMetrics(),
       context = scrollable.context;

  /// The direction that positive scroll offsets indicate.
  final AxisDirection axisDirection;

  Axis get axis => axisDirectionToAxis(axisDirection);

  final ScrollableMetrics metrics;

  /// The build context of the [Scrollable2] that fired this notification.
  ///
  /// This can be used to find the scrollable's render objects to determine the
  /// size of the viewport, for instance.
  // TODO(ianh): Maybe just fold those into the ScrollableMetrics?
  final BuildContext context;

  /// The number of [Scrollable2] widgets that this notification has bubbled
  /// through. Typically listeners only respond to notifications with a [depth]
  /// of zero.
  int get depth => _depth;
  int _depth = 0;

  @override
  bool visitAncestor(Element element) {
    if (element.widget is Scrollable2)
      _depth += 1;
    return super.visitAncestor(element);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('metrics: $metrics');
    description.add('depth: $depth');
  }
}

class ScrollStartNotification extends ScrollNotification2 {
  ScrollStartNotification({
    @required Scrollable2State scrollable,
    this.dragDetails,
  }) : super(scrollable: scrollable);

  final DragStartDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

class ScrollUpdateNotification extends ScrollNotification2 {
  ScrollUpdateNotification({
    @required Scrollable2State scrollable,
    this.dragDetails,
    this.scrollDelta,
  }) : super(scrollable: scrollable);

  final DragUpdateDetails dragDetails;

  /// The distance by which the [Scrollable2] was scrolled, in logical pixels.
  final double scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

class OverscrollNotification extends ScrollNotification2 {
  OverscrollNotification({
    @required Scrollable2State scrollable,
    this.dragDetails,
    @required this.overscroll,
    this.velocity: 0.0,
  }) : super(scrollable: scrollable) {
    assert(overscroll != null);
    assert(overscroll.isFinite);
    assert(overscroll != 0.0);
    assert(velocity != null);
  }

  final DragUpdateDetails dragDetails;

  /// The number of logical pixels that the [Scrollable2] avoided scrolling.
  ///
  /// This will be negative for overscroll on the "start" side and positive for
  /// overscroll on the "end" side.
  final double overscroll;

  /// The velocity at which the [ScrollPosition] was changing when this
  /// overscroll happened.
  ///
  /// This will typically be 0.0 for touch-driven overscrolls, and positive
  /// for overscrolls that happened from a [BallisticScrollActivity] or
  /// [DrivenScrollActivity].
  final double velocity;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('overscroll: ${overscroll.toStringAsFixed(1)}');
    description.add('velocity: ${velocity.toStringAsFixed(1)}');
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

class ScrollEndNotification extends ScrollNotification2 {
  ScrollEndNotification({
    @required Scrollable2State scrollable,
    this.dragDetails,
  }) : super(scrollable: scrollable);

  final DragEndDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

class UserScrollNotification extends ScrollNotification2 {
  UserScrollNotification({
    @required Scrollable2State scrollable,
    this.direction,
  }) : super(scrollable: scrollable);

  final ScrollDirection direction;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $direction');
  }
}
