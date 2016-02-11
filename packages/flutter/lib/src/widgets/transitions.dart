// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/animation.dart' show AnimationDirection;
export 'package:flutter/rendering.dart' show RelativeRect;

/// A component that rebuilds when the given animation changes value.
///
/// AnimatedComponent is most useful for stateless animated widgets. To use
/// AnimatedComponent, simply subclass it and implement the build function.
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder].
abstract class AnimatedComponent extends StatefulComponent {
  AnimatedComponent({
    Key key,
    this.animation
  }) : super(key: key) {
    assert(animation != null);
  }

  /// The animation to which this component is listening.
  final Animation<Object> animation;

  /// Override this function to build widgets that depend on the current value
  /// of the animation.
  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  _AnimatedComponentState createState() => new _AnimatedComponentState();

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('animation: $animation');
  }
}

class _AnimatedComponentState extends State<AnimatedComponent> {
  void initState() {
    super.initState();
    config.animation.addListener(_handleTick);
  }

  void didUpdateConfig(AnimatedComponent oldConfig) {
    if (config.animation != oldConfig.animation) {
      oldConfig.animation.removeListener(_handleTick);
      config.animation.addListener(_handleTick);
    }
  }

  void dispose() {
    config.animation.removeListener(_handleTick);
    super.dispose();
  }

  void _handleTick() {
    setState(() {
      // The animation's state is our build state, and it changed already.
    });
  }

  Widget build(BuildContext context) {
    return config.build(context);
  }
}

/// Animates the position of a widget relative to its normal position.
class SlideTransition extends AnimatedComponent {
  SlideTransition({
    Key key,
    Animation<FractionalOffset> position,
    this.transformHitTests: true,
    this.child
  }) : position = position, super(key: key, animation: position);

  /// The animation that controls the position of the child.
  ///
  /// If the current value of the position animation is (dx, dy), the child will
  /// be translated horizontally by width * dx and vertically by height * dy.
  final Animation<FractionalOffset> position;


  /// Whether hit testing should be affected by the slide animation.
  ///
  /// If false, hit testing will proceed as if the child was not translated at
  /// all. Setting this value to false is useful for fast animations where you
  /// expect the user to commonly interact with the child widget in its final
  /// location and you want the user to benefit from "muscle memory".
  final bool transformHitTests;

  final Widget child;

  Widget build(BuildContext context) {
    return new FractionalTranslation(
      translation: position.value,
      transformHitTests: transformHitTests,
      child: child
    );
  }
}

/// Animates the size of a widget.
class ScaleTransition extends AnimatedComponent {
  ScaleTransition({
    Key key,
    Animation<double> scale,
    this.alignment: const FractionalOffset(0.5, 0.5),
    this.child
  }) : scale = scale, super(key: key, animation: scale);

  /// The animation that controls the scale of the child.
  ///
  /// If the current value of the scale animation is v, the child will be
  /// painted v times its normal size.
  final Animation<double> scale;

  /// The alignment of the origin of the coordainte system in which the scale
  /// takes place, relative to the size of the box.
  ///
  /// For example, to set the origin of the scale to bottom middle, you can use
  /// an alignment of (0.5, 1.0).
  final FractionalOffset alignment;

  final Widget child;

  Widget build(BuildContext context) {
    double scaleValue = scale.value;
    Matrix4 transform = new Matrix4.identity()
      ..scale(scaleValue, scaleValue);
    return new Transform(
      transform: transform,
      alignment: alignment,
      child: child
    );
  }
}

/// Animates the rotation of a widget.
class RotationTransition extends AnimatedComponent {
  RotationTransition({
    Key key,
    Animation<double> turns,
    this.child
  }) : turns = turns, super(key: key, animation: turns);

  /// The animation that controls the rotation of the child.
  ///
  /// If the current value of the turns animation is v, the child will be
  /// rotated v * 2 * pi radians before being painted.
  final Animation<double> turns;

  final Widget child;

  Widget build(BuildContext context) {
    double turnsValue = turns.value;
    Matrix4 transform = new Matrix4.rotationZ(turnsValue * math.PI * 2.0);
    return new Transform(
      transform: transform,
      alignment: const FractionalOffset(0.5, 0.5),
      child: child
    );
  }
}

/// Animates the opacity of a widget.
class FadeTransition extends AnimatedComponent {
  FadeTransition({
    Key key,
    Animation<double> opacity,
    this.child
  }) : opacity = opacity, super(key: key, animation: opacity);

  /// The animation that controls the opacity of the child.
  ///
  /// If the current value of the opacity animation is v, the child will be
  /// painted with an opacity of v. For example, if v is 0.5, the child will be
  /// blended 50% with its background. Similarly, if v is 0.0, the child will be
  /// completely transparent.
  final Animation<double> opacity;

  final Widget child;

  Widget build(BuildContext context) {
    return new Opacity(opacity: opacity.value, child: child);
  }
}

/// An interpolation between two relative rects.
///
/// This class specializes the interpolation of Tween<RelativeRect> to be
/// appropriate for rectangles that are described in terms of offsets from
/// other rectangles.
class RelativeRectTween extends Tween<RelativeRect> {
  RelativeRectTween({ RelativeRect begin, RelativeRect end })
    : super(begin: begin, end: end);

  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t);
}

/// Animated version of [Positioned] which takes a specific
/// [Animation<RelativeRect>] to transition the child's position from a start
/// position to and end position over the lifetime of the animation.
///
/// Only works if it's the child of a [Stack].
class PositionedTransition extends AnimatedComponent {
  PositionedTransition({
    Key key,
    Animation<RelativeRect> rect,
    this.child
  }) : rect = rect, super(key: key, animation: rect) {
    assert(rect != null);
  }

  /// The animation that controls the child's size and position.
  final Animation<RelativeRect> rect;

  final Widget child;

  Widget build(BuildContext context) {
    return new Positioned(
      top: rect.value.top,
      right: rect.value.right,
      bottom: rect.value.bottom,
      left: rect.value.left,
      child: child
    );
  }
}

/// A builder that builds a widget given a child.
typedef Widget TransitionBuilder(BuildContext context, Widget child);

/// A general-purpose widget for building animations.
///
/// AnimatedBuilder is useful for more complex components that wish to include
/// an animation as part of a larger build function. To use AnimatedBuilder,
/// simply construct the widget and pass it a builder function.
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
/// For simple cases without additional state, consider using
/// [AnimatedComponent].
class AnimatedBuilder extends AnimatedComponent {
  AnimatedBuilder({
    Key key,
    Animation<Object> animation,
    this.builder,
    this.child
  }) : super(key: key, animation: animation);

  /// Called every time the animation changes value.
  final TransitionBuilder builder;

  /// If your builder function contains a subtree that does not depend on the
  /// animation, it's more efficient to build that subtree once instead of
  /// rebuilding it on every animation tick.
  ///
  /// If you pass the pre-built subtree as the [child] parameter, the
  /// AnimatedBuilder will pass it back to your builder function so that you
  /// can incorporate it into your build.
  ///
  /// Using this pre-built child is entirely optional, but can improve
  /// performance significantly in some cases and is therefore a good practice.
  final Widget child;

  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
