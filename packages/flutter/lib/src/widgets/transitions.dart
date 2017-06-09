// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'basic.dart';
import 'container.dart';
import 'framework.dart';

export 'package:flutter/rendering.dart' show RelativeRect;

/// A widget that rebuilds when the given [Listenable] changes value.
///
/// [AnimatedWidget] is most commonly used with [Animation] objects, which are
/// [Listenable], but it can be used with any [Listenable], including
/// [ChangeNotifier] and [ValueNotifier].
///
/// [AnimatedWidget] is most useful for widgets widgets that are otherwise
/// stateless. To use [AnimatedWidget], simply subclass it and implement the
/// build function.
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder].
///
/// See also:
///
///  * [AnimatedBuilder], which is useful for more complex use cases.
///  * [Animation], which is a [Listenable] object that can be used for
///    [listenable].
///  * [ChangeNotifier], which is another [Listenable] object that can be used
///    for [listenable].
abstract class AnimatedWidget extends StatefulWidget {
  /// Creates a widget that rebuilds when the given listenable changes.
  ///
  /// The [listenable] argument is required.
  const AnimatedWidget({
    Key key,
    @required this.listenable
  }) : assert(listenable != null),
       super(key: key);

  /// The [Listenable] to which this widget is listening.
  ///
  /// Commonly an [Animation] or a [ChangeNotifier].
  final Listenable listenable;

  /// Override this method to build widgets that depend on the state of the
  /// listenable (e.g., the current value of the animation).
  @protected
  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  @override
  _AnimatedState createState() => new _AnimatedState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('animation: $listenable');
  }
}

class _AnimatedState extends State<AnimatedWidget> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The listenable's state is our build state, and it changed already.
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

/// Animates the position of a widget relative to its normal position.
class SlideTransition extends AnimatedWidget {
  /// Creates a fractional translation transition.
  ///
  /// The [position] argument must not be null.
  const SlideTransition({
    Key key,
    @required Animation<FractionalOffset> position,
    this.transformHitTests: true,
    this.child,
  }) : super(key: key, listenable: position);

  /// The animation that controls the position of the child.
  ///
  /// If the current value of the position animation is (dx, dy), the child will
  /// be translated horizontally by width * dx and vertically by height * dy.
  Animation<FractionalOffset> get position => listenable;

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
  /// The [scale] argument must not be null. The [alignment] argument defaults
  /// to [FractionalOffset.center].
  const ScaleTransition({
    Key key,
    @required Animation<double> scale,
    this.alignment: FractionalOffset.center,
    this.child,
  }) : super(key: key, listenable: scale);

  /// The animation that controls the scale of the child.
  ///
  /// If the current value of the scale animation is v, the child will be
  /// painted v times its normal size.
  Animation<double> get scale => listenable;

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
    final Matrix4 transform = new Matrix4.identity()
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
  /// The [turns] argument must not be null.
  const RotationTransition({
    Key key,
    @required Animation<double> turns,
    this.child,
  }) : super(key: key, listenable: turns);

  /// The animation that controls the rotation of the child.
  ///
  /// If the current value of the turns animation is v, the child will be
  /// rotated v * 2 * pi radians before being painted.
  Animation<double> get turns => listenable;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double turnsValue = turns.value;
    final Matrix4 transform = new Matrix4.rotationZ(turnsValue * math.PI * 2.0);
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
  /// The [sizeFactor] argument must not be null. The [axis] argument defaults
  /// to [Axis.vertical]. The [axisAlignment] defaults to 0.5, which centers the
  /// child along the main axis during the transition.
  const SizeTransition({
    Key key,
    this.axis: Axis.vertical,
    @required Animation<double> sizeFactor,
    this.axisAlignment: 0.5,
    this.child,
  }) : assert(axis != null),
       super(key: key, listenable: sizeFactor);

  /// [Axis.horizontal] if [sizeFactor] modifies the width, otherwise [Axis.vertical].
  final Axis axis;

