// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'app.dart';
/// @docImport 'color_scheme.dart';
/// @docImport 'page.dart';
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'theme.dart';

/// Defines the page transition animations used by [MaterialPageRoute]
/// for different [TargetPlatform]s.
///
/// The [MaterialPageRoute.buildTransitions] method looks up the
/// current [PageTransitionsTheme] with `Theme.of(context).pageTransitionsTheme`
/// and delegates to [buildTransitions].
///
/// If a builder with a matching platform is not found, then the
/// [ZoomPageTransitionsBuilder] is used.
///
/// {@tool dartpad}
/// This example shows a [MaterialApp] that defines a custom [PageTransitionsTheme].
///
/// ** See code in examples/api/lib/material/page_transitions_theme/page_transitions_theme.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ThemeData.pageTransitionsTheme], which defines the default page
///    transitions for the overall theme.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided by Android Q.
///  * [FadeForwardsPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided by Android U.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
@immutable
class PageTransitionsTheme with Diagnosticable {
  /// Constructs an object that selects a transition based on the platform.
  ///
  /// By default the list of builders is: [ZoomPageTransitionsBuilder]
  /// for [TargetPlatform.android], [TargetPlatform.windows] and [TargetPlatform.linux]
  /// and [CupertinoPageTransitionsBuilder] for [TargetPlatform.iOS] and [TargetPlatform.macOS].
  const PageTransitionsTheme({
    Map<TargetPlatform, PageTransitionsBuilder> builders = _defaultBuilders,
  }) : _builders = builders;

  static const Map<TargetPlatform, PageTransitionsBuilder> _defaultBuilders =
      <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      };

  /// The [PageTransitionsBuilder]s supported by this theme.
  Map<TargetPlatform, PageTransitionsBuilder> get builders => _builders;
  final Map<TargetPlatform, PageTransitionsBuilder> _builders;

  /// Delegates to the builder for the current [ThemeData.platform].
  /// If a builder for the current platform is not found, then the
  /// [ZoomPageTransitionsBuilder] is used.
  ///
  /// [MaterialPageRoute.buildTransitions] delegates to this method.
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PageTransitionsThemeTransitions<T>(
      builders: builders,
      route: route,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  /// Provides the delegate transition for the target platform.
  ///
  /// {@macro flutter.widgets.delegatedTransition}
  DelegatedTransitionBuilder? delegatedTransition(TargetPlatform platform) {
    final PageTransitionsBuilder matchingBuilder =
        builders[platform] ?? const ZoomPageTransitionsBuilder();

    return matchingBuilder.delegatedTransition;
  }

  // Map the builders to a list with one PageTransitionsBuilder per platform for
  // the operator == overload.
  List<PageTransitionsBuilder?> _all(Map<TargetPlatform, PageTransitionsBuilder> builders) {
    return TargetPlatform.values.map((TargetPlatform platform) => builders[platform]).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (other is PageTransitionsTheme && identical(builders, other.builders)) {
      return true;
    }
    return other is PageTransitionsTheme &&
        listEquals<PageTransitionsBuilder?>(_all(other.builders), _all(builders));
  }

  @override
  int get hashCode => Object.hashAll(_all(builders));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Map<TargetPlatform, PageTransitionsBuilder>>(
        'builders',
        builders,
        defaultValue: PageTransitionsTheme._defaultBuilders,
      ),
    );
  }
}

class _PageTransitionsThemeTransitions<T> extends StatefulWidget {
  const _PageTransitionsThemeTransitions({
    required this.builders,
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Map<TargetPlatform, PageTransitionsBuilder> builders;
  final PageRoute<T> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_PageTransitionsThemeTransitions<T>> createState() =>
      _PageTransitionsThemeTransitionsState<T>();
}

class _PageTransitionsThemeTransitionsState<T> extends State<_PageTransitionsThemeTransitions<T>> {
  TargetPlatform? _transitionPlatform;

  @override
  Widget build(BuildContext context) {
    TargetPlatform platform = Theme.of(context).platform;

    // If the theme platform is changed in the middle of a pop gesture, keep the
    // transition that the gesture began with until the gesture is finished.
    if (widget.route.popGestureInProgress) {
      _transitionPlatform ??= platform;
      platform = _transitionPlatform!;
    } else {
      _transitionPlatform = null;
    }

    final PageTransitionsBuilder matchingBuilder =
        widget.builders[platform] ??
        switch (platform) {
          TargetPlatform.iOS => const CupertinoPageTransitionsBuilder(),
          TargetPlatform.android ||
          TargetPlatform.fuchsia ||
          TargetPlatform.windows ||
          TargetPlatform.macOS ||
          TargetPlatform.linux => const ZoomPageTransitionsBuilder(),
        };
    return matchingBuilder.buildTransitions<T>(
      widget.route,
      context,
      widget.animation,
      widget.secondaryAnimation,
      widget.child,
    );
  }
}
