// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_metrics.dart';

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
    @required this.metrics,
    @required this.context,
  });

  final ScrollMetrics metrics;

  /// The build context of the widget that fired this notification.
  ///
  /// This can be used to find the scrollable's render objects to determine the
  /// size of the viewport, for instance.
  final BuildContext context;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$metrics');
  }
}

class ScrollStartNotification extends ScrollNotification {
  ScrollStartNotification({
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
  }) : super(metrics: metrics, context: context);

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
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
    this.scrollDelta,
  }) : super(metrics: metrics, context: context);

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
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
    @required this.overscroll,
    this.velocity: 0.0,
  }) : super(metrics: metrics, context: context) {
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
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
  }) : super(metrics: metrics, context: context);

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
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.direction,
  }) : super(metrics: metrics, context: context);

  final ScrollDirection direction;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $direction');
  }
}
