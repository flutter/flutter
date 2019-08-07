// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'framework.dart';

// ignore_for_file: public_member_api_docs

typedef TweenAnimationBuilderCallback<T> = Widget Function(BuildContext context, T value, Widget child);


enum PlaybackDirection {
  forward,
  reverse,
  repeat,
  repeatReverse,
}

class TweenAnimationBuilder<T> extends StatefulWidget {
  const TweenAnimationBuilder({
    Key key,
    @required this.tween,
    @required this.duration,
    this.curve = Curves.linear,
    this.direction = PlaybackDirection.forward,
    this.gapless = true,
    @required this.builder,
    this.animationStatusListener,
    this.child,
  }) : assert(tween != null),
       assert(direction != null),
       assert(curve != null),
       assert(direction != null),
       assert(builder != null),
       assert(gapless != null),
       super(key: key);

  final Tween<T> tween;
  final Duration duration;
  final Curve curve;
  final PlaybackDirection direction;
  final TweenAnimationBuilderCallback<T> builder;
  final Widget child;
  final AnimationStatusListener animationStatusListener;
  final bool gapless;

  @override
  State<TweenAnimationBuilder<T>> createState() => _TweenAnimationBuilderState<T>();
}

class _TweenAnimationBuilderState<T> extends State<TweenAnimationBuilder<T>> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<T> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
    ..addListener(() {
      setState(() { });
    });
    if (widget.animationStatusListener != null) {
      _controller.addStatusListener(widget.animationStatusListener);
    }
    _animation = widget.tween.chain(CurveTween(curve: widget.curve)).animate(_controller);
    _updateDirection();
  }

  T _cachedBegin;
  T _cachedEnd;

  @override
  void didUpdateWidget(TweenAnimationBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    if (oldWidget.animationStatusListener != widget.animationStatusListener) {
      if (oldWidget.animationStatusListener != null) {
        _controller.removeStatusListener(oldWidget.animationStatusListener);
      }
      if (widget.animationStatusListener != null) {
        _controller.addStatusListener(widget.animationStatusListener);
      }
    }

    final T currentAnimationValue = _animation.value;

    final bool hasStatusListener = _cachedEnd != null || _cachedBegin != null;
    if (identical(oldWidget.tween, widget.tween)) {
      if (_cachedBegin != null) {
        widget.tween.begin = _cachedBegin;
      }
      if (_cachedEnd != null) {
        widget.tween.end = _cachedEnd;
      }
    }
    _cachedEnd = null;
    _cachedBegin = null;

    final bool tweenChanged = oldWidget.tween != widget.tween;

    if (widget.gapless) {
      _updateTween(currentAnimationValue);
    }

    if (!identical(oldWidget.tween, widget.tween) || oldWidget.curve != widget.curve) {
      _updateAnimation();
    }

    if (_tweenIsAnimatable && (oldWidget.direction != widget.direction || tweenChanged)) {
      _updateDirection();
    }

    final bool shouldHaveStatusListener = _cachedEnd != null || _cachedBegin != null;
    if (hasStatusListener != shouldHaveStatusListener) {
      if (hasStatusListener) {
        _controller.removeStatusListener(_resetTweenWhenAnimationIsDone);
      } else {
        _controller.addStatusListener(_resetTweenWhenAnimationIsDone);
      }
    }
  }

  void _resetTweenWhenAnimationIsDone(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        if (_cachedEnd != null) {
          widget.tween.end = _cachedEnd;
          _cachedEnd = null;
        }
        break;
      case AnimationStatus.completed:
        if (_cachedBegin != null) {
          widget.tween.begin = _cachedBegin;
          _cachedBegin = null;
        }
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        // Nothing to do.
        break;
    }
    if (_cachedEnd == null && _cachedBegin == null) {
      _controller.removeStatusListener(_resetTweenWhenAnimationIsDone);
    }
  }

  void _updateTween(T currentAnimationValue) {
    assert(widget.gapless);
    switch (widget.direction) {
      case PlaybackDirection.repeatReverse:
      // Ideally, we would set begin to the currentValue when the animation
      // is running forward, and end to the currentValue when the animation
      // is running in reverse. However, since [AnimationController.repeat]
      // starts a simulation and simulations always run forward,
      // we cannot differentiate between the two cases. Therefore, we just
      // fallthrough here to the forward case.
      case PlaybackDirection.repeat:
      case PlaybackDirection.forward:
        if (widget.tween.begin != currentAnimationValue) {
          assert(_cachedBegin == null);
          _cachedBegin = widget.tween.begin;
          widget.tween.begin = currentAnimationValue;
          _controller.value = 0.0;
        }
        break;
      case PlaybackDirection.reverse:
        if (widget.tween.end != currentAnimationValue) {
          assert(_cachedEnd == null);
          _cachedEnd = widget.tween.end;
          widget.tween.end = currentAnimationValue;
          _controller.value = 1.0;
        }
        break;
    }
  }

  void _updateAnimation() {
    _animation = widget.tween.chain(CurveTween(curve: widget.curve)).animate(_controller);
  }

  void _updateDirection() {
    assert(_tweenIsAnimatable);
    switch (widget.direction) {
      case PlaybackDirection.forward:
        _controller.value = 0.0;
        _controller.forward();
        break;
      case PlaybackDirection.reverse:
        _controller.value = 1.0;
        _controller.reverse();
        break;
      case PlaybackDirection.repeat:
        _controller.value = 0.0;
        _controller.repeat();
        break;
      case PlaybackDirection.repeatReverse:
        _controller.value = 0.0;
        _controller.repeat(reverse: true);
        break;
    }
  }

  bool get _tweenIsAnimatable => widget.tween.begin != widget.tween.end;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animation.value, widget.child);
  }
}
