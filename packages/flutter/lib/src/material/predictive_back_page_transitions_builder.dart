// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'page_transitions_theme.dart';

/// Used by [PageTransitionsTheme] to define a [MaterialPageRoute] page
/// transition animation that looks like the default page transition used on
/// Android U and above when using predictive back.
///
/// When used on Android, animates along with the back gesture to reveal the
/// destination route. Can be canceled by dragging back towards the edge of the
/// screen.
///
/// See also:
///
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
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
    return _AndroidBackGestureDetector(
      predictiveBackRoute: route,
      builder: (BuildContext context) {
        // Only do a predictive back transition when the user is performing a
        // pop gesture. Otherwise, for things like button presses or other
        // programmatic navigation, fall back to ZoomPageTransitionsBuilder.
        if (route.popGestureInProgress) {
          return _PredictiveBackPageTransition(
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

class _AndroidBackGestureDetector extends StatefulWidget {
  const _AndroidBackGestureDetector({
    required this.predictiveBackRoute,
    required this.builder,
  });

  final WidgetBuilder builder;
  final PredictiveBackRoute predictiveBackRoute;

  @override
  State<_AndroidBackGestureDetector> createState() =>
      _AndroidBackGestureDetectorState();
}

class _AndroidBackGestureDetectorState extends State<_AndroidBackGestureDetector>
    with WidgetsBindingObserver {
  PredictiveBackEvent? _startBackEvent;
  bool _gestureInProgress = false;

  PredictiveBackEvent? get startBackEvent => _startBackEvent;

  PredictiveBackEvent? _currentBackEvent;
  PredictiveBackEvent? get currentBackEvent => _currentBackEvent;

  /// True when the predictive back gesture is enabled.
  bool get _isEnabled {
    return widget.predictiveBackRoute.isCurrent
        && widget.predictiveBackRoute.popGestureEnabled;
  }

  set startBackEvent(PredictiveBackEvent? startBackEvent) {
    if (_startBackEvent != startBackEvent && mounted) {
      setState(() {
        _startBackEvent = startBackEvent;
      });
    }
  }

  set currentBackEvent(PredictiveBackEvent? currentBackEvent) {
    if (_currentBackEvent != currentBackEvent && mounted) {
      setState(() {
        _currentBackEvent = currentBackEvent;
      });
    }
  }

  // Begin WidgetsBinding.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    _gestureInProgress = !backEvent.isButtonEvent && _isEnabled;
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleStartBackGesture(progress: 1 - backEvent.progress);
    startBackEvent = currentBackEvent = backEvent;
    return true;
  }

  // TODO(justinmc): Is this logic properly divided between here and PBR?
  @override
  bool handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    currentBackEvent = backEvent;
    return true;
  }

  @override
  bool handleCancelBackGesture() {
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleDragEnd(animateForward: true);
    _gestureInProgress = false;
    startBackEvent = currentBackEvent = null;
    return true;
  }

  @override
  bool handleCommitBackGesture() {
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleDragEnd(animateForward: false);
    _gestureInProgress = false;
    startBackEvent = currentBackEvent = null;
    return true;
  }

  // End WidgetsBinding.

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
    return widget.builder(context);
  }
}

/// Android's predictive back page transition.
class _PredictiveBackPageTransition extends StatelessWidget {
  const _PredictiveBackPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.getIsCurrent,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final ValueGetter<bool> getIsCurrent;
  final Widget child;

  Widget _secondaryAnimatedBuilder(BuildContext context, Widget? child) {
    final Size size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    final double xShift = (screenWidth / 20) - 8;

    final bool isCurrent = getIsCurrent();
    final Tween<double> xShiftTween = isCurrent
        ? ConstantTween<double>(0)
        : Tween<double>(begin: xShift, end: 0);
    final Animatable<double> scaleTween = isCurrent
        ? ConstantTween<double>(1)
        : TweenSequence<double>(<TweenSequenceItem<double>>[
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 0.95, end: 1), weight: 65.0),
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 1, end: 1), weight: 35.0),
          ]);
    final Animatable<double> fadeTween = isCurrent
        ? ConstantTween<double>(1)
        : TweenSequence<double>(<TweenSequenceItem<double>>[
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 1.0, end: 0.8), weight: 65.0),
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 1, end: 1), weight: 35.0),
          ]);

    return Transform.translate(
      offset: Offset(xShiftTween.animate(secondaryAnimation).value, 0),
      child: Transform.scale(
        scale: scaleTween.animate(secondaryAnimation).value,
        child: Opacity(
          opacity: fadeTween.animate(secondaryAnimation).value,
          child: child,
        ),
      ),
    );
  }

  Widget _primaryAnimatedBuilder(BuildContext context, Widget? child) {
    final Size size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    final double xShift = (screenWidth / 20) - 8;

    final Animatable<double> xShiftTween =
        TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 0.0), weight: 65.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: xShift, end: 0.0), weight: 35.0),
    ]);
    final Animatable<double> scaleTween =
        TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 1.0), weight: 65.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.95, end: 1.0), weight: 35.0),
    ]);
    final Animatable<double> fadeTween =
        TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 0.0), weight: 65.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.95, end: 1.0), weight: 35.0),
    ]);

    return Transform.translate(
      offset: Offset(xShiftTween.animate(animation).value, 0),
      child: Transform.scale(
        scale: scaleTween.animate(animation).value,
        child: Opacity(
          opacity: fadeTween.animate(animation).value,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: _secondaryAnimatedBuilder,
      child: AnimatedBuilder(
        animation: animation,
        builder: _primaryAnimatedBuilder,
        child: child,
      ),
    );
  }
}
