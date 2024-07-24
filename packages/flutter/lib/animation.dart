// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter animation system.
///
/// To use, import `package:flutter/animation.dart`.
///
/// This library provides basic building blocks for implementing animations in
/// Flutter. Other layers of the framework use these building blocks to provide
/// advanced animation support for applications. For example, the widget library
/// includes [ImplicitlyAnimatedWidget]s and [AnimatedWidget]s that make it easy
/// to animate certain properties of a [Widget]. If those animated widgets are
/// not sufficient for a given use case, the basic building blocks provided by
/// this library can be used to implement custom animated effects.
///
/// This library depends only on core Dart libraries and the `physics.dart`
/// library.
///
///
/// ### Foundations: the Animation class
///
/// Flutter represents an animation as a value that changes over a given
/// duration, and that value may be of any type. For example, it could be a
/// [double] indicating the current opacity of a [Widget] as it fades out. Or,
/// it could be the current background [Color] of a widget that transitions
/// smoothly from one color to another. The current value of an animation is
/// represented by an [Animation] object, which is the central class of the
/// animation library. In addition to the current animation value, the
/// [Animation] object also stores the current [AnimationStatus]. The status
/// indicates whether the animation is currently conceptually running from the
/// beginning to the end or the other way around. It may also indicate that the
/// animation is currently stopped at the beginning or the end.
///
/// Other objects can register listeners on an [Animation] to be informed
/// whenever the animation value and/or the animation status changes. A [Widget]
/// may register such a *value* listener via [Animation.addListener] to rebuild
/// itself with the current animation value whenever that value changes. For
/// example, a widget might listen to an animation to update its opacity to the
/// animation's value every time that value changes. Likewise, registering a
/// *status* listener via [Animation.addStatusListener] may be useful to trigger
/// another action when the current animation has ended.
///
/// As an example, the following video shows the changes over time in the
/// current animation status and animation value for the opacity animation of a
/// widget. This [Animation] is driven by an [AnimationController] (see next
/// section). Before the animation triggers, the animation status is "dismissed"
/// and the value is 0.0. As the value runs from 0.0 to 1.0 to fade in the
/// widget, the status changes to "forward". When the widget is fully faded in
/// at an animation value of 1.0 the status is "completed". When the animation
/// triggers again to fade the widget back out, the animation status changes to
/// "reverse" and the animation value runs back to 0.0. At that point the widget
/// is fully faded out and the animation status switches back to "dismissed"
/// until the animation is triggered again.
///
/// {@animation 420 100 https://flutter.github.io/assets-for-api-docs/assets/animation/animation_status_value.mp4}
///
/// Although you can't instantiate [Animation] directly (it is an abstract
/// class), you can create one using an [AnimationController].
///
///
/// ### Powering animations: AnimationController
///
/// An [AnimationController] is a special kind of [Animation] that advances its
/// animation value whenever the device running the application is ready to
/// display a new frame (typically, this rate is around 60 values per second).
/// An [AnimationController] can be used wherever an [Animation] is expected. As
/// the name implies, an [AnimationController] also provides control over its
/// [Animation]: It implements methods to stop the animation at any time and to
/// run it forward as well as in the reverse direction.
///
/// By default, an [AnimationController] increases its animation value linearly
/// over the given duration from 0.0 to 1.0 when run in the forward direction.
/// For many use cases you might want the value to be of a different type,
/// change the range of the animation values, or change how the animation moves
/// between values. This is achieved by wrapping the animation: Wrapping it in
/// an [Animatable] (see below) changes the range of animation values to a
/// different range or type (for example to animate [Color]s or [Rect]s).
/// Furthermore, a [Curve] can be applied to the animation by wrapping it in a
/// [CurvedAnimation]. Instead of linearly increasing the animation value, a
/// curved animation changes its value according to the provided curve. The
/// framework ships with many built-in curves (see [Curves]). As an example,
/// [Curves.easeOutCubic] increases the animation value quickly at the beginning
/// of the animation and then slows down until the target value is reached:
///
/// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_cubic.mp4}
///
///
/// ### Animating different types: Animatable
///
/// An `Animatable<T>` is an object that takes an `Animation<double>` as input
/// and produces a value of type `T`. Objects of these types can be used to
/// translate the animation value range of an [AnimationController] (or any
/// other [Animation] of type [double]) to a different range. That new range
/// doesn't even have to be of type double anymore. With the help of an
/// [Animatable] like a [Tween] or a [TweenSequence] (see sections below) an
/// [AnimationController] can be used to smoothly transition [Color]s, [Rect]s,
/// [Size]s and many more types from one value to another over a given duration.
///
///
/// ### Interpolating values: Tweens
///
/// A [Tween] is applied to an [Animation] of type [double] to change the
/// range and type of the animation value. For example, to transition the
/// background of a [Widget] smoothly between two [Color]s, a [ColorTween] can
/// be used. Each [Tween] specifies a start and an end value. As the animation
/// value of the [Animation] powering the [Tween] progresses from 0.0 to 1.0 it
/// produces interpolated values between its start and end value. The values
/// produced by the [Tween] usually move closer and closer to its end value as
/// the animation value of the powering [Animation] approaches 1.0.
///
/// The following video shows example values produced by an [IntTween], a
/// `Tween<double>`, and a [ColorTween] as the animation value runs from 0.0 to
/// 1.0 and back to 0.0:
///
/// {@animation 530 150 https://flutter.github.io/assets-for-api-docs/assets/animation/tweens.mp4}
///
/// An [Animation] or [AnimationController] can power multiple [Tween]s. For
/// example, to animate the size and the color of a widget in parallel, create
/// one [AnimationController] that powers a [SizeTween] and a [ColorTween].
///
/// The framework ships with many [Tween] subclasses ([IntTween], [SizeTween],
/// [RectTween], etc.) to animate common properties.
///
///
/// ### Staggered animations: TweenSequences
///
/// A [TweenSequence] can help animate a given property smoothly in stages. Each
/// [Tween] in the sequence is responsible for a different stage and has an
/// associated weight. When the animation runs, the stages execute one after
/// another. For example, let's say you want to animate the background of a
/// widget from yellow to green and then, after a short pause, to red. For this
/// you can specify three tweens within a tween sequence: One [ColorTween]
/// animating from yellow to green, one [ConstantTween] that just holds the color
/// green, and another [ColorTween] animating from green to red. For each
/// tween you need to pick a weight indicating the ratio of time spent on that
/// tween compared to all other tweens. If we assign a weight of 2 to both of
/// the [ColorTween]s and a weight of 1 to the [ConstantTween] the transition
/// described by the [ColorTween]s would take twice as long as the
/// [ConstantTween]. A [TweenSequence] is driven by an [Animation] just like a
/// regular [Tween]: As the powering [Animation] runs from 0.0 to 1.0 the
/// [TweenSequence] runs through all of its stages.
///
/// The following video shows the animation described in the previous paragraph:
///
/// {@animation 646 250 https://flutter.github.io/assets-for-api-docs/assets/animation/tween_sequence.mp4}
///
///
/// See also:
///
///  * [Introduction to animations](https://docs.flutter.dev/ui/animations)
///    on flutter.dev.
///  * [Animations tutorial](https://docs.flutter.dev/ui/animations/tutorial)
///    on flutter.dev.
///  * [Sample app](https://github.com/flutter/samples/tree/main/animations),
///    which showcases Flutter's animation features.
///  * [ImplicitlyAnimatedWidget] and its subclasses, which are [Widget]s that
///    implicitly animate changes to their properties.
///  * [AnimatedWidget] and its subclasses, which are [Widget]s that take an
///    explicit [Animation] to animate their properties.
///
/// @docImport 'package:flutter/material.dart';
library animation;

// AnimationController can throw TickerCanceled
export 'package:flutter/scheduler.dart' show TickerCanceled;

export 'src/animation/animation.dart';
export 'src/animation/animation_controller.dart';
export 'src/animation/animation_style.dart';
export 'src/animation/animations.dart';
export 'src/animation/curves.dart';
export 'src/animation/listener_helpers.dart';
export 'src/animation/tween.dart';
export 'src/animation/tween_sequence.dart';
