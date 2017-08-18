/// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show min, pow;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'overscroll_indicator.dart';
import 'scroll_context.dart';
import 'scroll_physics.dart';

const Color _kDefaultGlowColor = const Color(0xFFFFFFFF);

// Methodology:
// 1- Use https://github.com/flutter/scroll_overlay to test with Flutter and
//    platform scroll views superimposed.
// 2- Record incoming speed and make rapid flings in the test app.
// 3- If the scrollables stopped overlapping at any moment, adjust the desired
//    output value of this function at that input speed.
// 4- Feed new input/output set into a power curve fitter. Change function
//    and repeat from 2.
// 5- Repeat from 2 with medium and slow flings.
/// Momentum build-up function that mimics iOS's scroll speed increase with repeated flings.
///
/// Note the velocity of the last fling is not an important factor. Existing speed
/// and (related) time since last fling are.
MomentumCarryFunction iosMomentumCarryFunction = (double existingVelocity) {
  return existingVelocity.sign *
      min(0.06 * pow(existingVelocity.abs(), 1.42).toDouble(), 30000.0);
};

/// Platforms other than iOS don't carry scrolling momentum with repeated scrolls.
///
/// Previous velocity is discarded and not carried forward.
MomentumCarryFunction noMomentumCarryFunction = (double existingVelocity) => 0.0;

/// Describes how [Scrollable] widgets should behave.
///
/// Used by [ScrollConfiguration] to configure the [Scrollable] widgets in a
/// subtree.
@immutable
class ScrollBehavior {
  /// Creates a description of how [Scrollable] widgets should behave.
  const ScrollBehavior();

  /// The platform whose scroll physics should be implemented.
  ///
  /// Defaults to the current platform.
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  /// Wraps the given widget, which scrolls in the given [AxisDirection].
  ///
  /// For example, on Android, this method wraps the given widget with a
  /// [GlowingOverscrollIndicator] to provide visual feedback when the user
  /// overscrolls.
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    // When modifying this function, consider modifying the implementation in
    // _MaterialScrollBehavior as well.
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return new GlowingOverscrollIndicator(
          child: child,
          axisDirection: axisDirection,
          color: _kDefaultGlowColor,
        );
    }
    return null;
  }

  /// The scroll physics to use for the platform given by [getPlatform].
  ///
  /// Defaults to [BouncingScrollPhysics] on iOS and [ClampingScrollPhysics] on
  /// Android.
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return const BouncingScrollPhysics();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const ClampingScrollPhysics();
    }
    return null;
  }

  /// A function for carrying scrolling momentum depending on the platform.
  ///
  /// The function is applied to the existing scroll velocity when another
  /// scroll drag is applied in the same direction.
  ///
  /// Scrolling momentum is not carried on Android and grows exponentially
  /// on iOS.
  MomentumCarryFunction getScrollMomentumCarryFunction(BuildContext context) {
    if (getPlatform(context) == TargetPlatform.iOS)
      return iosMomentumCarryFunction;

    return noMomentumCarryFunction;
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
  String toString() => '$runtimeType';
}

/// Controls how [Scrollable] widgets behave in a subtree.
///
/// The scroll configuration determines the [ScrollPhysics] and viewport
/// decorations used by decendants of [child].
class ScrollConfiguration extends InheritedWidget {
  /// Creates a widget that controls how [Scrollable] widgets behave in a subtree.
  ///
  /// The [behavior] and [child] arguments must not be null.
  const ScrollConfiguration({
    Key key,
    @required this.behavior,
    @required Widget child,
  }) : super(key: key, child: child);

  /// How [Scrollable] widgets that are decendants of [child] should behave.
  final ScrollBehavior behavior;

  /// The [ScrollBehavior] for [Scrollable] widgets in the given [BuildContext].
  ///
  /// If no [ScrollConfiguration] widget is in scope of the given `context`,
  /// a default [ScrollBehavior] instance is returned.
  static ScrollBehavior of(BuildContext context) {
    final ScrollConfiguration configuration = context.inheritFromWidgetOfExactType(ScrollConfiguration);
    return configuration?.behavior ?? const ScrollBehavior();
  }

  @override
  bool updateShouldNotify(ScrollConfiguration oldWidget) {
    assert(behavior != null);
    return behavior.runtimeType != oldWidget.behavior.runtimeType
        || (behavior != oldWidget.behavior && behavior.shouldNotify(oldWidget.behavior));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<ScrollBehavior>('behavior', behavior));
  }
}
