// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'page.dart';
library;

import 'dart:math';
import 'dart:ui' show clampDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'page_transitions_theme.dart';
import 'predictive_back_transition.dart';
import 'theme.dart';

/// Used by [PageTransitionsTheme] to define a [MaterialPageRoute] page
/// transition animation that looks like the default page transition used on
/// Android U and above when using predictive back.
///
/// Predictive back is only supported on Android U and above, and if this
/// [PageTransitionsBuilder] is used by any other platform, it will fall back to
/// [FadeForwardsPageTransitionsBuilder].
///
/// When used on Android U and above, animates along with the back gesture to
/// reveal the destination route. Can be canceled by dragging back towards the
/// edge of the screen.
///
/// See also:
///
///  * [PredictiveBackFullscreenPageTransitionsBuilder], which is another
///    variant of Android's predictive back page transitition.
///  * [FadeForwardsPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android 16.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android 10.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android 9.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android 8.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#shared-element-transition,
///    which is the Android spec for this page transition, called the Shared
///    Element page transition.
class PredictiveBackPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates an instance of a [PageTransitionsBuilder] that matches Android U's
  /// predictive back transition.
  const PredictiveBackPageTransitionsBuilder({this.backgroundColor});

  /// The background color during transition between two routes.
  ///
  /// When a new page fades in and the old page fades out, this background color
  /// helps avoid a black background between two page.
  ///
  /// Defaults to [ColorScheme.surface]
  final Color? backgroundColor;

  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        bool allowSnapshotting,
        Widget? child,
      ) {
        final ModalRoute<dynamic>? route = ModalRoute.of(context);

        if (route is PageRoute && child != null) {
          return buildTransitions(route, context, animation, secondaryAnimation, child);
        }

        return child;
      };

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool isLastPage;
    if (secondaryAnimation.isAnimating) {
      isLastPage = false;
    } else if (animation.isAnimating) {
      isLastPage = true;
    } else {
      isLastPage = route.isCurrent;
    }

    return PredictiveBackGestureBuilder(
      route: route,
      updateRouteUserGestureProgress: isLastPage,
      behavior: isLastPage
          ? PredictiveBackObserverBehavior.takeControl
          : PredictiveBackObserverBehavior.updateIfControlled,
      transitionBuilder:
          (
            BuildContext context,
            PredictiveBackPhase phase,
            PredictiveBackEvent? startBackEvent,
            PredictiveBackEvent? currentBackEvent,
            Widget child,
          ) {
            if (phase != PredictiveBackPhase.idle) {
              return _PredictiveBackSharedElementPageTransition(
                isLastPage: isLastPage,
                backgroundColor: backgroundColor,
                animation: isLastPage ? animation : secondaryAnimation,
                phase: phase,
                startBackEvent: startBackEvent,
                currentBackEvent: currentBackEvent,
                child: child,
              );
            }

            return FadeForwardsPageTransitionsBuilder(
              backgroundColor: backgroundColor,
            ).buildTransitions(route, context, animation, secondaryAnimation, child);
          },

      child: child,
    );
  }
}

/// Used by [PageTransitionsTheme] to define a [MaterialPageRoute] page
/// transition animation that looks like Android's Full Screen page transition.
///
/// Predictive back is only supported on Android U and above, and if this
/// [PageTransitionsBuilder] is used by any other platform, it will fall back to
/// [ZoomPageTransitionsBuilder].
///
/// When used on Android U and above, animates along with the back gesture to
/// reveal the destination route. Can be canceled by dragging back towards the
/// edge of the screen.
///
/// See also:
///
///  * [PredictiveBackPageTransitionsBuilder], which is the default Android
///    predictive back page transition.
///  * [FadeForwardsPageTransitionsBuilder], which defines the default page
///  transition that's similar to the one provided in Android 16.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android 10.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android 9.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android 8.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#full-screen-surfaces,
///    which is the native Android docs for this page transition.
class PredictiveBackFullscreenPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates an instance of a [PageTransitionsBuilder] that matches Android U's
  /// full screen predictive back transition.
  const PredictiveBackFullscreenPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return PredictiveBackGestureBuilder(
      route: route,
      transitionBuilder:
          (
            BuildContext context,
            PredictiveBackPhase phase,
            PredictiveBackEvent? startBackEvent,
            PredictiveBackEvent? currentBackEvent,
            Widget child,
          ) {
            // Only do a predictive back transition when the user is performing a
            // pop gesture. Otherwise, for things like button presses or other
            // programmatic navigation, fall back to ZoomPageTransitionsBuilder.
            if (route.popGestureInProgress) {
              return _PredictiveBackFullscreenPageTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                getIsCurrent: () => route.isCurrent,
                phase: phase,
                child: child,
              );
            }

            return const ZoomPageTransitionsBuilder().buildTransitions(
              route,
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
      child: child,
    );
  }
}

