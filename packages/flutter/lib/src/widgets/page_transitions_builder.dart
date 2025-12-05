// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'basic.dart';
import 'dual_transition_builder.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'pages.dart';
import 'routes.dart';
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

// This transition is intended to match the default for Android P.
class _OpenUpwardsPageTransition extends StatefulWidget {
  const _OpenUpwardsPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  // The new page slides upwards just a little as its clip
  // rectangle exposes the page from bottom to top.
  static final Tween<Offset> _primaryTranslationTween = Tween<Offset>(
    begin: const Offset(0.0, 0.05),
    end: Offset.zero,
  );

  // The old page slides upwards a little as the new page appears.
  static final Tween<Offset> _secondaryTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.0, -0.025),
  );

  // The scrim color that obscures the old page during the transition.
  static const Color _scrimColor = Color(0xFF000000);

  // The scrim obscures the old page by becoming increasingly opaque.
  static final Tween<double> _scrimOpacityTween = Tween<double>(begin: 0.0, end: 0.25);

  // Used by all of the transition animations.
  static const Curve _transitionCurve = Cubic(0.20, 0.00, 0.00, 1.00);

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_OpenUpwardsPageTransition> createState() => _OpenUpwardsPageTransitionState();
}

class _OpenUpwardsPageTransitionState extends State<_OpenUpwardsPageTransition> {
  late CurvedAnimation _primaryAnimation;
  late CurvedAnimation _secondaryTranslationCurvedAnimation;

  @override
  void initState() {
    super.initState();
    _setAnimations();
  }

