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
/// [ZoomPageTransitionsBuilder].
///
/// When used on Android U and above, animates along with the back gesture to
/// reveal the destination route. Can be canceled by dragging back towards the
/// edge of the screen.
///
/// See also:
///
///  * [PredictiveBackFullscreenPageTransitionsBuilder], which is another
///    variant of Android's predictive back page transitition.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
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
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PredictiveBackGestureDetector(
      route: route,
      builder: (
        BuildContext context,
        _PredictiveBackPhase phase,
        PredictiveBackEvent? startBackEvent,
        PredictiveBackEvent? currentBackEvent,
      ) {
        // Only do a predictive back transition when the user is performing a
        // pop gesture. Otherwise, for things like button presses or other
        // programmatic navigation, fall back to ZoomPageTransitionsBuilder.
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
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
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
      builder: (
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

enum _PredictiveBackPhase { idle, start, update, commit, cancel }

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
    final _PredictiveBackPhase effectivePhase =
        widget.route.popGestureInProgress ? phase : _PredictiveBackPhase.idle;
    return widget.builder(context, effectivePhase, startBackEvent, currentBackEvent);
  }
}

// TODO(justinmc): Bug: Do two backs back to back really fast.
/// Android's predictive back page shared element transition.
/// https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#shared-element-transition
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

  // Ideally this would match the curvature of the physical Android device being
  // used, but that is not yet supported. Instead, this value is a best guess at
  // a value that looks reasonable on most devices.
  // See https://github.com/flutter/flutter/issues/97349.
  static const double _kDeviceBorderRadius = 32.0;

  // Eyeballed on a Pixel 9 running Android 16.
  static const int _kCommitMilliseconds = 100;

  // Since we don't know the device border radius, this provides a smooth
  // transition between the default radius and the actual radius.
  final Tween<double> _borderRadiusTween = Tween<double>(begin: _kDeviceBorderRadius, end: 0.0);

  final Tween<double> _gapTween = Tween<double>(begin: _kMargin, end: 0.0);
  final Tween<double> _scaleTween = Tween<double>(begin: _kMinScale, end: 1.0);
  final Tween<double> _opacityTween = Tween<double>(begin: 1.0, end: 0.0);

  late final AnimationController _commitController;
  late final Animation<double> _commitAnimation;
  late final Listenable _mergedAnimations;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late Animation<double> _scaleCommitAnimation;
  late Animation<double> _xAnimation;
  late Animation<Offset> _positionCommitAnimation;

  double _lastXDrag = 0.0;
  double _lastYDrag = 0.0;
  double _lastScale = 1.0;

  // This isn't done as an animation because it's based on the vertical drag
  // amount, not the progression of the back gesture like widget.animation is.
  double _getYPosition(double screenHeight) {
    final double startTouchY = widget.startBackEvent?.touchOffset?.dy ?? 0;
    final double currentTouchY = widget.currentBackEvent?.touchOffset?.dy ?? 0;

    final double yShiftMax = (screenHeight / _kDivisionFactor) - _kMargin;

    final double rawYShift = currentTouchY - startTouchY;
    final double easedYShift =
        Curves.easeOut.transform(clampDouble(rawYShift.abs() / screenHeight, 0.0, 1.0)) *
        rawYShift.sign *
        yShiftMax;

    return clampDouble(easedYShift, -yShiftMax, yShiftMax);
  }

  Animation<Offset> _getCommitPositionAnimation(double screenWidth) {
    return Tween<Offset>(
      begin: Offset(_lastXDrag, _lastYDrag),
      end: Offset(screenWidth * _kYPositionFactor, 0.0),
    ).animate(_commitAnimation);
  }

  // TODO(justinmc): Should have a delegatedTransition to animate the incoming
  // route regardless of its page transition.
  // https://github.com/flutter/flutter/issues/153577

  @override
  void initState() {
    super.initState();

    _commitController = AnimationController(
      duration: const Duration(milliseconds: _kCommitMilliseconds),
      vsync: this,
    );
    _commitAnimation = CurvedAnimation(parent: _commitController, curve: Curves.easeOut);
    _mergedAnimations = Listenable.merge(<Listenable>[widget.animation, _commitAnimation]);
    _opacityAnimation = _opacityTween.animate(_commitAnimation);
    _scaleAnimation = _scaleTween.animate(widget.animation);
    _scaleCommitAnimation = Tween<double>(begin: _lastScale, end: 1.0).animate(_commitAnimation);

    if (widget.phase == _PredictiveBackPhase.commit) {
      _commitController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(_PredictiveBackSharedElementPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.phase != oldWidget.phase && widget.phase == _PredictiveBackPhase.commit) {
      _commitController.forward(from: 0.0);
      _scaleCommitAnimation = Tween<double>(begin: _lastScale, end: 1.0).animate(_commitAnimation);
      final double screenWidth = MediaQuery.sizeOf(context).width;
      _positionCommitAnimation = _getCommitPositionAnimation(screenWidth);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final double xShift = (screenWidth / _kDivisionFactor) - _kMargin;
    _xAnimation = Tween<double>(
      begin: switch (widget.currentBackEvent?.swipeEdge) {
        SwipeEdge.left => xShift,
        SwipeEdge.right => -xShift,
        null => xShift,
      },
      end: 0.0,
    ).animate(widget.animation);

    _positionCommitAnimation = _getCommitPositionAnimation(screenWidth);
  }

  @override
  void dispose() {
    _commitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mergedAnimations,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: switch (widget.phase) {
            _PredictiveBackPhase.commit => _scaleCommitAnimation.value,
            _ => _lastScale = _scaleAnimation.value,
          },
          child: Transform.translate(
            offset: switch (widget.phase) {
              _PredictiveBackPhase.commit => _positionCommitAnimation.value,
              _ => Offset(
                _lastXDrag = _xAnimation.value,
                _lastYDrag = _getYPosition(MediaQuery.sizeOf(context).height),
              ),
            },
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _gapTween.evaluate(widget.animation)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    _borderRadiusTween.evaluate(widget.animation),
                  ),
                  child: child,
                ),
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
/// https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back#full-screen-surfaces
class _PredictiveBackFullscreenPageTransition extends StatefulWidget {
  const _PredictiveBackFullscreenPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.getIsCurrent,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
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
  static const double _scaleStart = 1.0;
  static const double _scaleCommit = 0.95;
  static const double _opacityFullyOpened = 1.0;
  static const double _opacityStartTransition = 0.95;
  static const double _commitAt = 0.65;
  static const double _weightPreCommit = _commitAt;
  static const double _weightPostCommit = 1 - _weightPreCommit;
  static const double _screenWidthDivisionFactor = 20.0;
  static const double _xShiftAdjustment = 8.0;
  static const Duration _commitDuration = Duration(milliseconds: 100);

  final Animatable<double> _primaryOpacityTween = Tween<double>(
    begin: _opacityStartTransition,
    end: _opacityFullyOpened,
  );

  final Animatable<double> _primaryScaleTween = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: _scaleStart, end: _scaleStart),
      weight: _weightPreCommit,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: _scaleCommit, end: _scaleStart),
      weight: _weightPostCommit,
    ),
  ]);

  final ConstantTween<double> _secondaryScaleTweenCurrent = ConstantTween<double>(_scaleStart);
  final TweenSequence<double> _secondaryTweenScale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _scaleCommit, end: _scaleStart),
          weight: _weightPreCommit,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _scaleStart, end: _scaleStart),
          weight: _weightPostCommit,
        ),
      ]);

  final ConstantTween<double> _secondaryOpacityTweenCurrent = ConstantTween<double>(
    _opacityFullyOpened,
  );
  final TweenSequence<double> _secondaryOpacityTween =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _opacityFullyOpened, end: _opacityStartTransition),
          weight: _weightPreCommit,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: _opacityFullyOpened, end: _opacityFullyOpened),
          weight: _weightPostCommit,
        ),
      ]);

  late Animatable<Offset> _primaryPositionTween;
  late Animatable<Offset> _secondaryPositionTween;
  late Animatable<Offset> _secondaryCurrentPositionTween;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double xShift = (screenWidth / _screenWidthDivisionFactor) - _xShiftAdjustment;
    _primaryPositionTween = TweenSequence<Offset>(<TweenSequenceItem<Offset>>[
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset.zero),
        weight: _weightPreCommit,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset(xShift, 0.0), end: Offset.zero),
        weight: _weightPostCommit,
      ),
    ]);

    _secondaryCurrentPositionTween = ConstantTween<Offset>(Offset.zero);
    _secondaryPositionTween = Tween<Offset>(begin: Offset(xShift, 0.0), end: Offset.zero);
  }

  Widget _secondaryAnimatedBuilder(BuildContext context, Widget? child) {
    final bool isCurrent = widget.getIsCurrent();

    return Transform.translate(
      offset:
          isCurrent
              ? _secondaryCurrentPositionTween.evaluate(widget.secondaryAnimation)
              : _secondaryPositionTween.evaluate(widget.secondaryAnimation),
      child: Transform.scale(
        scale:
            isCurrent
                ? _secondaryScaleTweenCurrent.evaluate(widget.secondaryAnimation)
                : _secondaryTweenScale.evaluate(widget.secondaryAnimation),
        child: Opacity(
          opacity:
              isCurrent
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
            opacity: widget.animation.value < _commitAt ? 0.0 : 1.0,
            duration: _commitDuration,
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
