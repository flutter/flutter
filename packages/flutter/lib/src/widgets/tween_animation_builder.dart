// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/foundation.dart';
/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'animated_size.dart';
/// @docImport 'transitions.dart';
library;

import 'package:flutter/animation.dart';

import 'framework.dart';
import 'implicit_animations.dart';
import 'value_listenable_builder.dart';

/// [Widget] builder that animates a property of a [Widget] to a target value
/// whenever the target value changes.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=l9uHB8VXZOg}
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
/// A provided [onEnd] callback is called whenever an animation completes.
/// Registering an [onEnd] callback my be useful to trigger an action (like
/// another animation) at the end of the current animation.
///
/// ## Performance optimizations
///
/// If your [builder] function contains a subtree that does not depend on the
/// animation, it's more efficient to build that subtree once instead of
/// rebuilding it on every animation tick.
///
/// If you pass the pre-built subtree as the [child] parameter, the
/// AnimatedBuilder will pass it back to your builder function so that you
/// can incorporate it into your build.
///
/// Using this pre-built child is entirely optional, but can improve
/// performance significantly in some cases and is therefore a good practice.
///
/// ## Ownership of the [Tween]
///
/// The [TweenAnimationBuilder] takes full ownership of the provided [tween]
/// instance and it will mutate it. Once a [Tween] has been passed to a
/// [TweenAnimationBuilder], its properties should not be accessed or changed
/// anymore to avoid interference with the [TweenAnimationBuilder].
///
/// It is good practice to never store a [Tween] provided to a
/// [TweenAnimationBuilder] in an instance variable to avoid accidental
/// modifications of the [Tween].
///
/// ## Example Code
///
/// {@tool dartpad}
/// This example shows an [IconButton] that "zooms" in when the widget first
/// builds (its size smoothly increases from 0 to 24) and whenever the button
/// is pressed, it smoothly changes its size to the new target value of either
/// 48 or 24.
///
/// ** See code in examples/api/lib/widgets/tween_animation_builder/tween_animation_builder.0.dart **
/// {@end-tool}
///
/// ## Relationship to [ImplicitlyAnimatedWidget]s and [AnimatedWidget]s
///
/// The [ImplicitlyAnimatedWidget] has many subclasses that provide animated
/// versions of regular widgets. These subclasses (like [AnimatedOpacity],
/// [AnimatedContainer], [AnimatedSize], etc.) animate changes in their
/// properties smoothly and they are easier to use than this general-purpose
/// builder. However, [TweenAnimationBuilder] (which itself is a subclass of
/// [ImplicitlyAnimatedWidget]) is handy for animating any widget property to a
/// given target value even when the framework (or third-party widget library)
/// doesn't ship with an animated version of that widget.
///
/// Those [ImplicitlyAnimatedWidget]s (including this [TweenAnimationBuilder])
/// all manage an internal [AnimationController] to drive the animation. If you
/// want more control over the animation than just setting a target value,
/// [duration], and [curve], have a look at (subclasses of) [AnimatedWidget]s.
/// For those, you have to manually manage an [AnimationController] giving you
/// full control over the animation. An example of an [AnimatedWidget] is the
/// [AnimatedBuilder], which can be used similarly to this
/// [TweenAnimationBuilder], but unlike the latter it is powered by a
/// developer-managed [AnimationController].
///
/// See also:
///
/// * [ValueListenableBuilder], a widget whose content stays synced with a
///   [ValueListenable] instead of a [Tween].
class TweenAnimationBuilder<T extends Object?> extends ImplicitlyAnimatedWidget {
  /// Creates a [TweenAnimationBuilder].
  ///
  /// The [TweenAnimationBuilder] takes full ownership of the provided [tween]
  /// instance and mutates it. Once a [Tween] has been passed to a
  /// [TweenAnimationBuilder], its properties should not be accessed or changed
  /// anymore to avoid interference with the [TweenAnimationBuilder].
  const TweenAnimationBuilder({
    super.key,
    required this.tween,
    required super.duration,
    super.curve,
    required this.builder,
    super.onEnd,
    this.child,
  }) : _isRepeating = false,
       _reverse = false,
       _paused = false;