  @override
  void didUpdateWidget(covariant _OpenUpwardsPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _disposeAnimations();
      _setAnimations();
    }
  }

  void _setAnimations() {
    _primaryAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: _OpenUpwardsPageTransition._transitionCurve,
      reverseCurve: _OpenUpwardsPageTransition._transitionCurve.flipped,
    );
    _secondaryTranslationCurvedAnimation = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: _OpenUpwardsPageTransition._transitionCurve,
      reverseCurve: _OpenUpwardsPageTransition._transitionCurve.flipped,
    );
  }

  void _disposeAnimations() {
    _primaryAnimation.dispose();
    _secondaryTranslationCurvedAnimation.dispose();
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;

        // Gradually expose the new page from bottom to top.
        final Animation<double> clipAnimation = Tween<double>(
          begin: 0.0,
          end: size.height,
        ).animate(_primaryAnimation);

        final Animation<double> opacityAnimation = _OpenUpwardsPageTransition._scrimOpacityTween
            .animate(_primaryAnimation);
        final Animation<Offset> primaryTranslationAnimation = _OpenUpwardsPageTransition
            ._primaryTranslationTween
            .animate(_primaryAnimation);

        final Animation<Offset> secondaryTranslationAnimation = _OpenUpwardsPageTransition
            ._secondaryTranslationTween
            .animate(_secondaryTranslationCurvedAnimation);

        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[widget.animation, widget.secondaryAnimation]),
          builder: (BuildContext context, Widget? child) {
            return ColoredBox(
              color: _OpenUpwardsPageTransition._scrimColor.withOpacity(opacityAnimation.value),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ClipRect(
                  child: SizedBox(
                    height: clipAnimation.value,
                    child: OverflowBox(
                      alignment: Alignment.bottomLeft,
                      maxHeight: size.height,
                      child: FractionalTranslation(
                        translation: secondaryTranslationAnimation.value,
                        child: FractionalTranslation(
                          translation: primaryTranslationAnimation.value,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A page transition builder that animates incoming pages by revealing them
/// from bottom to top with a clipping effect.
///
/// This transition combines several animations:
/// - A clip animation that gradually reveals the new page from bottom to top
/// - A subtle upward slide of the new page (5% translation)
/// - A slight upward movement of the old page (2.5% translation)
/// - A darkening scrim effect on the background
///
/// The resulting animation creates a layered effect where the new page appears
/// to open upward from the bottom of the screen while the previous page slides
/// back slightly.
///
/// See also:
///
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * [PredictiveBackPageTransitionsBuilder], which defines a page
///    transition that allows peeking behind the current route on Android.
///  * [FadeForwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android U.
class OpenUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Constructs a page transition animation that matches the transition used on
  /// Android P.
  const OpenUpwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _OpenUpwardsPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

// This transition slides a new page in from right to left while fading it in,
// and simultaneously slides the previous page out to the left while fading it out.
// This transition is designed to match the Android U activity transition.
class _FadeForwardsPageTransition extends StatelessWidget {
  const _FadeForwardsPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.backgroundColor,
    this.child,
  });

  final Animation<double> animation;

  final Animation<double> secondaryAnimation;

  final Color backgroundColor;

  final Widget? child;

  // The new page slides in from right to left.
  static final Animatable<Offset> _forwardTranslationTween = Tween<Offset>(
    begin: const Offset(0.25, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: FadeForwardsPageTransitionsBuilder._transitionCurve));

  // The old page slides back from left to right.
  static final Animatable<Offset> _backwardTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.25, 0.0),
  ).chain(CurveTween(curve: FadeForwardsPageTransitionsBuilder._transitionCurve));

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: FadeForwardsPageTransitionsBuilder._fadeInTransition.animate(animation),
          child: SlideTransition(
            position: _forwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder: (BuildContext context, Animation<double> animation, Widget? child) {
        return IgnorePointer(
          ignoring: animation.status == AnimationStatus.forward,
          child: FadeTransition(
            opacity: FadeForwardsPageTransitionsBuilder._fadeOutTransition.animate(animation),
            child: SlideTransition(
              position: _backwardTranslationTween.animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: FadeForwardsPageTransitionsBuilder._delegatedTransition(
        context,
        secondaryAnimation,
        backgroundColor,
        child,
      ),
    );
  }
}

/// A page transition builder that animates incoming pages by sliding and fading
/// them in from right to left.
///
/// This transition combines several animations:
/// - The new page slides in from right to left (25% horizontal translation)
/// - The new page fades in as it slides
/// - The old page slides out to the left while fading out
/// - An optional background color fills the space between transitions
///
/// The resulting animation creates a smooth horizontal transition where the new
/// page appears to push the old page off screen while both fade in and out.
///
/// {@tool dartpad}
/// This example shows how to use the fade forwards page transition.
///
/// ** See code in examples/api/lib/widgets/page_transitions_builder/page_transitions_builder.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * [PredictiveBackPageTransitionsBuilder], which defines a page
///    transition that allows peeking behind the current route on Android.
class FadeForwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Constructs a page transition animation that matches the transition used on
  /// Android U.
  const FadeForwardsPageTransitionsBuilder({required this.backgroundColor});

  /// The background color during transition between two routes.
  ///
  /// When a new page fades in and the old page fades out, this background color
  /// helps avoid a black background between two page.
  ///
  /// Defaults to black color.
  final Color backgroundColor;

  /// The value of [transitionDuration] in milliseconds.
  ///
  /// Eyeballed on a physical Pixel 9 running Android 16. This does not match
  /// the actual value used by native Android, which is 800ms, because native
  /// Android is using Material 3 Expressive springs that are not currently
  /// supported by Flutter. So for now at least, this is an approximation.
  static const int kTransitionMilliseconds = 450;

  @override
  Duration get transitionDuration => const Duration(milliseconds: kTransitionMilliseconds);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        bool allowSnapshotting,
        Widget? child,
      ) => _delegatedTransition(context, secondaryAnimation, backgroundColor, child);

  // Used by all of the sliding transition animations.
  static const Curve _transitionCurve = Curves.easeInOutCubicEmphasized;

  // The previous page slides from right to left as the current page appears.
  static final Animatable<Offset> _secondaryBackwardTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.25, 0.0),
  ).chain(CurveTween(curve: _transitionCurve));

  // The previous page slides from left to right as the current page disappears.
  static final Animatable<Offset> _secondaryForwardTranslationTween = Tween<Offset>(
    begin: const Offset(-0.25, 0.0),
    end: Offset.zero,
  ).chain(CurveTween(curve: _transitionCurve));

  // The fade in transition when the new page appears.
  static final Animatable<double> _fadeInTransition = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: const Interval(0.0, 0.75)));

  // The fade out transition of the old page when the new page appears.
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: const Interval(0.0, 0.25)));

  // The default background color, used when no transition is active.
  static const Color _defaultBackgroundColor = Color(0x00000000);

  static Widget _delegatedTransition(
    BuildContext context,
    Animation<double> secondaryAnimation,
    Color backgroundColor,
    Widget? child,
  ) {
    final Widget builder = DualTransitionBuilder(
      animation: ReverseAnimation(secondaryAnimation),
      forwardBuilder: (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: SlideTransition(
            position: _secondaryForwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder: (BuildContext context, Animation<double> animation, Widget? child) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: SlideTransition(
            position: _secondaryBackwardTranslationTween.animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );

    final bool isOpaque = ModalRoute.opaqueOf(context) ?? true;

    if (!isOpaque) {
      return builder;
    }

    return ColoredBox(
      color: secondaryAnimation.isAnimating ? backgroundColor : _defaultBackgroundColor,
      child: builder,
    );
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeForwardsPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
