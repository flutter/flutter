// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'page.dart';
library;

import 'dart:ui' show clampDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'page_transitions_theme.dart';

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
  const PredictiveBackPageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      const Duration(milliseconds: FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PredictiveBackGestureDetector(
      route: route,
      builder:
          (
            BuildContext context,
            _PredictiveBackPhase phase,
            PredictiveBackEvent? startBackEvent,
            PredictiveBackEvent? currentBackEvent,
          ) {
            // Only do a predictive back transition when the user is performing a
            // pop gesture. Otherwise, for things like button presses or other
            // programmatic navigation, fall back to
            // FadeForwardsPageTransitionsBuilder.
            if (route.popGestureInProgress) {
              return _PredictiveBackSharedElementPageTransition(
                isDelegatedTransition: true,
                animation: animation,
                phase: phase,
                secondaryAnimation: secondaryAnimation,
                startBackEvent: startBackEvent,
                currentBackEvent: currentBackEvent,
                child: child,
              );
            }

            return const FadeForwardsPageTransitionsBuilder().buildTransitions(
              route,
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
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
    return _PredictiveBackGestureDetector(
      route: route,
      builder:
          (
            BuildContext context,
            _PredictiveBackPhase phase,
            PredictiveBackEvent? startBackEvent,
            PredictiveBackEvent? currentBackEvent,
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
    );
  }
}

typedef _PredictiveBackGestureDetectorWidgetBuilder =
    Widget Function(
      BuildContext context,
      _PredictiveBackPhase phase,
      PredictiveBackEvent? startBackEvent,
      PredictiveBackEvent? currentBackEvent,
    );

/// The phases of a predictive back gesture.
enum _PredictiveBackPhase {
  /// There is no active predictive back gesture in progress.
  idle,

  /// The user pointer has contacted the screen.
  start,

  /// The user pointer has moved.
  update,

  /// The user pointer has released in a position in which Android has
  /// determined that the back gesture is successful and the current route
  /// should be popped.
  commit,

  /// The user pointer has released in a position in which Android has
  /// determined that the back gesture should be canceled and the original route
  /// should be shown.
  cancel,
}

class _PredictiveBackGestureDetector extends StatefulWidget {
  const _PredictiveBackGestureDetector({required this.route, required this.builder});

  final _PredictiveBackGestureDetectorWidgetBuilder builder;
  final PageRoute<dynamic> route;

  @override
  State<_PredictiveBackGestureDetector> createState() => _PredictiveBackGestureDetectorState();
}

class _PredictiveBackGestureDetectorState extends State<_PredictiveBackGestureDetector>
    with WidgetsBindingObserver {
  /// True when the predictive back gesture is enabled.
  bool get _isEnabled {
    return widget.route.isCurrent && widget.route.popGestureEnabled;
  }

  _PredictiveBackPhase get phase => _phase;
  _PredictiveBackPhase _phase = _PredictiveBackPhase.idle;
  set phase(_PredictiveBackPhase phase) {
    if (_phase != phase && mounted) {
      setState(() => _phase = phase);
    }
  }

  /// The back event when the gesture first started.
  PredictiveBackEvent? get startBackEvent => _startBackEvent;
  PredictiveBackEvent? _startBackEvent;
  set startBackEvent(PredictiveBackEvent? startBackEvent) {
    if (_startBackEvent != startBackEvent && mounted) {
      setState(() => _startBackEvent = startBackEvent);
    }
  }

  /// The most recent back event during the gesture.
  PredictiveBackEvent? get currentBackEvent => _currentBackEvent;
  PredictiveBackEvent? _currentBackEvent;
  set currentBackEvent(PredictiveBackEvent? currentBackEvent) {
    if (_currentBackEvent != currentBackEvent && mounted) {
      setState(() => _currentBackEvent = currentBackEvent);
    }
  }

  // Begin WidgetsBindingObserver.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    phase = _PredictiveBackPhase.start;
    final bool gestureInProgress = !backEvent.isButtonEvent && _isEnabled;
    if (!gestureInProgress) {
      return false;
    }

    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    startBackEvent = currentBackEvent = backEvent;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    phase = _PredictiveBackPhase.update;

    widget.route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    currentBackEvent = backEvent;
  }

  @override
  void handleCancelBackGesture() {
    phase = _PredictiveBackPhase.cancel;

    widget.route.handleCancelBackGesture();
    startBackEvent = currentBackEvent = null;
  }

  @override
  void handleCommitBackGesture() {
    phase = _PredictiveBackPhase.commit;

    widget.route.handleCommitBackGesture();
    startBackEvent = currentBackEvent = null;
  }

  // End WidgetsBindingObserver.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _PredictiveBackPhase effectivePhase = widget.route.popGestureInProgress
        ? phase
        : _PredictiveBackPhase.idle;
    return widget.builder(context, effectivePhase, startBackEvent, currentBackEvent);
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
    required this.isDelegatedTransition,
    required this.animation,
    required this.secondaryAnimation,
    required this.phase,
    required this.startBackEvent,
    required this.currentBackEvent,
    required this.child,
  });

  final bool isDelegatedTransition;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final _PredictiveBackPhase phase;
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
  // Constants as per the motion specs
  // https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#motion-specs
  static const double _kMinScale = 0.90;
  static const double _kDivisionFactor = 20.0;
  static const double _kMargin = 8.0;
  static const double _kYPositionFactor = 0.1;

  // The duration of the commit transition.
  //
  // This is not the same as PredictiveBackPageTransitionsBuilder's duration,
  // which is the duration of widget.animation, so an Interval is used.
  //
  // Eyeballed on a Pixel 9 running Android 16.
  static const int _kCommitMilliseconds = 400;
  static const Curve _kCurve = Curves.easeInOutCubicEmphasized;
  static const Interval _kCommitInterval = Interval(
    0.0,
    _kCommitMilliseconds / FadeForwardsPageTransitionsBuilder.kTransitionMilliseconds,
    curve: _kCurve,
  );

  // Ideally this would match the curvature of the physical Android device being
  // used, but that is not yet supported. Instead, this value is a best guess at
  // a value that looks reasonable on most devices.
  // See https://github.com/flutter/flutter/issues/97349.
  static const double _kDeviceBorderRadius = 32.0;

  // Since we don't know the device border radius, this provides a smooth
  // transition between the default radius and the actual radius.
  final Tween<double> _borderRadiusTween = Tween<double>(begin: 0.0, end: _kDeviceBorderRadius);

  // The route fades out after commit.
  final Tween<double> _opacityTween = Tween<double>(begin: 1.0, end: 0.0);

  // The route shrinks during the gesture and animates back to normal after
  // commit.
  final Tween<double> _scaleTween = Tween<double>(begin: 1.0, end: _kMinScale);

  // An animation that stays constant at zero before the commit, and after the
  // commit goes from zero to one.
  final ProxyAnimation _commitAnimation = ProxyAnimation();

  // An animation that goes from zero to a maximum of one during a predictive
  // back gesture, and then at commit, it goes from its current value to zero.
  // Used for animations that follow the gesture and then animate back to their
  // original value after commit.
  final ProxyAnimation _bounceAnimation = ProxyAnimation();
  double _lastBounceAnimationValue = 0.0;

  // An animation that proxies to widget.animation during the gesture and then
  // to _commitAnimation after the commit. So, it goes from zero to a maximum of
  // one before commit, and then after commit goes from zero to one again.
  final ProxyAnimation _animation = ProxyAnimation();

  /// The same as widget.animation but with a curve applied.
  CurvedAnimation? _curvedAnimation;

  /// The reverse of _curvedAnimation.
  CurvedAnimation? _curvedAnimationReversed;

  late Animation<Offset> _positionAnimation;

  Offset _lastDrag = Offset.zero;

  // This isn't done as an animation because it's based on the vertical drag
  // amount, not the progression of the back gesture like widget.animation is.
  double _getYShiftPosition(double screenHeight) {
    final double startTouchY = widget.startBackEvent?.touchOffset?.dy ?? 0;
    final double currentTouchY = widget.currentBackEvent?.touchOffset?.dy ?? 0;

    final double yShiftMax = (screenHeight / _kDivisionFactor) - _kMargin;

    final double rawYShift = currentTouchY - startTouchY;
    final double easedYShift =
        // This curve was eyeballed on a Pixel 9 running Android 16.
        Curves.easeOut.transform(clampDouble(rawYShift.abs() / screenHeight, 0.0, 1.0)) *
        rawYShift.sign *
        yShiftMax;

    return clampDouble(easedYShift, -yShiftMax, yShiftMax);
  }

  void _updateAnimations(Size screenSize) {
    _animation.parent = switch (widget.phase) {
      _PredictiveBackPhase.commit => _curvedAnimationReversed,
      _ => widget.animation,
    };

    _bounceAnimation.parent = switch (widget.phase) {
      _PredictiveBackPhase.commit => Tween<double>(
        begin: 0.0,
        end: _lastBounceAnimationValue,
      ).animate(_curvedAnimation!),
      _ => ReverseAnimation(widget.animation),
    };

    _commitAnimation.parent = switch (widget.phase) {
      _PredictiveBackPhase.commit => _animation,
      _ => kAlwaysDismissedAnimation,
    };

    final double xShift = (screenSize.width / _kDivisionFactor) - _kMargin;
    _positionAnimation = _animation.drive(switch (widget.phase) {
      _PredictiveBackPhase.commit => Tween<Offset>(
        begin: _lastDrag,
        end: Offset(screenSize.height * _kYPositionFactor, 0.0),
      ),
      _ => Tween<Offset>(
        // The y position before commit is given by the vertical drag, not by an
        // animation.
        begin: switch (widget.currentBackEvent?.swipeEdge) {
          SwipeEdge.left => Offset(xShift, _getYShiftPosition(screenSize.height)),
          SwipeEdge.right => Offset(-xShift, _getYShiftPosition(screenSize.height)),
          null => Offset(xShift, _getYShiftPosition(screenSize.height)),
        },
        end: Offset.zero,
      ),
    });
  }

  void _updateCurvedAnimations() {
    _curvedAnimation?.dispose();
    _curvedAnimationReversed?.dispose();
    _curvedAnimation = CurvedAnimation(parent: widget.animation, curve: _kCommitInterval);
    _curvedAnimationReversed = CurvedAnimation(
      parent: ReverseAnimation(widget.animation),
      curve: _kCommitInterval,
    );
  }

  // TODO(justinmc): Should have a delegatedTransition to animate the incoming
  // route regardless of its page transition.
  // https://github.com/flutter/flutter/issues/153577

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(_PredictiveBackSharedElementPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animation != oldWidget.animation) {
      _updateCurvedAnimations();
    }
    if (widget.phase != oldWidget.phase && widget.phase == _PredictiveBackPhase.commit) {
      _updateAnimations(MediaQuery.sizeOf(context));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurvedAnimations();
    _updateAnimations(MediaQuery.sizeOf(context));
  }

  @override
  void dispose() {
    _curvedAnimation!.dispose();
    _curvedAnimationReversed!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (BuildContext context, Widget? child) {
        _lastBounceAnimationValue = _bounceAnimation.value;
        return Transform.scale(
          scale: _scaleTween.evaluate(_bounceAnimation),
          child: Transform.translate(
            offset: switch (widget.phase) {
              _PredictiveBackPhase.commit => _positionAnimation.value,
              _ => _lastDrag = Offset(
                _positionAnimation.value.dx,
                _getYShiftPosition(MediaQuery.heightOf(context)),
              ),
            },
            child: Opacity(
              opacity: _opacityTween.evaluate(_commitAnimation),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_borderRadiusTween.evaluate(_bounceAnimation)),
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
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
  final _PredictiveBackPhase phase;
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
              _PredictiveBackPhase.commit => 0.0,
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
