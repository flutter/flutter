// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

// Fractional offset from 1/4 screen below the top to fully on screen.
final Tween<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 0.25),
  end: Offset.zero,
);

// Slides the page upwards and fades it in, starting from 1/4 screen
// below the top.
class _FadeUpwardsPageTransition extends StatelessWidget {
  _FadeUpwardsPageTransition({
    Key key,
    @required Animation<double> routeAnimation, // The route's linear 0.0 - 1.0 animation.
    @required this.child,
  }) : _positionAnimation = routeAnimation.drive(_kBottomUpTween.chain(_fastOutSlowInTween)),
       _opacityAnimation = routeAnimation.drive(_easeInTween),
       super(key: key);

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
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: child,
      ),
    );
  }
}

// This transition is intended to match the default for Android P.
class _OpenUpwardsPageTransition extends StatelessWidget {
  const _OpenUpwardsPageTransition({
    Key key,
    this.animation,
    this.secondaryAnimation,
    this.child,
  }) : super(key: key);

  // The new page slides upwards just a little as its clip
  // rectangle exposes the page from bottom to top.
  static final Tween<Offset> _primaryTranslationTween = Tween<Offset>(
    begin: const Offset(0.0, 0.05),
    end: Offset.zero,
  );

  // The old page slides downwards a little as the new page appears.
  static final Tween<Offset> _secondaryTranslationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.0, 0.025),
  );

  // The scrim obscures the old page by becoming increasingly opaque.
  static final Tween<double> _scrimOpacityTween = Tween<double>(
    begin: 0.0,
    end: 0.25,
  );

  // Used by all of the transition animations.
  static const Curve _transitionCurve = Cubic(0.20, 0.00, 0.00, 1.00);

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;

        // Gradually expose the new page from bottom to top.
        final Animation<double> clipAnimation = Tween<double>(
          begin: 0.0,
          end: size.height,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: _transitionCurve,
            reverseCurve: _transitionCurve.flipped,
          ),
        );

        final Animation<double> opacityAnimation = _scrimOpacityTween.animate(
          CurvedAnimation(
            parent: animation,
            curve: _transitionCurve,
            reverseCurve: _transitionCurve.flipped,
          ),
        );

        final Animation<Offset> primaryTranslationAnimation = _primaryTranslationTween.animate(
          CurvedAnimation(
            parent: animation,
            curve: _transitionCurve,
            reverseCurve: _transitionCurve.flipped,
          ),
        );

        final Animation<Offset> secondaryTranslationAnimation = _secondaryTranslationTween.animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: _transitionCurve,
            reverseCurve: _transitionCurve.flipped,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget child) {
            return Container(
              color: Colors.black.withOpacity(opacityAnimation.value),
              alignment: Alignment.bottomLeft,
              child: ClipRect(
                child: SizedBox(
                  height: clipAnimation.value,
                  child: OverflowBox(
                    alignment: Alignment.bottomLeft,
                    maxHeight: size.height,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: AnimatedBuilder(
            animation: secondaryAnimation,
            child: FractionalTranslation(
              translation: primaryTranslationAnimation.value,
              child: child,
            ),
            builder: (BuildContext context, Widget child) {
              return FractionalTranslation(
                translation: secondaryTranslationAnimation.value,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

/// Used by [PageTransitionsTheme] to define a [MaterialPageRoute] page
/// transition animation.
///
/// If [platform] is non-null then this transition is preferred when
/// it matches the current platform, [ThemeData.platform].
///
/// Apps can configure the list of builders for [ThemeData.platformTheme]
/// to customize the default [MaterialPageRoute] page transition animation
/// for different platforms.
///
/// See also:
///
///  * [FadeUpwardsPageTransitionsBuilder], which defines a default page transition.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
abstract class PageTransitionsBuilder {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PageTransitionsBuilder({ this.platform });

  /// The [TargetPlatform] this builder is to be used for or null if the
  /// builder is not platform-specific.
  final TargetPlatform platform;

  /// Wraps the child with one or more transition widgets which define how [route]
  /// arrives on and leaves the screen.
  ///
  /// The [MaterialPageRoute.buildTransitions] method looks up the current
  /// current [PageTransitionsTheme] with `Theme.of(context).pageTransitionsTheme`
  /// and delegates to this method with a [PageTransitionsBuilder] that has
  /// a matching [PageTransitionsBuilder.platform].
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );

  @override
  String toString() {
    return '[$runtimeType${platform == null ? "" : " for $platform"}]';
  }
}

/// Used by [PageTransitionsTheme] to define a default [MaterialPageRoute] page
/// transition animation.
///
/// The default animation fades the new page in while translating it upwards,
/// starting from about 25% below the top of the screen.
///
/// The [platform] for this builder is null which indicates that it's not
/// platform-specific.
///
/// See also:
///
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
class FadeUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Construct a FadeUpwardsPageTransitionsBuilder with a null [platform].
  const FadeUpwardsPageTransitionsBuilder() : super(platform: null);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeUpwardsPageTransition(routeAnimation: animation, child: child);
  }
}

/// Used by [PageTransitionsTheme] to define a vertical [MaterialPageRoute] page
/// transition animation that looks like the default page transition
/// used on Android P.
///
/// The [platform] for this builder [TargetPlatform.android].
///
/// See also:
///  * [FadeUpwardsPageTransitionsBuilder], which defines a default page transition.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
class OpenUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Construct a OpenUpwardsPageTransitionsBuilder with a
  /// [TargetPlatform.android] [platform].
  const OpenUpwardsPageTransitionsBuilder() : super(platform: TargetPlatform.android);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
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

/// Used by [PageTransitionsTheme] to define a horizontal [MaterialPageRoute]
/// page transition animation that matches native iOS page transitions.
///
/// The [platform] for this builder [TargetPlatform.iOS].
///
/// See also:
///
///  * [FadeUpwardsPageTransitionsBuilder], which defines a default page transition.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
class CupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Construct a CupertinoPageTransitionsBuilder with a
  /// [TargetPlatform.iOS] [platform].
  const CupertinoPageTransitionsBuilder() : super(platform: TargetPlatform.iOS);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoPageRoute.buildPageTransitions<T>(route, context, animation, secondaryAnimation, child);
  }
}

/// Defines the page transition animations used by [MaterialPageRoute]
/// for different [TargetPlatform]s.
///
/// The [MaterialPageRoute.buildTransitions] method looks up the current
/// current [PageTransitionsTheme] with `Theme.of(context).pageTransitionsTheme`
/// and delegates to [buildTransitions].
///
/// If a builder with a matching platform is not found, the first builder
/// with a null [PageTransitionsBuilder.platform] is used.
///
/// See also:
///
///  * [ThemeData.pageTransitionsTheme], which defines the default page
///    transitions for the overall theme.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a default page transition.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
@immutable
class PageTransitionsTheme extends Diagnosticable {
  /// Construct a PageTransitionsTheme.
  ///
  /// The [builders] parameter must not be null.
  ///
  /// By default the list of builders is: [FadeUpwardsPageTransitionsBuilder],
  /// [CupertinoPageTransitionsBuilder].
  const PageTransitionsTheme({
    this.builders = const <PageTransitionsBuilder>[
      FadeUpwardsPageTransitionsBuilder(),
      CupertinoPageTransitionsBuilder(),
    ],
  }) : assert(builders != null);

  /// The [PageTransitionsBuilder]s supported by this theme.
  final Iterable<PageTransitionsBuilder> builders;

  /// Delegates to the first builder in [builders] whose
  /// [PageTransitionsBuilder.platform] matches the current target
  /// platform: `Theme.of(context).platform`.
  ///
  /// If a builder with a matching platform is not found, the first
  /// builder whose platform is null is used. By default that's the
  /// [FadeUpwardsPageTransitionsBuilder].
  ///
  /// [MaterialPageRoute.builderTransitions] delegates to this method.
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    TargetPlatform platform = Theme.of(context).platform;

    if (CupertinoPageRoute.isPopGestureInProgress(route))
      platform = TargetPlatform.iOS;

    PageTransitionsBuilder matchingBuilder;
    for (PageTransitionsBuilder builder in builders) {
      if (builder.platform == platform) {
        matchingBuilder = builder;
        break;
      }
      if (builder.platform == null)
        matchingBuilder ??= builder;
    }
    assert(matchingBuilder != null);
    return matchingBuilder.buildTransitions<T>(route, context, animation, secondaryAnimation, child);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final PageTransitionsTheme typedOther = other;
    if (identical(builders, other.builders))
      return true;
    return listEquals<PageTransitionsBuilder>(builders, typedOther.builders);
  }

  @override
  int get hashCode => hashList(builders);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const PageTransitionsTheme defaultTheme = PageTransitionsTheme();
    properties.add(DiagnosticsProperty<Iterable<PageTransitionsBuilder>>('builders', builders, defaultValue: defaultTheme.builders));
  }
}
