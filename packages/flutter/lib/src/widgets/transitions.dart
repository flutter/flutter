// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/rendering.dart' show RelativeRect;

/// A widget that rebuilds when the given animation changes value.
///
/// AnimatedWidget is most useful for stateless animated widgets. To use
/// AnimatedWidget, simply subclass it and implement the build function.
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder].
abstract class AnimatedWidget extends StatefulWidget {
  /// Creates a widget that rebuilds when the given animation changes value.
  ///
  /// The [animation] argument is required.
  AnimatedWidget({
    Key key,
    @required this.animation
  }) : super(key: key) {
    assert(animation != null);
  }

  /// The animation to which this widget is listening.
  final Animation<Object> animation;

  /// Override this method to build widgets that depend on the current value
  /// of the animation.
  @protected
  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  @override
  _AnimatedState createState() => new _AnimatedState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('animation: $animation');
  }
}

class _AnimatedState extends State<AnimatedWidget> {
  @override
  void initState() {
    super.initState();
    config.animation.addListener(_handleTick);
  }

  @override
  void didUpdateConfig(AnimatedWidget oldConfig) {
    if (config.animation != oldConfig.animation) {
      oldConfig.animation.removeListener(_handleTick);
      config.animation.addListener(_handleTick);
    }
  }

  @override
  void dispose() {
    config.animation.removeListener(_handleTick);
    super.dispose();
  }

  void _handleTick() {
    setState(() {
      // The animation's state is our build state, and it changed already.
    });
  }

  @override
  Widget build(BuildContext context) {
    return config.build(context);
  }
}

/// Animates the position of a widget relative to its normal position.
class SlideTransition extends AnimatedWidget {
  /// Creates a fractional translation transition.
  ///
  /// The [position] argument is required.
  SlideTransition({
    Key key,
    Animation<FractionalOffset> position,
    this.transformHitTests: true,
    this.child,
  }) : super(key: key, animation: position);

  /// The animation that controls the position of the child.
  ///
  /// If the current value of the position animation is (dx, dy), the child will
  /// be translated horizontally by width * dx and vertically by height * dy.
  Animation<FractionalOffset> get position => animation;

  /// Whether hit testing should be affected by the slide animation.
  ///
  /// If false, hit testing will proceed as if the child was not translated at
  /// all. Setting this value to false is useful for fast animations where you
  /// expect the user to commonly interact with the child widget in its final
  /// location and you want the user to benefit from "muscle memory".
  final bool transformHitTests;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new FractionalTranslation(
      translation: position.value,
      transformHitTests: transformHitTests,
      child: child,
    );
  }
}

/// Animates the scale of transformed widget.
class ScaleTransition extends AnimatedWidget {
  /// Creates a scale transition.
  ///
  /// The [scale] argument is required. The [alignment] argument defaults to
  /// [FractionalOffset.center].
  ScaleTransition({
    Key key,
    Animation<double> scale,
    this.alignment: FractionalOffset.center,
    this.child,
  }) : super(key: key, animation: scale);

  /// The animation that controls the scale of the child.
  ///
  /// If the current value of the scale animation is v, the child will be
  /// painted v times its normal size.
  Animation<double> get scale => animation;

  /// The alignment of the origin of the coordainte system in which the scale
  /// takes place, relative to the size of the box.
  ///
  /// For example, to set the origin of the scale to bottom middle, you can use
  /// an alignment of (0.5, 1.0).
  final FractionalOffset alignment;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double scaleValue = scale.value;
    Matrix4 transform = new Matrix4.identity()
      ..scale(scaleValue, scaleValue, 1.0);
    return new Transform(
      transform: transform,
      alignment: alignment,
      child: child,
    );
  }
}

/// Animates the rotation of a widget.
class RotationTransition extends AnimatedWidget {
  /// Creates a rotation transition.
  ///
  /// The [turns] argument is required.
  RotationTransition({
    Key key,
    Animation<double> turns,
    this.child,
  }) : super(key: key, animation: turns);

  /// The animation that controls the rotation of the child.
  ///
  /// If the current value of the turns animation is v, the child will be
  /// rotated v * 2 * pi radians before being painted.
  Animation<double> get turns => animation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double turnsValue = turns.value;
    Matrix4 transform = new Matrix4.rotationZ(turnsValue * math.PI * 2.0);
    return new Transform(
      transform: transform,
      alignment: FractionalOffset.center,
      child: child,
    );
  }
}

/// Animates its own size and clips and aligns the child.
///
/// For a widget that automatically animates between the sizes of two children,
/// fading between them, see [AnimatedCrossFade].
class SizeTransition extends AnimatedWidget {
  /// Creates a size transition.
  ///
  /// The [sizeFactor] argument is required. The [axis] argument defaults to
  /// [Axis.vertical]. The [axisAlignment] defaults to 0.5, which centers the
  /// child along the main axis during the transition.
  SizeTransition({
    Key key,
    this.axis: Axis.vertical,
    Animation<double> sizeFactor,
    this.axisAlignment: 0.5,
    this.child,
  }) : super(key: key, animation: sizeFactor) {
    assert(axis != null);
  }

