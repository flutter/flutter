// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_metrics.dart';

/// Mixin for [Notification]s that track how many [RenderAbstractViewport] they
/// have bubbled through.
///
/// This is used by [ScrollNotification] and [OverscrollIndicatorNotification].
mixin ViewportNotificationMixin on Notification {
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
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('depth: $depth (${ depth == 0 ? "local" : "remote"})');
  }
}

/// A mixin that allows [Element]s containing [Viewport] like widgets to correctly
/// modify the notification depth of a [ViewportNotificationMixin].
///
/// See also:
///   * [Viewport], which creates a custom [MultiChildRenderObjectElement] that mixes
///     this in.
mixin ViewportElementMixin  on NotifiableElementMixin {
  @override
  bool onNotification(Notification notification) {
    if (notification is ViewportNotificationMixin) {
      notification._depth += 1;
    }
    return false;
  }
}

/// A [Notification] related to scrolling.
///
/// [Scrollable] widgets notify their ancestors about scrolling-related changes.
/// The notifications have the following lifecycle:
///
///  * A [ScrollStartNotification], which indicates that the widget has started
///    scrolling.
///  * Zero or more [ScrollUpdateNotification]s, which indicate that the widget
///    has changed its scroll position, mixed with zero or more
///    [OverscrollNotification]s, which indicate that the widget has not changed
///    its scroll position because the change would have caused its scroll
///    position to go outside its scroll bounds.
///  * Interspersed with the [ScrollUpdateNotification]s and
///    [OverscrollNotification]s are zero or more [UserScrollNotification]s,
///    which indicate that the user has changed the direction in which they are
///    scrolling.
///  * A [ScrollEndNotification], which indicates that the widget has stopped
///    scrolling.
///  * A [UserScrollNotification], with a [UserScrollNotification.direction] of
///    [ScrollDirection.idle].
///
/// Notifications bubble up through the tree, which means a given
/// [NotificationListener] will receive notifications for all descendant
/// [Scrollable] widgets. To focus on notifications from the nearest
/// [Scrollable] descendant, check that the [depth] property of the notification
/// is zero.
///
/// When a scroll notification is received by a [NotificationListener], the
/// listener will have already completed build and layout, and it is therefore
/// too late for that widget to call [State.setState]. Any attempt to adjust the
/// build or layout based on a scroll notification would result in a layout that
/// lagged one frame behind, which is a poor user experience. Scroll
/// notifications are therefore primarily useful for paint effects (since paint
/// happens after layout). The [GlowingOverscrollIndicator] and [Scrollbar]
/// widgets are examples of paint effects that use scroll notifications.
///
/// To drive layout based on the scroll position, consider listening to the
/// [ScrollPosition] directly (or indirectly via a [ScrollController]).
abstract class ScrollNotification extends LayoutChangedNotification with ViewportNotificationMixin {
  /// Initializes fields for subclasses.
  ScrollNotification({
    required this.metrics,
    required this.context,
  });

  /// A description of a [Scrollable]'s contents, useful for modeling the state
  /// of its viewport.
  final ScrollMetrics metrics;

  /// The build context of the widget that fired this notification.
  ///
  /// This can be used to find the scrollable's render objects to determine the
  /// size of the viewport, for instance.
  final BuildContext? context;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$metrics');
  }
}

/// A notification that a [Scrollable] widget has started scrolling.
///
/// See also:
///
///  * [ScrollEndNotification], which indicates that scrolling has stopped.
///  * [ScrollNotification], which describes the notification lifecycle.
class ScrollStartNotification extends ScrollNotification {
  /// Creates a notification that a [Scrollable] widget has started scrolling.
  ScrollStartNotification({
    required ScrollMetrics metrics,
    required BuildContext? context,
    this.dragDetails,
  }) : super(metrics: metrics, context: context);