/// Android's predictive back page shared element transition.
///
/// See also:
///
///  * <https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#shared-element-transition>,
///    which is the Android spec for this transition.
class _PredictiveBackSharedElementPageTransition extends StatefulWidget {
  const _PredictiveBackSharedElementPageTransition({
    required this.isLastPage,
    required this.backgroundColor,
    required this.animation,
    required this.phase,
    required this.startBackEvent,
    required this.currentBackEvent,
    required this.child,
  });

  final bool isLastPage;
  final Color? backgroundColor;
  final Animation<double> animation;
  final PredictiveBackPhase phase;
  final PredictiveBackEvent? startBackEvent;
  final PredictiveBackEvent? currentBackEvent;

  final Widget child;

  @override
  State<_PredictiveBackSharedElementPageTransition> createState() =>
      _PredictiveBackSharedElementPageTransitionState();
}

class _PredictiveBackSharedElementPageTransitionState
    extends State<_PredictiveBackSharedElementPageTransition>
    with SingleTickerProviderStateMixin {
  // Ideally this would match the curvature of the physical Android device being
  // used, but that is not yet supported. Instead, this value is a best guess at
  // a value that looks reasonable on most devices.
  // See https://github.com/flutter/flutter/issues/97349.
  static const double _kDeviceBorderRadius = 32.0;

  // Since we don't know the device border radius, this provides a smooth
  // transition between the default radius and the actual radius.
  final Tween<double> _borderRadiusTween = Tween<double>(begin: 0.0, end: _kDeviceBorderRadius);

  // https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/back/DefaultCrossActivityBackAnimation.kt;l=90
  double get _closingOpacity => switch (widget.phase) {
    PredictiveBackPhase.commit => max(1 - (1 - widget.animation.value) * 5, 0),
    _ => 1.0,
  };

  final Tween<Offset> _offsetTween = Tween<Offset>(begin: const Offset(-96, 0), end: Offset.zero);

  // https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/back/CrossActivityBackAnimation.kt;l=422
  Brightness? _brightness;
  double get _maxBarrierAlpha => _brightness == Brightness.dark ? 0.8 : 0.2;
  // https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/back/CrossActivityBackAnimation.kt;l=328
  double get _barrierAlpha => switch (widget.phase) {
    PredictiveBackPhase.commit => _maxBarrierAlpha * widget.animation.value,
    _ => _maxBarrierAlpha,
  };

  // https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/back/DefaultCrossActivityBackAnimation.kt;l=111
  static const int _kCommitMilliseconds = 450;
  // Corresponds to Interpolators.EMPHASIZED
  // https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/base/libs/WindowManager/Shell/src/com/android/wm/shell/back/DefaultCrossActivityBackAnimation.kt;l=46
  static const Curve _kCurve = Curves.easeInOutCubicEmphasized;
  static const Interval _kCommitInterval = Interval(
    0.0,
    _kCommitMilliseconds / FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds,
    curve: _kCurve,
  );

  // An animation that goes from zero to a maximum of one during a predictive
  // back gesture, and then at commit, it goes from its current value to zero.
  // Used for animations that follow the gesture and then animate back to their
  // original value after commit.
  final ProxyAnimation _bounceAnimation = ProxyAnimation();
  double _lastBounceAnimationValue = 0.0;

  // An animation that stays constant at zero before the commit, and after the
  // commit goes from zero to one.
  final ProxyAnimation _commitAnimation = ProxyAnimation();

  /// The same as widget.animation but with a curve applied and reversed.
  CurvedAnimation? _curvedAnimationReversed;

  /// Curved animation used during the pre-commit (gesture-driven) phase so
  /// that the shared element transition follows the PredictiveBackSharedElementTransition.kCurve.
  CurvedAnimation? _preCommitCurvedAnimation;

  void _updateAnimations() {
    _bounceAnimation.parent = switch (widget.phase) {
      PredictiveBackPhase.commit =>
        widget.isLastPage
            ? AlwaysStoppedAnimation<double>(_lastBounceAnimationValue)
            : Tween<double>(
                begin: _lastBounceAnimationValue,
                end: 0.0,
              ).animate(_curvedAnimationReversed!),
      _ => _preCommitCurvedAnimation,
    };

    _commitAnimation.parent = switch (widget.phase) {
      PredictiveBackPhase.commit => _curvedAnimationReversed,
      _ => kAlwaysDismissedAnimation,
    };
  }

  void _updateCurvedAnimations() {
    _curvedAnimationReversed?.dispose();
    _preCommitCurvedAnimation?.dispose();
    _curvedAnimationReversed = CurvedAnimation(
      parent: ReverseAnimation(widget.animation),
      curve: _kCommitInterval,
    );
    _preCommitCurvedAnimation = CurvedAnimation(
      parent: ReverseAnimation(widget.animation),
      curve: PredictiveBackTransition.kCurve,
    );
  }

  @override
  void initState() {
    super.initState();

    _updateCurvedAnimations();
    _updateAnimations();
  }

  @override
  void didUpdateWidget(_PredictiveBackSharedElementPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animation != oldWidget.animation) {
      _updateCurvedAnimations();
    }
    if (widget.phase != oldWidget.phase && widget.phase == PredictiveBackPhase.commit) {
      _updateAnimations();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _brightness = Theme.of(context).brightness;
  }

  @override
  void dispose() {
    super.dispose();

    _curvedAnimationReversed?.dispose();
    _preCommitCurvedAnimation?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _lastBounceAnimationValue = _bounceAnimation.value;

    final Widget builder = PredictiveBackTransition(
      progress: _bounceAnimation,
      startBackEvent: widget.startBackEvent,
      currentBackEvent: widget.currentBackEvent,
      useXShift: widget.startBackEvent?.swipeEdge == SwipeEdge.left && widget.isLastPage,
      useInterpolation: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadiusTween.evaluate(_bounceAnimation)),
        child: widget.child,
      ),
    );

    if (widget.isLastPage) {
      return ColoredBox(
        color: Colors.black.withValues(alpha: _barrierAlpha),
        child: Opacity(opacity: _closingOpacity, child: builder),
      );
    }

    return ColoredBox(
      color: widget.backgroundColor ?? ColorScheme.of(context).surface,
      child: Transform.translate(offset: _offsetTween.evaluate(_commitAnimation), child: builder),
    );
  }
}

