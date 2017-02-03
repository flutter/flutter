/// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_behavior.dart';
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

////////////////////////////////////////////////////////////////////////////////
// DELETE EVERYTHING BELOW THIS LINE WHEN REMOVING LEGACY SCROLLING CODE
////////////////////////////////////////////////////////////////////////////////

/// Controls how [Scrollable] widgets in a subtree behave.
///
/// Used by [ScrollConfiguration].
abstract class ScrollConfigurationDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ScrollConfigurationDelegate();

  /// Returns the platform whose scroll physics should be approximated. See
  /// [ScrollBehavior.platform].
  TargetPlatform get platform;

  /// Returns the ScrollBehavior to be used by generic scrolling containers like
  /// [Block].
  ExtentScrollBehavior createScrollBehavior();

  /// Generic scrolling containers like [Block] will apply this function to the
  /// Scrollable they create. It can be used to add widgets that wrap the
  /// Scrollable, like scrollbars or overscroll indicators. By default the
  /// [scrollWidget] parameter is returned unchanged.
  Widget wrapScrollWidget(BuildContext context, Widget scrollWidget) => scrollWidget;

  /// Overrides should return true if this ScrollConfigurationDelegate differs
  /// from the provided old delegate in a way that requires rebuilding its
  /// scrolling container descendants.
  bool updateShouldNotify(@checked ScrollConfigurationDelegate old);
}

class _DefaultScrollConfigurationDelegate extends ScrollConfigurationDelegate {
  const _DefaultScrollConfigurationDelegate();

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  ExtentScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior(platform: platform);

  @override
  bool updateShouldNotify(ScrollConfigurationDelegate old) => false;
}

/// A widget that controls descendant [Scrollable] widgets.
///
/// Classes that create Scrollables are not required to depend on this
/// Widget. The following general purpose scrolling widgets do depend
/// on [ScrollConfiguration]: [Block], [LazyBlock], [ScrollableViewport],
/// [ScrollableList], [ScrollableLazyList]. The [Scrollable] base class uses
/// [ScrollConfiguration] to create its [ScrollBehavior].
class ScrollConfiguration extends InheritedWidget {
  /// Creates a widget that controls descendant [Scrollable] widgets.
  ///
  /// If the [delegate] argument is null, the scroll configuration for this
  /// subtree is controlled by the default implementation of
  /// [ScrollConfigurationDelegate].
  ScrollConfiguration({
    Key key,
    this.delegate,
    @required Widget child
  }) : super(key: key, child: child);

  static const ScrollConfigurationDelegate _defaultDelegate = const _DefaultScrollConfigurationDelegate();

  /// Defines the ScrollBehavior and scrollable wrapper for descendants.
  final ScrollConfigurationDelegate delegate;

  /// The delegate property of the closest instance of this class that encloses
  /// the given context.
  ///
  /// If no such instance exists, returns a default
  /// [ScrollConfigurationDelegate] that approximates the scrolling physics of
  /// the current platform (see [defaultTargetPlatform]) using a
  /// [OverscrollWhenScrollableBehavior] behavior model.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScrollConfigurationDelegate scrollConfiguration = ScrollConfiguration.of(context);
  /// ```
  static ScrollConfigurationDelegate of(BuildContext context) {
    ScrollConfiguration configuration = context.inheritFromWidgetOfExactType(ScrollConfiguration);
    return configuration?.delegate ?? _defaultDelegate;
  }

  /// A utility function that calls [ScrollConfigurationDelegate.wrapScrollWidget].
  static Widget wrap(BuildContext context, Widget scrollWidget) {
    return ScrollConfiguration.of(context).wrapScrollWidget(context, scrollWidget);
  }

  @override
  bool updateShouldNotify(ScrollConfiguration old) {
    return delegate?.updateShouldNotify(old.delegate) ?? false;
  }
}
