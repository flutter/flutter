// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'overscroll_indicator.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';
import 'scrollbar.dart';

const Color _kDefaultGlowColor = Color(0xFFFFFFFF);

/// Describes how [Scrollable] widgets should behave.
///
/// {@template flutter.widgets.scrollBehavior}
/// Used by [ScrollConfiguration] to configure the [Scrollable] widgets in a
/// subtree.
///
/// This class can be extended to further customize a [ScrollBehavior] for a
/// subtree. For example, overriding [ScrollBehavior.getScrollPhysics] sets the
/// default [ScrollPhysics] for [Scrollable]s that inherit this [ScrollConfiguration].
/// Overriding [ScrollBehavior.buildViewportDecoration] can be used to add or change
/// default decorations like [GlowingOverscrollIndicator]s.
/// {@endtemplate}
///
/// See also:
///
///   * [ScrollConfiguration], the inherited widget that controls how
///     [Scrollable] widgets behave in a subtree.
@immutable
class ScrollBehavior {
  /// Creates a description of how [Scrollable] widgets should behave.
  const ScrollBehavior({
    @Deprecated(
      'Temporary migration flag, do not use. '
      'This feature was deprecated after v2.1.0-11.0.pre.'
    )
    bool useDecoration = false,
  }) : _useDecoration = useDecoration;

  // Whether [buildViewportChrome] or [buildViewportDecoration] should be used
  // in wrapping the Scrollable widget.
  //
  // This is used to maintain subclass behavior to allow for graceful migration.
  final bool _useDecoration;

  ///
  ScrollBehavior copyWith({ bool scrollbars = true, bool overscroll = true}) {
    return _WrappedScrollBehavior(delegate: this, scrollbars: scrollbars, overscroll: overscroll);
  }

  /// The platform whose scroll physics should be implemented.
  ///
  /// Defaults to the current platform.
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  /// Wraps the given widget, which scrolls in the given [AxisDirection].
  ///
  /// For example, on Android, this method wraps the given widget with a
  /// [GlowingOverscrollIndicator] to provide visual feedback when the user
  /// overscrolls.
  ///
  /// This method is deprecated. Use [ScrollBehavior.buildViewportDecoration] instead.
  @Deprecated(
    'Migrate to buildViewportDecoration. '
    'This feature was deprecated after v2.1.0-11.0.pre.'
  )
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return buildOverscrollIndicator(context, child, axisDirection);
    }
  }

  /// Wraps the given widget with the information provided by [ScrollableDetails].
  ///
  /// Based on the platforms designated by [glowingPlatforms], or
  /// the [defaultGlowingPlatforms], this method could wrap a given widget with
  /// a [GlowingOverscrollIndicator] to provide visual feedback when the user overscrolls.
  ///
  /// Based on the platforms designated by [scrollbarPlatforms], or
  /// the [defaultScrollbarPlatforms], this method could wrap a given widget with
  /// a [Scrollbar].
  Widget buildViewportDecoration(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // If useDecoration is false, call buildViewportChrome instead, this is to
    // avoid breaking subclasses that have not implemented buildViewportDecoration yet.
    if (!_useDecoration)
      return buildViewportChrome(context, child, details.direction);

    // When modifying this function, consider modifying the implementation in
    // MaterialScrollBehavior and CupertinoScrollBehavior as well.
    // By default:
    //   * On Android and Fuchsia, we add a GlowingOverscrollIndicator.
    //   * On Desktop platforms, we add a RawScrollbar.
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return buildScrollbar(child, details.controller);
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return buildOverscrollIndicator(context, child, details.direction);
    }
  }

  ///
  Widget buildScrollbar(Widget child, ScrollController controller) {
    return RawScrollbar(
      child: child,
      controller: controller,
    );
  }

  ///
  Widget buildOverscrollIndicator(BuildContext context, Widget child, AxisDirection direction) {
    return GlowingOverscrollIndicator(
      child: child,
      axisDirection: direction,
      color: _kDefaultGlowColor,
    );
  }

  /// Specifies the type of velocity tracker to use in the descendant
  /// [Scrollable]s' drag gesture recognizers, for estimating the velocity of a
  /// drag gesture.
  ///
  /// This can be used to, for example, apply different fling velocity
  /// estimation methods on different platforms, in order to match the
  /// platform's native behavior.
  ///
  /// Typically, the provided [GestureVelocityTrackerBuilder] should return a
  /// fresh velocity tracker. If null is returned, [Scrollable] creates a new
  /// [VelocityTracker] to track the newly added pointer that may develop into
  /// a drag gesture.
  ///
  /// The default implementation provides a new
  /// [IOSScrollViewFlingVelocityTracker] on iOS and macOS for each new pointer,
  /// and a new [VelocityTracker] on other platforms for each new pointer.
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return (PointerEvent event) => IOSScrollViewFlingVelocityTracker(event.kind);
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return (PointerEvent event) => VelocityTracker.withKind(event.kind);
    }
  }

  static const ScrollPhysics _bouncingPhysics = BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());
  static const ScrollPhysics _clampingPhysics = ClampingScrollPhysics(parent: RangeMaintainingScrollPhysics());

  /// The scroll physics to use for the platform given by [getPlatform].
  ///
  /// Defaults to [RangeMaintainingScrollPhysics] mixed with
  /// [BouncingScrollPhysics] on iOS and [ClampingScrollPhysics] on
  /// Android.
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _bouncingPhysics;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _clampingPhysics;
    }
  }

  /// Called whenever a [ScrollConfiguration] is rebuilt with a new
  /// [ScrollBehavior] of the same [runtimeType].
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If this method returns true, all the widgets that inherit from the
  /// [ScrollConfiguration] will rebuild using the new [ScrollBehavior]. If this
  /// method returns false, the rebuilds might be optimized away.
  bool shouldNotify(covariant ScrollBehavior oldDelegate) => false;

  @override
  String toString() => objectRuntimeType(this, 'ScrollBehavior');
}

