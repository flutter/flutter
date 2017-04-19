// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scrollable.dart' show Scrollable, ScrollableState;

/// A description of a [Scrollable]'s contents, useful for modelling the state
/// of the viewport, for example by a [Scrollbar].
///
/// The units used by the [extentBefore], [extentInside], and [extentAfter] are
/// not defined, but must be consistent. For example, they could be in pixels,
/// or in percentages, or in units of the [extentInside] (in the latter case,
/// [extentInside] would always be 1.0).
@immutable
class ScrollMetrics {
  /// Create a description of the metrics of a [Scrollable]'s contents.
  ///
  /// The three arguments must be present, non-null, finite, and non-negative.
  const ScrollMetrics({
    @required this.extentBefore,
    @required this.extentInside,
    @required this.extentAfter,
    @required this.viewportDimension,
  });

  /// Creates a [ScrollMetrics] that has the same properties as the given
  /// [ScrollMetrics].
  ScrollMetrics.clone(ScrollMetrics other)
    : extentBefore = other.extentBefore,
      extentInside = other.extentInside,
      extentAfter = other.extentAfter,
      viewportDimension = other.viewportDimension;

  /// The quantity of content conceptually "above" the currently visible content
  /// of the viewport in the scrollable. This is the content above the content
  /// described by [extentInside].
  final double extentBefore;

  /// The quantity of visible content.
  ///
  /// If [extentBefore] and [extentAfter] are non-zero, then this is typically
  /// the height of the viewport. It could be less if there is less content
  /// visible than the size of the viewport.
  final double extentInside;

  /// The quantity of content conceptually "below" the currently visible content
  /// of the viewport in the scrollable. This is the content below the content
  /// described by [extentInside].
  final double extentAfter;

  final double viewportDimension;

  @override
  String toString() {
    return '$runtimeType(${extentBefore.toStringAsFixed(1)}..[${extentInside.toStringAsFixed(1)}]..${extentAfter.toStringAsFixed(1)}})';
  }
}

/// Mixin for [Notification]s that track how many [RenderAbstractViewport] they
/// have bubbled through.
///
/// This is used by [ScrollNotification] and [OverscrollIndicatorNotification].
abstract class ViewportNotificationMixin extends Notification {
  /// The number of viewports that this notification has bubbled through.
  ///
  /// Typically listeners only respond to notifications with a [depth] of zero.
  ///
  /// Specifically, this is the number of [Widget]s representing
  /// [RenderAbstractViewport] render objects through which this notification
  /// has bubbled.
  int get depth => _depth;
  int _depth = 0;

  @override
  bool visitAncestor(Element element) {
    if (element is RenderObjectElement && element.renderObject is RenderAbstractViewport)
      _depth += 1;
    return super.visitAncestor(element);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('depth: $depth (${ depth == 0 ? "local" : "remote"})');
  }
}

abstract class ScrollNotification extends LayoutChangedNotification with ViewportNotificationMixin {
  /// Creates a notification about scrolling.
  ScrollNotification({
    @required ScrollableState scrollable,
  }) : axisDirection = scrollable.widget.axisDirection,
       metrics = scrollable.position.getMetrics(),
       context = scrollable.context;

  /// The direction that positive scroll offsets indicate.
  final AxisDirection axisDirection;

  Axis get axis => axisDirectionToAxis(axisDirection);

  final ScrollMetrics metrics;

  /// The build context of the [Scrollable] that fired this notification.
  ///
  /// This can be used to find the scrollable's render objects to determine the
  /// size of the viewport, for instance.
  final BuildContext context;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('metrics: $metrics');
  }
}

class ScrollStartNotification extends ScrollNotification {
  ScrollStartNotification({
    @required ScrollableState scrollable,
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

class ScrollUpdateNotification extends ScrollNotification {
  ScrollUpdateNotification({
    @required ScrollableState scrollable,
    this.dragDetails,
    this.scrollDelta,
  }) : super(scrollable: scrollable);

  final DragUpdateDetails dragDetails;

  /// The distance by which the [Scrollable] was scrolled, in logical pixels.
  final double scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

class OverscrollNotification extends ScrollNotification {
  OverscrollNotification({
    @required ScrollableState scrollable,
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

  /// The number of logical pixels that the [Scrollable] avoided scrolling.
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

class ScrollEndNotification extends ScrollNotification {
  ScrollEndNotification({
    @required ScrollableState scrollable,
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

class UserScrollNotification extends ScrollNotification {
  UserScrollNotification({
    @required ScrollableState scrollable,
    this.direction,
  }) : super(scrollable: scrollable);

  final ScrollDirection direction;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $direction');
  }
}
