/// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_physics.dart';
import 'overscroll_indicator.dart';

class ScrollBehavior2 {
  const ScrollBehavior2();

  /// The platform whose scroll physics should be implemented.
  ///
  /// Defaults to the current platform.
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  /// The color to use for the glow effect when [platform] indicates a platform
  /// that uses a [GlowingOverscrollIndicator].
  ///
  /// Defaults to white.
  Color getGlowColor(BuildContext context) => const Color(0xFFFFFFFF);

  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return new GlowingOverscrollIndicator(
          child: child,
          axisDirection: axisDirection,
          color: getGlowColor(context),
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

  bool shouldNotify(@checked ScrollBehavior2 oldDelegate) => false;
}

class ScrollConfiguration2 extends InheritedWidget {
  const ScrollConfiguration2({
    Key key,
    @required this.behavior,
    @required Widget child,
  }) : super(key: key, child: child);

  final ScrollBehavior2 behavior;

  static ScrollBehavior2 of(BuildContext context) {
    final ScrollConfiguration2 configuration = context.inheritFromWidgetOfExactType(ScrollConfiguration2);
    return configuration?.behavior ?? const ScrollBehavior2();
  }

  @override
  bool updateShouldNotify(ScrollConfiguration2 old) {
    assert(behavior != null);
    return behavior.runtimeType != old.behavior.runtimeType
        || behavior.shouldNotify(old.behavior);
  }
}