/// Android's predictive back page transition for full screen surfaces.
///
/// See also:
///
///  * <https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#full-screen-surfaces>,
///    which is the Android spec for this transition.
class _PredictiveBackFullscreenPageTransition extends StatefulWidget {
  const _PredictiveBackFullscreenPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.getIsCurrent,
    required this.phase,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final PredictiveBackPhase phase;
  final ValueGetter<bool> getIsCurrent;
  final Widget child;

  @override
  State<_PredictiveBackFullscreenPageTransition> createState() =>
      _PredictiveBackFullscreenPageTransitionState();
}

class _PredictiveBackFullscreenPageTransitionState
    extends State<_PredictiveBackFullscreenPageTransition> {
  // These values were eyeballed to match the Android spec for the Full Screen
  // page transition:
  // https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#full-screen-surfaces
  static const double _kScaleStart = 1.0;
  static const double _kScaleCommit = 0.95;
  static const double _kOpacityFullyOpened = 1.0;
  static const double _kOpacityStartTransition = 0.95;
  // The point at which the drag would cause a commit instead of a cancel if it
  // were released.
  static const double _kCommitAt = 0.65;
  static const double _kWeightPreCommit = _kCommitAt;
  static const double _kWeightPostCommit = 1 - _kWeightPreCommit;
  static const double _kScreenWidthDivisionFactor = 20.0;
  static const double _kXShiftAdjustment = 8.0;
  static const Duration _kCommitDuration = Duration(milliseconds: 100);

  final Animatable<double> _primaryOpacityTween = Tween<double>(
    begin: _kOpacityStartTransition,
    end: _kOpacityFullyOpened,
  );

  final Animatable<double> _primaryScaleTween = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: _kScaleStart, end: _kScaleStart),
      weight: _kWeightPreCommit,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: _kScaleCommit, end: _kScaleStart),
      weight: _kWeightPostCommit,
    ),
  ]);

  final ConstantTween<double> _secondaryScaleTweenCurrent = ConstantTween<double>(_kScaleStart);
  final TweenSequence<double> _secondaryTweenScale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _kScaleCommit, end: _kScaleStart),
          weight: _kWeightPreCommit,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _kScaleStart, end: _kScaleStart),
          weight: _kWeightPostCommit,
        ),
      ]);

  final ConstantTween<double> _secondaryOpacityTweenCurrent = ConstantTween<double>(
    _kOpacityFullyOpened,
  );
  final TweenSequence<double> _secondaryOpacityTween =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _kOpacityFullyOpened, end: _kOpacityStartTransition),
          weight: _kWeightPreCommit,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _kOpacityFullyOpened, end: _kOpacityFullyOpened),
          weight: _kWeightPostCommit,
        ),
      ]);

  late Animatable<Offset> _primaryPositionTween;
  late Animatable<Offset> _secondaryPositionTween;
  late Animatable<Offset> _secondaryCurrentPositionTween;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double screenWidth = MediaQuery.widthOf(context);
    final double xShift = (screenWidth / _kScreenWidthDivisionFactor) - _kXShiftAdjustment;
    _primaryPositionTween = TweenSequence<Offset>(<TweenSequenceItem<Offset>>[
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset.zero),
        weight: _kWeightPreCommit,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset(xShift, 0.0), end: Offset.zero),
        weight: _kWeightPostCommit,
      ),
    ]);

    _secondaryCurrentPositionTween = ConstantTween<Offset>(Offset.zero);
    _secondaryPositionTween = Tween<Offset>(begin: Offset(xShift, 0.0), end: Offset.zero);
  }

  Widget _secondaryAnimatedBuilder(BuildContext context, Widget? child) {
    final bool isCurrent = widget.getIsCurrent();

    return Transform.translate(
      offset: isCurrent
          ? _secondaryCurrentPositionTween.evaluate(widget.secondaryAnimation)
          : _secondaryPositionTween.evaluate(widget.secondaryAnimation),
      child: Transform.scale(
        scale: isCurrent
            ? _secondaryScaleTweenCurrent.evaluate(widget.secondaryAnimation)
            : _secondaryTweenScale.evaluate(widget.secondaryAnimation),
        child: Opacity(
          opacity: isCurrent
              ? _secondaryOpacityTweenCurrent.evaluate(widget.secondaryAnimation)
              : _secondaryOpacityTween.evaluate(widget.secondaryAnimation),
          child: child,
        ),
      ),
    );
  }

  Widget _primaryAnimatedBuilder(BuildContext context, Widget? child) {
    return Transform.translate(
      offset: _primaryPositionTween.evaluate(widget.animation),
      child: Transform.scale(
        scale: _primaryScaleTween.evaluate(widget.animation),
        // A slight change in opacity before reaching the commit point.
        child: Opacity(
          opacity: _primaryOpacityTween.evaluate(widget.animation),
          // A sudden fadeout at the commit point, driven by time and not the
          // gesture.
          child: AnimatedOpacity(
            opacity: switch (widget.phase) {
              PredictiveBackPhase.commit => 0.0,
              _ => widget.animation.value < _kCommitAt ? 0.0 : 1.0,
            },
            duration: _kCommitDuration,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.secondaryAnimation,
      builder: _secondaryAnimatedBuilder,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: _primaryAnimatedBuilder,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            _PredictiveBackSharedElementPageTransitionState._kDeviceBorderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