class _WrappedScrollBehavior implements ScrollBehavior {
  const _WrappedScrollBehavior({
    required this.delegate,
    this.scrollbars = true,
    this.overscroll = true,
  });

  final ScrollBehavior delegate;
  final bool scrollbars;
  final bool overscroll;

  @override
  bool get _useDecoration => true;

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, AxisDirection direction) {
    if (overscroll)
      return delegate.buildOverscrollIndicator(context, child, direction);
    return child;
  }

  @override
  Widget buildScrollbar(Widget child, ScrollController controller) {
    if (scrollbars)
      return delegate.buildScrollbar(child, controller);
    return child;
  }

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return delegate.buildViewportChrome(context, child, axisDirection);
  }

  @override
  Widget buildViewportDecoration(BuildContext context, Widget child, ScrollableDetails details) {
    return delegate.buildViewportDecoration(context, child, details);
  }

  @override
  ScrollBehavior copyWith({bool scrollbars = true, bool overscroll = true}) {
    return delegate.copyWith(scrollbars: scrollbars, overscroll: overscroll);
  }

  @override
  TargetPlatform getPlatform(BuildContext context) {
    return delegate.getPlatform(context);
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return delegate.getScrollPhysics(context);
  }

  @override
  bool shouldNotify(covariant ScrollBehavior oldDelegate) {
    return delegate.shouldNotify(oldDelegate);
  }

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) {
    return delegate.velocityTrackerBuilder(context);
  }

}

/// Controls how [Scrollable] widgets behave in a subtree.
///
/// The scroll configuration determines the [ScrollPhysics] and viewport
/// decorations used by descendants of [child].
class ScrollConfiguration extends InheritedWidget {
  /// Creates a widget that controls how [Scrollable] widgets behave in a subtree.
  ///
  /// The [behavior] and [child] arguments must not be null.
  const ScrollConfiguration({
    Key? key,
    required this.behavior,
    required Widget child,
  }) : super(key: key, child: child);

  /// How [Scrollable] widgets that are descendants of [child] should behave.
  final ScrollBehavior behavior;

  /// The [ScrollBehavior] for [Scrollable] widgets in the given [BuildContext].
  ///
  /// If no [ScrollConfiguration] widget is in scope of the given `context`,
  /// a default [ScrollBehavior] instance is returned.
  static ScrollBehavior of(BuildContext context) {
    final ScrollConfiguration? configuration = context.dependOnInheritedWidgetOfExactType<ScrollConfiguration>();
    return configuration?.behavior ?? const ScrollBehavior(useDecoration: true);
  }

  @override
  bool updateShouldNotify(ScrollConfiguration oldWidget) {
    assert(behavior != null);
    return behavior.runtimeType != oldWidget.behavior.runtimeType
        || (behavior != oldWidget.behavior && behavior.shouldNotify(oldWidget.behavior));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollBehavior>('behavior', behavior));
  }
}