  /// [Axis.horizontal] if [sizeFactor] modifies the width, otherwise [Axis.vertical].
  final Axis axis;

  /// The animation that controls the (clipped) size of the child. If the current value
  /// of sizeFactor is v then the width or height of the widget will be its intrinsic
  /// width or height multiplied by v.
  Animation<double> get sizeFactor => animation;

  /// How to align the child along the axis that sizeFactor is modifying.
  final double axisAlignment;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    FractionalOffset alignment;
    if (axis == Axis.vertical)
      alignment = new FractionalOffset(0.0, axisAlignment);
    else
      alignment = new FractionalOffset(axisAlignment, 0.0);
    return new ClipRect(
      child: new Align(
        alignment: alignment,
        heightFactor: axis == Axis.vertical ? sizeFactor.value : null,
        widthFactor: axis == Axis.horizontal ? sizeFactor.value : null,
        child: child,
      )
    );
  }
}

/// Animates the opacity of a widget.
///
/// For a widget that automatically animates between the sizes of two children,
/// fading between them, see [AnimatedCrossFade].
class FadeTransition extends AnimatedWidget {
  /// Creates an opacity transition.
  ///
  /// The [opacity] argument is required.
  FadeTransition({
    Key key,
    Animation<double> opacity,
    this.child,
  }) : super(key: key, animation: opacity);

  /// The animation that controls the opacity of the child.
  ///
  /// If the current value of the opacity animation is v, the child will be
  /// painted with an opacity of v. For example, if v is 0.5, the child will be
  /// blended 50% with its background. Similarly, if v is 0.0, the child will be
  /// completely transparent.
  Animation<double> get opacity => animation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
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
  /// Creates a relative rect tween.
  ///
  /// The [begin] and [end] arguments must not be null.
  RelativeRectTween({ RelativeRect begin, RelativeRect end })
    : super(begin: begin, end: end);

  @override
  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t);
}

/// Animated version of [Positioned] which takes a specific
/// [Animation<RelativeRect>] to transition the child's position from a start
/// position to and end position over the lifetime of the animation.
///
/// Only works if it's the child of a [Stack].
///
/// See also:
///
/// * [RelativePositionedTransition].
class PositionedTransition extends AnimatedWidget {
  /// Creates a transition for [Positioned].
  ///
  /// The [rect] argument is required.
  PositionedTransition({
    Key key,
    Animation<RelativeRect> rect,
    @required this.child,
  }) : super(key: key, animation: rect);

  /// The animation that controls the child's size and position.
  Animation<RelativeRect> get rect => animation;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Positioned(
      top: rect.value.top,
      right: rect.value.right,
      bottom: rect.value.bottom,
      left: rect.value.left,
      child: child,
    );
  }
}

/// Animated version of [Positioned] which transitions the child's position
/// based on the value of [rect] relative to a bounding box with the
/// specified [size].
///
/// Only works if it's the child of a [Stack].
///
/// See also:
///
/// * [PositionedTransition].
class RelativePositionedTransition extends AnimatedWidget {
  /// Create an animated version of [Positioned].
  ///
  /// Each frame, the [Positioned] widget will be configured to represent the
  /// current value of the [rect] argument assuming that the stack has the given
  /// [size]. Both [rect] and [size] must be non-null.
  RelativePositionedTransition({
    Key key,
    @required Animation<Rect> rect,
    @required this.size,
    @required this.child,
  }) : super(key: key, animation: rect);

  /// The animation that controls the child's size and position.
  ///
  /// See also [size].
  Animation<Rect> get rect => animation;

  /// The [Positioned] widget's offsets are relative to a box of this
  /// size whose origin is 0,0.
  final Size size;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final RelativeRect offsets = new RelativeRect.fromSize(rect.value, size);
    return new Positioned(
      top: offsets.top,
      right: offsets.right,
      bottom: offsets.bottom,
      left: offsets.left,
      child: child,
    );
  }
}

/// A builder that builds a widget given a child.
///
/// The child should typically be part of the returned widget tree.
///
/// Used by [AnimatedBuilder.builder].
typedef Widget TransitionBuilder(BuildContext context, Widget child);

/// A general-purpose widget for building animations.
///
/// AnimatedBuilder is useful for more complex widgets that wish to include
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
/// [AnimatedWidget].
class AnimatedBuilder extends AnimatedWidget {
  /// Creates an animated builder.
  ///
  /// The [animation] and [builder] arguments must not be null.
  AnimatedBuilder({
    Key key,
    @required Animation<Object> animation,
    @required this.builder,
    this.child,
  }) : super(key: key, animation: animation) {
    assert(builder != null);
  }

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

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