  /// Creates a [TweenAnimationBuilder] that repeats its animation.
  ///
  /// The animation continuously cycles, restarting from [tween.begin] each time
  /// it reaches [tween.end]. This is useful for creating animations that need to
  /// run indefinitely, such as loading spinners, pulsing effects, or continuous
  /// rotations.
  ///
  /// {@template flutter.widgets.TweenAnimationBuilder.repeat.reverse}
  /// The [reverse] parameter controls the animation direction:
  ///  * When `false` (default), the animation repeats in one direction, jumping
  ///    back to the beginning when it completes.
  ///  * When `true`, the animation reverses direction when it reaches the end,
  ///    creating a back-and-forth motion.
  /// {@endtemplate}
  ///
  /// {@template flutter.widgets.TweenAnimationBuilder.repeat.paused}
  /// The [paused] parameter controls whether the animation is running:
  ///  * When `false` (default), the animation runs continuously.
  ///  * When `true`, the animation pauses at its current value.
  ///  * Changing from `true` to `false` resumes the animation from where it paused.
  /// {@endtemplate}
  ///
  /// Unlike the default constructor, [onEnd] is not supported for repeating
  /// animations since they never end.
  ///
  /// {@tool snippet}
  /// This example shows a spinning square that rotates continuously:
  ///
  /// ```dart
  /// TweenAnimationBuilder<double>.repeat(
  ///   tween: Tween<double>(begin: 0, end: 1),
  ///   duration: const Duration(seconds: 2),
  ///   builder: (BuildContext context, double value, Widget? child) {
  ///     return Transform.rotate(
  ///       angle: value * 2 * math.pi,
  ///       child: Container(
  ///         width: 100,
  ///         height: 100,
  ///         color: Colors.green,
  ///       ),
  ///     );
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// This example shows a pulsing effect using the [reverse] parameter:
  ///
  /// ```dart
  /// TweenAnimationBuilder<double>.repeat(
  ///   tween: Tween<double>(begin: 0.8, end: 1.2),
  ///   duration: const Duration(seconds: 1),
  ///   reverse: true,
  ///   builder: (BuildContext context, double value, Widget? child) {
  ///     return Transform.scale(
  ///       scale: value,
  ///       child: child,
  ///     );
  ///   },
  ///   child: const Icon(Icons.favorite, color: Colors.red, size: 100),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [AnimationController.repeat], which this constructor replaces for simple use cases.
  ///  * [TweenAnimationBuilder], the default constructor for single animations.
  ///
  /// ## Ownership
  ///
  /// The [TweenAnimationBuilder] takes full ownership of the provided [tween]
  /// instance and mutates it. Once a [Tween] has been passed to a
  /// [TweenAnimationBuilder], its properties should not be accessed or changed
  /// anymore to avoid interference with the [TweenAnimationBuilder].
  const TweenAnimationBuilder.repeat({
    super.key,
    required this.tween,
    required super.duration,
    super.curve = Curves.linear,
    bool reverse = false,
    bool paused = false,
    required this.builder,
    this.child,
  }) : _isRepeating = true,
       _reverse = reverse,
       _paused = paused,
       super(onEnd: null);

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
  /// The [TweenAnimationBuilder] takes full ownership of the provided [Tween]
  /// and it will mutate the [Tween]. Once a [Tween] instance has been passed
  /// to [TweenAnimationBuilder] its properties should not be accessed or
  /// changed anymore to avoid any interference with the
  /// [TweenAnimationBuilder]. If you need to change the [Tween], create a
  /// **new instance** with the new values.
  ///
  /// It is good practice to never store a [Tween] provided to a
  /// [TweenAnimationBuilder] in an instance variable to avoid accidental
  /// modifications of the [Tween].
  final Tween<T> tween;

  /// Called every time the animation value changes.
  ///
  /// The current animation value is passed to the builder along with the
  /// [child]. The builder should build a [Widget] based on the current
  /// animation value and incorporate the [child] into it, if it is non-null.
  final ValueWidgetBuilder<T> builder;

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
  final Widget? child;

