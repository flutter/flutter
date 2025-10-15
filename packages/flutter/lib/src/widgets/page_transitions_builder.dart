// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'basic.dart';
import 'framework.dart';
import 'pages.dart';
import 'transitions.dart';

/// Defines a page transition animation for a [PageRoute].
///
/// PageTransitionsBuilder can be used directly with widget layer primitives
/// in any design system. Custom [PageRoute] subclasses can accept a
/// PageTransitionsBuilder and delegate to its [buildTransitions] method when
/// overriding [ModalRoute.buildTransitions]. This enables reusable transition
/// animations that work with [Navigator] and other navigation primitives.
///
/// ## Example usage
///
/// {@tool dartpad}
/// This example shows how to create a custom [PageTransitionsBuilder] that
/// slides the new page in from the right while fading it in, and how to use
/// it with a custom [PageRoute].
///
/// ** See code in examples/api/lib/widgets/page_transitions_builder/page_transitions_builder.0.dart **
/// {@end-tool}
///
/// As an example of usage, in the Material library this class is used by
/// [PageTransitionsTheme] to define a [MaterialPageRoute] page transition
/// animation. Apps can configure the map of builders for
/// [ThemeData.pageTransitionsTheme] to customize the default
/// [MaterialPageRoute] page transition animation for different platforms.
///
/// See also:
///
///  * [PageTransitionsTheme], which uses this class to configure page transitions.
///  * [MaterialPageRoute], which uses this class to build its transition.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * [FadeForwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android U.
abstract class PageTransitionsBuilder {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PageTransitionsBuilder();

  /// Provides a secondary transition to the previous route.
  ///
  /// {@macro flutter.widgets.delegatedTransition}
  DelegatedTransitionBuilder? get delegatedTransition => null;

  /// {@macro flutter.widgets.TransitionRoute.transitionDuration}
  ///
  /// Defaults to 300 milliseconds.
  Duration get transitionDuration => const Duration(milliseconds: 300);

  /// {@macro flutter.widgets.TransitionRoute.reverseTransitionDuration}
  ///
  /// Defaults to 300 milliseconds.
  Duration get reverseTransitionDuration => transitionDuration;

  /// Wraps the child with one or more transition widgets which define how [route]
  /// arrives on and leaves the screen.
  ///
  /// Subclasses override this method to create a transition animation.
  ///
  /// The [MaterialPageRoute.buildTransitions] method is an example of a method
  /// that uses this to build a transition. It looks up the current
  /// [PageTransitionsTheme] with `Theme.of(context).pageTransitionsTheme`
  /// and delegates to this method with a [PageTransitionsBuilder] based
  /// on the theme's [ThemeData.platform].
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}

// Slides the page upwards and fades it in, starting from 1/4 screen
// below the top. The transition is intended to match the default for
// Android O.
class _FadeUpwardsPageTransition extends StatelessWidget {
  _FadeUpwardsPageTransition({
    required Animation<double> routeAnimation, // The route's linear 0.0 - 1.0 animation.
    required this.child,
  }) : _positionAnimation = routeAnimation.drive(_bottomUpTween.chain(_fastOutSlowInTween)),
       _opacityAnimation = routeAnimation.drive(_easeInTween);

  // Fractional offset from 1/4 screen below the top to fully on screen.
  static final Tween<Offset> _bottomUpTween = Tween<Offset>(
    begin: const Offset(0.0, 0.25),
    end: Offset.zero,
  );
  static final Animatable<double> _fastOutSlowInTween = CurveTween(curve: Curves.fastOutSlowIn);
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);

  final Animation<Offset> _positionAnimation;
  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _positionAnimation,
      // TODO(ianh): tell the transform to be un-transformed for hit testing
      child: FadeTransition(opacity: _opacityAnimation, child: child),
    );
  }
}

/// A page transition builder that animates incoming pages by fading and
/// sliding them upwards.
///
/// This transition combines two animations:
/// - A fade-in effect using an ease-in curve
/// - An upward slide starting from 25% below the top of the screen
///
/// The resulting animation creates a smooth entrance effect where the new
/// page appears to rise up while simultaneously becoming visible.
///
/// See also:
///
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * [PredictiveBackPageTransitionsBuilder], which defines a page
///    transition that allows peeking behind the current route on Android U and
///    above.
class FadeUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Constructs a page transition animation that slides the page up.
  const FadeUpwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    return _FadeUpwardsPageTransition(routeAnimation: animation, child: child);
  }
}
