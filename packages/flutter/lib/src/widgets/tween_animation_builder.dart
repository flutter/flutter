// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'framework.dart';


/// Builder callback for [TweenAnimationBuilder].
///
/// The callback is expected to return a [Widget] built with the current
/// `value` of the animation. The `child` is passed-though from the
/// [TweenAnimationBuilder] as-is and should be incorporated into the widget
/// subtree if it is non-null.
typedef TweenAnimationBuilderCallback<T> = Widget Function(BuildContext context, T value, Widget child);

/// [Widget] builder that animates a property of a [Widget] to a target value
/// whenever the target value changes.
///
/// The type of the animated property ([Color], [Rect], [double], etc.) is
/// defined via the type of the provided [tween] (e.g. [ColorTween],
/// [RectTween], [Tween<double>], etc.).
///
/// The [tween] also defines the target value for the animation: When the widget
/// first builds, it animates from [Tween.begin] to [Tween.end]. A new animation
/// can be triggered anytime by providing a new [tween] with a new [Tween.end]
/// value. The new animation runs from the current animation value (which may be
/// [Tween.end] of the old [tween], if that animation completed) to [Tween.end]
/// of the new [tween].
///
/// The animation is further customized by providing a [curve] and [duration].
///
/// The current value of the animation along with the [child] is passed to
/// the [builder] callback, which is expected to build a [Widget] based on the
/// current animation value. The [builder] is called throughout the animation
/// for every animation value until [Tween.end] is reached.
///
/// The [animationStatusListener] is informed of the current status of the
/// animation. Registering an [animationStatusListener] may be useful to trigger
/// an action (like another animation) at the end of the current animation.
///
/// See also:
///
///  * [AnimatedBuilder], which builds custom animations that are controlled
///    by a manually managed [AnimationController].
///  * [ImplicitlyAnimatedWidget], which is a base class for [Widget]s that
///    automatically animate any changes to their property values.
class TweenAnimationBuilder<T> extends ImplicitlyAnimatedWidget {
  /// Creates a [TweenAnimationBuilder].
  ///
  /// The properties [tween], [duration], and [builder] are required. The values
  /// for [tween], [curve], and [builder] must not be null.
  const TweenAnimationBuilder({
    Key key,
    @required this.tween,
    @required Duration duration,
    Curve curve = Curves.linear,
    @required this.builder,
    this.animationStatusListener,
    this.child,
  }) : assert(tween != null),
       assert(curve != null),
       assert(builder != null),
       super(key: key, duration: duration, curve: curve);

  /// Defines the target value for the animation.
  ///
  /// When the widget first builds, the animation runs from [Tween.begin] to
  /// [Tween.end], if [Tween.begin] is non-null. A new animation can be
  /// triggered at anytime by providing a new [Tween] with a new [Tween.end]
  /// value. The new animation runs from the current animation value (which may
  /// be [Tween.end] of the old [tween], if that animation completed) to
  /// [Tween.end] of the new [tween]. The [Tween.begin] value is ignored except
  /// for the initial animation that is triggered when the widget builds for the
  /// first time.
  ///
  /// Any (subclass of) [Tween] is accepted as an argument. For example, to
  /// animate the height or width of a [Widget], use a [Tween<double>], or
  /// check out the [ColorTween] to animate the color property of a [Widget].
  ///
  /// Any [Tween] provided must have a non-null [Tween.end] value.
  ///
  /// ## Ownership
  ///
  /// The [TweenAnimationBuilder] takes full ownership of the provided [Tween].
  /// Once a [Tween] instance has been passed to [TweenAnimationBuilder] its
  /// properties should not be accessed or changed anymore as they may have been
  /// modified by the [TweenAnimationBuilder]. If you need to change the
  /// [Tween], create a **new instance** with the new values.
  ///
  /// It is good practice to never store a [Tween] provided to a
  /// [TweenAnimationBuilder] in an instance variable.
  final Tween<T> tween;

  /// Called every time the animation value changes.
  ///
  /// The current animation value is passed to the builder along with the
  /// [child]. The builder should build a [Widget] based on the current
  /// animation value and incorporate the [child] into it, if it is non-null.
  final TweenAnimationBuilderCallback<T> builder;

  /// The child widget to pass to the builder.
  ///
  /// If a builder callback's return value contains a subtree that does not
  /// depend on the animation, it's more efficient to build that subtree once
  /// instead of rebuilding it on every animation tick.
  ///
  /// If the pre-built subtree is passed as the child parameter, the
  /// [TweenAnimationBuilder] will pass it back to the [builder] function so
  /// that it can be incorporated into the build.
  ///
  /// Using this pre-built child is entirely optional, but can improve
  /// performance significantly in some cases and is therefore a good practice.
  final Widget child;

  /// Called every time the [AnimationStatus] of the underlying animation
  /// changes.
  ///
  /// This can be useful to trigger additional actions (e.g. another animation)
  /// at the end of the current animation (which is signaled by
  /// [AnimationStatus.completed]).
  final AnimationStatusListener animationStatusListener;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return _TweenAnimationBuilderState<T>();
  }
}

class _TweenAnimationBuilderState<T> extends AnimatedWidgetBaseState<TweenAnimationBuilder<T>> {
  Tween<T> _currentTween;

  @override
  void initState() {
    widget.tween.begin ??= widget.tween.end;
    _currentTween = widget.tween;
    super.initState();
    if (widget.animationStatusListener != null) {
      controller.addStatusListener(widget.animationStatusListener);
    }
    if (_currentTween.begin != _currentTween.end) {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(TweenAnimationBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationStatusListener != widget.animationStatusListener) {
      if (oldWidget.animationStatusListener != null) {
        controller.removeStatusListener(oldWidget.animationStatusListener);
      }
      if (widget.animationStatusListener != null) {
        controller.addStatusListener(widget.animationStatusListener);
      }
    }
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    assert(
      widget.tween.end != null,
      'Tween provided to TweenAnimationBuilder must have non-null Tween.end value.',
    );
    _currentTween = visitor(_currentTween, widget.tween.end, (dynamic value) {
      assert(false);
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentTween.evaluate(animation), widget.child);
  }
}