  /// Whether this [TweenAnimationBuilder] is configured to repeat.
  ///
  /// When true, the widget uses [_RepeatingTweenAnimationBuilderState] which
  /// implements repeating animation behavior. When false, it uses the standard
  /// [_TweenAnimationBuilderState] for single animations.
  ///
  /// This is set to true when using [TweenAnimationBuilder.repeat] constructor
  /// and false when using the default constructor.
  final bool _isRepeating;

  /// Whether the repeating animation should reverse direction.
  ///
  /// When true, the animation alternates between playing forward
  /// (from [tween.begin] to [tween.end]) and backward (from [tween.end]
  /// to [tween.begin]).
  ///
  /// This value is only used when [_isRepeating] is true.
  ///
  /// For example, with a [Tween<double>] from 0.0 to 1.0:
  ///  * When false: animates 0.0 → 1.0, 0.0 → 1.0, 0.0 → 1.0, ...
  ///  * When true: animates 0.0 → 1.0 → 0.0 → 1.0 → 0.0 → ...
  ///
  /// Defaults to false in [TweenAnimationBuilder.repeat].
  final bool _reverse;

  /// Whether the repeating animation is currently paused.
  ///
  /// When true, the animation stops at its current value and does not progress.
  /// When changed from true to false, the animation resumes from where it was paused.
  ///
  /// This value is only used when [_isRepeating] is true.
  ///
  /// This is useful for scenarios where you want to conditionally run an animation,
  /// such as:
  ///  * A loading spinner that only animates when data is being fetched
  ///  * A progress indicator that pauses when a process is complete
  ///  * An attention-grabbing animation that stops when the user interacts
  ///
  /// Defaults to false in [TweenAnimationBuilder.repeat].
  final bool _paused;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return _isRepeating
        ? _RepeatingTweenAnimationBuilderState<T>()
        : _TweenAnimationBuilderState<T>();
  }
}

class _TweenAnimationBuilderState<T extends Object?>
    extends AnimatedWidgetBaseState<TweenAnimationBuilder<T>> {
  Tween<T>? _currentTween;

  @override
  void initState() {
    _currentTween = widget.tween;
    _currentTween!.begin ??= _currentTween!.end;
    super.initState();
    if (_currentTween!.begin != _currentTween!.end) {
      controller.forward();
    }
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    assert(
      widget.tween.end != null,
      'Tween provided to TweenAnimationBuilder must have non-null Tween.end value.',
    );
    _currentTween =
        visitor(_currentTween, widget.tween.end, (dynamic value) {
              assert(false);
              throw StateError(
                'Constructor will never be called because null is never provided as current tween.',
              );
            })
            as Tween<T>?;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentTween!.evaluate(animation), widget.child);
  }
}

class _RepeatingTweenAnimationBuilderState<T extends Object?>
    extends AnimatedWidgetBaseState<TweenAnimationBuilder<T>> {
  Tween<T>? _currentTween;

  @override
  void initState() {
    _currentTween = widget.tween;
    _currentTween!.begin ??= _currentTween!.end;
    super.initState();
    // After parent initialization, reset to begin value and start repeating
    if (!widget._paused && _currentTween!.begin != _currentTween!.end) {
      // Reset the controller to the beginning value to match AnimationController.repeat() behavior
      controller.value = 0.0;
      if (widget._reverse) {
        controller.repeat(reverse: true);
      } else {
        controller.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(TweenAnimationBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._paused != oldWidget._paused || widget._reverse != oldWidget._reverse) {
      if (widget._paused) {
        controller.stop();
      } else if (_currentTween!.begin != _currentTween!.end) {
        if (widget._reverse) {
          controller.repeat(reverse: true);
        } else {
          controller.repeat();
        }
      }
    }
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    assert(
      widget.tween.end != null,
      'Tween provided to TweenAnimationBuilder.repeat must have non-null Tween.end value.',
    );
    _currentTween =
        visitor(_currentTween, widget.tween.end, (dynamic value) {
              assert(false);
              throw StateError(
                'Constructor will never be called because null is never provided as current tween.',
              );
            })
            as Tween<T>?;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentTween!.evaluate(animation), widget.child);
  }
}