  /// If the [Scrollable] started scrolling because of a drag, the details about
  /// that drag start.
  ///
  /// Otherwise, null.
  final DragStartDetails? dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

/// A notification that a [Scrollable] widget has changed its scroll position.
///
/// See also:
///
///  * [OverscrollNotification], which indicates that a [Scrollable] widget
///    has not changed its scroll position because the change would have caused
///    its scroll position to go outside its scroll bounds.
///  * [ScrollNotification], which describes the notification lifecycle.
class ScrollUpdateNotification extends ScrollNotification {
  /// Creates a notification that a [Scrollable] widget has changed its scroll
  /// position.
  ScrollUpdateNotification({
    required ScrollMetrics metrics,
    required BuildContext context,
    this.dragDetails,
    this.scrollDelta,
    int? depth,
  }) : super(metrics: metrics, context: context) {
    if (depth != null) {
      _depth = depth;
    }
  }

  /// If the [Scrollable] changed its scroll position because of a drag, the
  /// details about that drag update.
  ///
  /// Otherwise, null.
  final DragUpdateDetails? dragDetails;

  /// The distance by which the [Scrollable] was scrolled, in logical pixels.
  final double? scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

/// A notification that a [Scrollable] widget has not changed its scroll position
/// because the change would have caused its scroll position to go outside of
/// its scroll bounds.
///
/// See also:
///
///  * [ScrollUpdateNotification], which indicates that a [Scrollable] widget
///    has changed its scroll position.
///  * [ScrollNotification], which describes the notification lifecycle.
class OverscrollNotification extends ScrollNotification {
  /// Creates a notification that a [Scrollable] widget has changed its scroll
  /// position outside of its scroll bounds.
  OverscrollNotification({
    required ScrollMetrics metrics,
    required BuildContext context,
    this.dragDetails,
    required this.overscroll,
    this.velocity = 0.0,
  }) : assert(overscroll != null),
       assert(overscroll.isFinite),
       assert(overscroll != 0.0),
       assert(velocity != null),
       super(metrics: metrics, context: context);

  /// If the [Scrollable] overscrolled because of a drag, the details about that
  /// drag update.
  ///
  /// Otherwise, null.
  final DragUpdateDetails? dragDetails;

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

/// A notification that a [Scrollable] widget has stopped scrolling.
///
/// See also:
///
///  * [ScrollStartNotification], which indicates that scrolling has started.
///  * [ScrollNotification], which describes the notification lifecycle.
class ScrollEndNotification extends ScrollNotification {
  /// Creates a notification that a [Scrollable] widget has stopped scrolling.
  ScrollEndNotification({
    required ScrollMetrics metrics,
    required BuildContext context,
    this.dragDetails,
  }) : super(metrics: metrics, context: context);

  /// If the [Scrollable] stopped scrolling because of a drag, the details about
  /// that drag end.
  ///
  /// Otherwise, null.
  ///
  /// If a drag ends with some residual velocity, a typical [ScrollPhysics] will
  /// start a ballistic scroll, which delays the [ScrollEndNotification] until
  /// the ballistic simulation completes, at which time [dragDetails] will
  /// be null. If the residual velocity is too small to trigger ballistic
  /// scrolling, then the [ScrollEndNotification] will be dispatched immediately
  /// and [dragDetails] will be non-null.
  final DragEndDetails? dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dragDetails != null)
      description.add('$dragDetails');
  }
}

/// A notification that the user has changed the direction in which they are
/// scrolling.
///
/// See also:
///
///  * [ScrollNotification], which describes the notification lifecycle.
class UserScrollNotification extends ScrollNotification {
  /// Creates a notification that the user has changed the direction in which
  /// they are scrolling.
  UserScrollNotification({
    required ScrollMetrics metrics,
    required BuildContext context,
    required this.direction,
  }) : super(metrics: metrics, context: context);

  /// The direction in which the user is scrolling.
  final ScrollDirection direction;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $direction');
  }
}

/// A predicate for [ScrollNotification], used to customize widgets that
/// listen to notifications from their children.
typedef ScrollNotificationPredicate = bool Function(ScrollNotification notification);

/// A [ScrollNotificationPredicate] that checks whether
/// `notification.depth == 0`, which means that the notification did not bubble
/// through any intervening scrolling widgets.
bool defaultScrollNotificationPredicate(ScrollNotification notification) {
  return notification.depth == 0;
}
