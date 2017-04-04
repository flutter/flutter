/// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'overscroll_indicator.dart';
import 'scroll_physics.dart';

const Color _kDefaultGlowColor = const Color(0xFFFFFFFF);

/// Describes how [Scrollable] widgets should behave.
///
/// Used by [ScrollConfiguration] to configure the [Scrollable] widgets in a
/// subtree.
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

  /// The scroll physics to use for the given platform.
  ///
  /// Used by [createScrollPosition] to get the scroll physics for newly created
  /// scroll positions.
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

  bool shouldNotify(covariant ScrollBehavior oldDelegate) => false;
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
  static ScrollBehavior of(BuildContext context) {
    final ScrollConfiguration configuration = context.inheritFromWidgetOfExactType(ScrollConfiguration);
    return configuration?.behavior ?? const ScrollBehavior();
  }

  @override
  bool updateShouldNotify(ScrollConfiguration old) {
    assert(behavior != null);
    return behavior.runtimeType != old.behavior.runtimeType
        || behavior.shouldNotify(old.behavior);
  }
}