  /// The animation that controls the (clipped) size of the child. If the current value
  /// of sizeFactor is v then the width or height of the widget will be its intrinsic
  /// width or height multiplied by v.
  Animation<double> get sizeFactor => listenable;

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
  /// The [opacity] argument must not be null.
  const FadeTransition({
    Key key,
    @required Animation<double> opacity,
    this.child,
  }) : super(key: key, listenable: opacity);

  /// The animation that controls the opacity of the child.
  ///
  /// If the current value of the opacity animation is v, the child will be
  /// painted with an opacity of v. For example, if v is 0.5, the child will be
  /// blended 50% with its background. Similarly, if v is 0.0, the child will be
  /// completely transparent.
  Animation<double> get opacity => listenable;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Opacity(opacity: opacity.value, child: child);
  }
}

/// An interpolation between two relative rects.
///
/// This class specializes the interpolation of [Tween<RelativeRect>] to
/// use [RelativeRect.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class RelativeRectTween extends Tween<RelativeRect> {
  /// Creates a [RelativeRect] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as [RelativeRect.fill].
  RelativeRectTween({ RelativeRect begin, RelativeRect end })
    : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
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
  /// The [rect] argument must not be null.
  const PositionedTransition({
    Key key,
    @required Animation<RelativeRect> rect,
    @required this.child,
  }) : super(key: key, listenable: rect);

  /// The animation that controls the child's size and position.
  Animation<RelativeRect> get rect => listenable;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Positioned.fromRelativeRect(
      rect: rect.value,
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
  /// [size]. Both [rect] and [size] must not be null.
  const RelativePositionedTransition({
    Key key,
    @required Animation<Rect> rect,
    @required this.size,
    @required this.child,
  }) : super(key: key, listenable: rect);

  /// The animation that controls the child's size and position.
  ///
  /// See also [size].
  Animation<Rect> get rect => listenable;

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

/// Animated version of a [DecoratedBox] that animates the different properties
/// of its [Decoration].
///
/// See also:
///
/// * [DecoratedBox], which also draws a [Decoration] but is not animated.
/// * [AnimatedContainer], a more full-featured container that also animates on
///   decoration using an internal animation.
class DecoratedBoxTransition extends AnimatedWidget {
  /// Creates an animated [DecoratedBox] whose [Decoration] animation updates
  /// the widget.
  ///
  /// The [decoration] and [position] cannot be null.
  ///
  /// See also:
  ///
  /// * [new DecoratedBox].
  const DecoratedBoxTransition({
    Key key,
    @required this.decoration,
    this.position: DecorationPosition.background,
    @required this.child,
  }) : super(key: key, listenable: decoration);

  /// Animation of the decoration to paint.
  ///
  /// Can be created using a [DecorationTween] interpolating typically between
  /// two [BoxDecoration].
  final Animation<Decoration> decoration;

  /// Whether to paint the box decoration behind or in front of the child.
  final DecorationPosition position;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new DecoratedBox(
      decoration: decoration.value,
      position: position,
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
/// For simple cases without additional state, consider using
/// [AnimatedWidget].
///
/// ## Performance optimisations
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
/// ## Sample code
///
/// This code defines a widget called `Spinner` that spins a green square
/// continually. It is built with an [AnimatedBuilder] and makes use of the
/// [child] feature to avoid having to rebuild the [Container] each time.
///
/// ```dart
/// class Spinner extends StatefulWidget {
///   @override
///   _SpinnerState createState() => new _SpinnerState();
/// }
///
/// class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
///   AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = new AnimationController(
///       duration: const Duration(seconds: 10),
///       vsync: this,
///     )..repeat();
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return new AnimatedBuilder(
///       animation: _controller,
///       child: new Container(width: 200.0, height: 200.0, color: Colors.green),
///       builder: (BuildContext context, Widget child) {
///         return new Transform.rotate(
///           angle: _controller.value * 2.0 * math.PI,
///           child: child,
///         );
///       },
///     );
///   }
/// }
/// ```
class AnimatedBuilder extends AnimatedWidget {
  /// Creates an animated builder.
  ///
  /// The [animation] and [builder] arguments must not be null.
  const AnimatedBuilder({
    Key key,
    @required Listenable animation,
    @required this.builder,
    this.child,
  }) : assert(builder != null),
       super(key: key, listenable: animation);

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
