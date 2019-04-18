// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'container.dart';
import 'debug.dart';
import 'framework.dart';
import 'text.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

// Examples can assume:
// class MyWidget extends ImplicitlyAnimatedWidget {
//   MyWidget() : super(duration: const Duration(seconds: 1));
//   final Color targetColor = Colors.black;
//   @override
//   MyWidgetState createState() => MyWidgetState();
// }

/// An interpolation between two [BoxConstraints].
///
/// This class specializes the interpolation of [Tween<BoxConstraints>] to use
/// [BoxConstraints.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class BoxConstraintsTween extends Tween<BoxConstraints> {
  /// Creates a [BoxConstraints] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as a tight constraint of zero size.
  BoxConstraintsTween({ BoxConstraints begin, BoxConstraints end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  BoxConstraints lerp(double t) => BoxConstraints.lerp(begin, end, t);
}

/// An interpolation between two [Decoration]s.
///
/// This class specializes the interpolation of [Tween<BoxConstraints>] to use
/// [Decoration.lerp].
///
/// For [ShapeDecoration]s which know how to [ShapeDecoration.lerpTo] or
/// [ShapeDecoration.lerpFrom] each other, this will produce a smooth
/// interpolation between decorations.
///
/// See also:
///
///  * [Tween] for a discussion on how to use interpolation objects.
///  * [ShapeDecoration], [RoundedRectangleBorder], [CircleBorder], and
///    [StadiumBorder] for examples of shape borders that can be smoothly
///    interpolated.
///  * [BoxBorder] for a border that can only be smoothly interpolated between other
///    [BoxBorder]s.
class DecorationTween extends Tween<Decoration> {
  /// Creates a decoration tween.
  ///
  /// The [begin] and [end] properties may be null. If both are null, then the
  /// result is always null. If [end] is not null, then its lerping logic is
  /// used (via [Decoration.lerpTo]). Otherwise, [begin]'s lerping logic is used
  /// (via [Decoration.lerpFrom]).
  DecorationTween({ Decoration begin, Decoration end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Decoration lerp(double t) => Decoration.lerp(begin, end, t);
}

/// An interpolation between two [EdgeInsets]s.
///
/// This class specializes the interpolation of [Tween<EdgeInsets>] to use
/// [EdgeInsets.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
///
/// See also:
///
///  * [EdgeInsetsGeometryTween], which interpolates between two
///    [EdgeInsetsGeometry] objects.
class EdgeInsetsTween extends Tween<EdgeInsets> {
  /// Creates an [EdgeInsets] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as an [EdgeInsets] with no inset.
  EdgeInsetsTween({ EdgeInsets begin, EdgeInsets end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  EdgeInsets lerp(double t) => EdgeInsets.lerp(begin, end, t);
}

/// An interpolation between two [EdgeInsetsGeometry]s.
///
/// This class specializes the interpolation of [Tween<EdgeInsetsGeometry>] to
/// use [EdgeInsetsGeometry.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
///
/// See also:
///
///  * [EdgeInsetsTween], which interpolates between two [EdgeInsets] objects.
class EdgeInsetsGeometryTween extends Tween<EdgeInsetsGeometry> {
  /// Creates an [EdgeInsetsGeometry] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as an [EdgeInsetsGeometry] with no inset.
  EdgeInsetsGeometryTween({ EdgeInsetsGeometry begin, EdgeInsetsGeometry end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  EdgeInsetsGeometry lerp(double t) => EdgeInsetsGeometry.lerp(begin, end, t);
}

/// An interpolation between two [BorderRadius]s.
///
/// This class specializes the interpolation of [Tween<BorderRadius>] to use
/// [BorderRadius.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class BorderRadiusTween extends Tween<BorderRadius> {
  /// Creates a [BorderRadius] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as a right angle (no radius).
  BorderRadiusTween({ BorderRadius begin, BorderRadius end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  BorderRadius lerp(double t) => BorderRadius.lerp(begin, end, t);
}

/// An interpolation between two [Border]s.
///
/// This class specializes the interpolation of [Tween<Border>] to use
/// [Border.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class BorderTween extends Tween<Border> {
  /// Creates a [Border] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as having no border.
  BorderTween({ Border begin, Border end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Border lerp(double t) => Border.lerp(begin, end, t);
}

/// An interpolation between two [Matrix4]s.
///
/// This class specializes the interpolation of [Tween<Matrix4>] to be
/// appropriate for transformation matrices.
///
/// Currently this class works only for translations.
///
/// See [Tween] for a discussion on how to use interpolation objects.
class Matrix4Tween extends Tween<Matrix4> {
  /// Creates a [Matrix4] tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  Matrix4Tween({ Matrix4 begin, Matrix4 end }) : super(begin: begin, end: end);

  @override
  Matrix4 lerp(double t) {
    assert(begin != null);
    assert(end != null);
    final Vector3 beginTranslation = Vector3.zero();
    final Vector3 endTranslation = Vector3.zero();
    final Quaternion beginRotation = Quaternion.identity();
    final Quaternion endRotation = Quaternion.identity();
    final Vector3 beginScale = Vector3.zero();
    final Vector3 endScale = Vector3.zero();
    begin.decompose(beginTranslation, beginRotation, beginScale);
    end.decompose(endTranslation, endRotation, endScale);
    final Vector3 lerpTranslation =
        beginTranslation * (1.0 - t) + endTranslation * t;
    // TODO(alangardner): Implement slerp for constant rotation
    final Quaternion lerpRotation =
        (beginRotation.scaled(1.0 - t) + endRotation.scaled(t)).normalized();
    final Vector3 lerpScale = beginScale * (1.0 - t) + endScale * t;
    return Matrix4.compose(lerpTranslation, lerpRotation, lerpScale);
  }
}

/// An interpolation between two [TextStyle]s.
///
/// This class specializes the interpolation of [Tween<TextStyle>] to use
/// [TextStyle.lerp].
///
/// This will not work well if the styles don't set the same fields.
///
/// See [Tween] for a discussion on how to use interpolation objects.
class TextStyleTween extends Tween<TextStyle> {
  /// Creates a text style tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  TextStyleTween({ TextStyle begin, TextStyle end }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  TextStyle lerp(double t) => TextStyle.lerp(begin, end, t);
}

/// An abstract widget for building widgets that gradually change their
/// values over a period of time.
///
/// Subclasses' States must provide a way to visit the subclass's relevant
/// fields to animate. [ImplicitlyAnimatedWidget] will then automatically
/// interpolate and animate those fields using the provided duration and
/// curve when those fields change.
abstract class ImplicitlyAnimatedWidget extends StatefulWidget {
  /// Initializes fields for subclasses.
  ///
  /// The [curve] and [duration] arguments must not be null.
  const ImplicitlyAnimatedWidget({
    Key key,
    this.curve = Curves.linear,
    @required this.duration,
  }) : assert(curve != null),
       assert(duration != null),
       super(key: key);

  /// The curve to apply when animating the parameters of this container.
  final Curve curve;

  /// The duration over which to animate the parameters of this container.
  final Duration duration;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
  }
}

/// Signature for a [Tween] factory.
///
/// This is the type of one of the arguments of [TweenVisitor], the signature
/// used by [AnimatedWidgetBaseState.forEachTween].
typedef TweenConstructor<T> = Tween<T> Function(T targetValue);

/// Signature for callbacks passed to [AnimatedWidgetBaseState.forEachTween].
typedef TweenVisitor<T> = Tween<T> Function(Tween<T> tween, T targetValue, TweenConstructor<T> constructor);

/// A base class for widgets with implicit animations.
///
/// [ImplicitlyAnimatedWidgetState] requires that subclasses respond to the
/// animation, themselves. If you would like `setState()` to be called
/// automatically as the animation changes, use [AnimatedWidgetBaseState].
///
/// Subclasses must implement the [forEachTween] method to allow
/// [ImplicitlyAnimatedWidgetState] to iterate through the subclasses' widget's
/// fields and animate them.
abstract class ImplicitlyAnimatedWidgetState<T extends ImplicitlyAnimatedWidget> extends State<T> with SingleTickerProviderStateMixin<T> {
  /// The animation controller driving this widget's implicit animations.
  @protected
  AnimationController get controller => _controller;
  AnimationController _controller;

  /// The animation driving this widget's implicit animations.
  Animation<double> get animation => _animation;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      debugLabel: '${widget.toStringShort()}',
      vsync: this,
    );
    _updateCurve();
    _constructTweens();
    didUpdateTweens();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.curve != oldWidget.curve)
      _updateCurve();
    _controller.duration = widget.duration;
    if (_constructTweens()) {
      forEachTween((Tween<dynamic> tween, dynamic targetValue, TweenConstructor<dynamic> constructor) {
        _updateTween(tween, targetValue);
        return tween;
      });
      _controller
        ..value = 0.0
        ..forward();
      didUpdateTweens();
    }
  }

  void _updateCurve() {
    if (widget.curve != null)
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    else
      _animation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldAnimateTween(Tween<dynamic> tween, dynamic targetValue) {
    return targetValue != (tween.end ?? tween.begin);
  }

  void _updateTween(Tween<dynamic> tween, dynamic targetValue) {
    if (tween == null)
      return;
    tween
      ..begin = tween.evaluate(_animation)
      ..end = targetValue;
  }

  bool _constructTweens() {
    bool shouldStartAnimation = false;
    forEachTween((Tween<dynamic> tween, dynamic targetValue, TweenConstructor<dynamic> constructor) {
      if (targetValue != null) {
        tween ??= constructor(targetValue);
        if (_shouldAnimateTween(tween, targetValue))
          shouldStartAnimation = true;
      } else {
        tween = null;
      }
      return tween;
    });
    return shouldStartAnimation;
  }

  /// Subclasses must implement this function by running through the following
  /// steps for each animatable facet in the class:
  ///
  /// 1. Call the visitor callback with three arguments, the first argument
  /// being the current value of the Tween<T> object that represents the
  /// tween (initially null), the second argument, of type T, being the value
  /// on the Widget that represents the current target value of the
  /// tween, and the third being a callback that takes a value T (which will
  /// be the second argument to the visitor callback), and that returns an
  /// Tween<T> object for the tween, configured with the given value
  /// as the begin value.
  ///
  /// 2. Take the value returned from the callback, and store it. This is the
  /// value to use as the current value the next time that the [forEachTween]
  /// method is called.
  ///
  /// Subclasses that contain properties based on tweens created by
  /// [forEachTween] should override [didUpdateTweens] to update those
  /// properties. Dependent properties should not be updated within
  /// [forEachTween].
  ///
  /// {@tool sample}
  ///
  /// Sample code implementing an implicitly animated widget's `State`.
  /// The widget animates between colors whenever `widget.targetColor`
  /// changes.
  ///
  /// ```dart
  /// class MyWidgetState extends AnimatedWidgetBaseState<MyWidget> {
  ///   ColorTween _colorTween;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Text(
  ///       'Hello World',
  ///       // Computes the value of the text color at any given time.
  ///       style: TextStyle(color: _colorTween.evaluate(animation)),
  ///     );
  ///   }
  ///
  ///   @override
  ///   void forEachTween(TweenVisitor<dynamic> visitor) {
  ///     // Update the tween using the provided visitor function.
  ///     _colorTween = visitor(
  ///       // The latest tween value. Can be `null`.
  ///       _colorTween,
  ///       // The color value toward which we are animating.
  ///       widget.targetColor,
  ///       // A function that takes a color value and returns a tween
  ///       // beginning at that value.
  ///       (value) => ColorTween(begin: value),
  ///     );
  ///
  ///     // We could have more tweens than one by using the visitor
  ///     // multiple times.
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  @protected
  void forEachTween(TweenVisitor<dynamic> visitor);

  /// Optional hook for subclasses that runs after all tweens have been updated
  /// via [forEachTween].
  ///
  /// Any properties that depend upon tweens created by [forEachTween] should be
  /// updated within [didUpdateTweens], not within [forEachTween].
  @protected
  void didUpdateTweens() { }
}

/// A base class for widgets with implicit animations that need to rebuild their
/// widget tree as the animation runs.
///
/// This class calls [build] each frame that the animation tickets. For a
/// variant that does not rebuild each frame, consider subclassing
/// [ImplicitlyAnimatedWidgetState] directly.
///
/// Subclasses must implement the [forEachTween] method to allow
/// [AnimatedWidgetBaseState] to iterate through the subclasses' widget's fields
/// and animate them.
abstract class AnimatedWidgetBaseState<T extends ImplicitlyAnimatedWidget> extends ImplicitlyAnimatedWidgetState<T> {
  @override
  void initState() {
    super.initState();
    controller.addListener(_handleAnimationChanged);
  }

  void _handleAnimationChanged() {
    setState(() { /* The animation ticked. Rebuild with new animation value */ });
  }
}

/// A container that gradually changes its values over a period of time.
///
/// The [AnimatedContainer] will automatically animate between the old and
/// new values of properties when they change using the provided curve and
/// duration. Properties that are null are not animated. Its child and
/// descendants are not animated.
///
/// This class is useful for generating simple implicit transitions between
/// different parameters to [Container] with its internal [AnimationController].
/// For more complex animations, you'll likely want to use a subclass of
/// [AnimatedWidget] such as the [DecoratedBoxTransition] or use your own
/// [AnimationController].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=yI-8QHpGIP4}
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_container.mp4}
///
/// See also:
///
///  * [AnimatedPadding], which is a subset of this widget that only
///    supports animating the [padding].
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
///  * [AnimatedPositioned], which, as a child of a [Stack], automatically
///    transitions its child's position over a given duration whenever the given
///    position changes.
///  * [AnimatedAlign], which automatically transitions its child's
///    position over a given duration whenever the given [alignment] changes.
///  * [AnimatedSwitcher], which switches out a child for a new one with a customizable transition.
///  * [AnimatedCrossFade], which fades between two children and interpolates their sizes.
class AnimatedContainer extends ImplicitlyAnimatedWidget {
  /// Creates a container that animates its parameters implicitly.
  ///
  /// The [curve] and [duration] arguments must not be null.
  AnimatedContainer({
    Key key,
    this.alignment,
    this.padding,
    Color color,
    Decoration decoration,
    this.foregroundDecoration,
    double width,
    double height,
    BoxConstraints constraints,
    this.margin,
    this.transform,
    this.child,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(margin == null || margin.isNonNegative),
       assert(padding == null || padding.isNonNegative),
       assert(decoration == null || decoration.debugAssertIsValid()),
       assert(constraints == null || constraints.debugAssertIsValid()),
       assert(color == null || decoration == null,
         'Cannot provide both a color and a decoration\n'
         'The color argument is just a shorthand for "decoration: new BoxDecoration(backgroundColor: color)".'
       ),
       decoration = decoration ?? (color != null ? BoxDecoration(color: color) : null),
       constraints =
        (width != null || height != null)
          ? constraints?.tighten(width: width, height: height)
            ?? BoxConstraints.tightFor(width: width, height: height)
          : constraints,
       super(key: key, curve: curve, duration: duration);

  /// The [child] contained by the container.
  ///
  /// If null, and if the [constraints] are unbounded or also null, the
  /// container will expand to fill all available space in its parent, unless
  /// the parent provides unbounded constraints, in which case the container
  /// will attempt to be as small as possible.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Align the [child] within the container.
  ///
  /// If non-null, the container will expand to fill its parent and position its
  /// child within itself according to the given value. If the incoming
  /// constraints are unbounded, then the child will be shrink-wrapped instead.
  ///
  /// Ignored if [child] is null.
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// Empty space to inscribe inside the [decoration]. The [child], if any, is
  /// placed inside this padding.
  final EdgeInsetsGeometry padding;

  /// The decoration to paint behind the [child].
  ///
  /// A shorthand for specifying just a solid color is available in the
  /// constructor: set the `color` argument instead of the `decoration`
  /// argument.
  final Decoration decoration;

  /// The decoration to paint in front of the child.
  final Decoration foregroundDecoration;

  /// Additional constraints to apply to the child.
  ///
  /// The constructor `width` and `height` arguments are combined with the
  /// `constraints` argument to set this property.
  ///
  /// The [padding] goes inside the constraints.
  final BoxConstraints constraints;

  /// Empty space to surround the [decoration] and [child].
  final EdgeInsetsGeometry margin;

  /// The transformation matrix to apply before painting the container.
  final Matrix4 transform;

  @override
  _AnimatedContainerState createState() => _AnimatedContainerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, showName: false, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('bg', decoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('fg', foregroundDecoration, defaultValue: null));
    properties.add(DiagnosticsProperty<BoxConstraints>('constraints', constraints, defaultValue: null, showName: false));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(ObjectFlagProperty<Matrix4>.has('transform', transform));
  }
}

class _AnimatedContainerState extends AnimatedWidgetBaseState<AnimatedContainer> {
  AlignmentGeometryTween _alignment;
  EdgeInsetsGeometryTween _padding;
  DecorationTween _decoration;
  DecorationTween _foregroundDecoration;
  BoxConstraintsTween _constraints;
  EdgeInsetsGeometryTween _margin;
  Matrix4Tween _transform;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(_alignment, widget.alignment, (dynamic value) => AlignmentGeometryTween(begin: value));
    _padding = visitor(_padding, widget.padding, (dynamic value) => EdgeInsetsGeometryTween(begin: value));
    _decoration = visitor(_decoration, widget.decoration, (dynamic value) => DecorationTween(begin: value));
    _foregroundDecoration = visitor(_foregroundDecoration, widget.foregroundDecoration, (dynamic value) => DecorationTween(begin: value));
    _constraints = visitor(_constraints, widget.constraints, (dynamic value) => BoxConstraintsTween(begin: value));
    _margin = visitor(_margin, widget.margin, (dynamic value) => EdgeInsetsGeometryTween(begin: value));
    _transform = visitor(_transform, widget.transform, (dynamic value) => Matrix4Tween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
      alignment: _alignment?.evaluate(animation),
      padding: _padding?.evaluate(animation),
      decoration: _decoration?.evaluate(animation),
      foregroundDecoration: _foregroundDecoration?.evaluate(animation),
      constraints: _constraints?.evaluate(animation),
      margin: _margin?.evaluate(animation),
      transform: _transform?.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<AlignmentGeometryTween>('alignment', _alignment, showName: false, defaultValue: null));
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>('padding', _padding, defaultValue: null));
    description.add(DiagnosticsProperty<DecorationTween>('bg', _decoration, defaultValue: null));
    description.add(DiagnosticsProperty<DecorationTween>('fg', _foregroundDecoration, defaultValue: null));
    description.add(DiagnosticsProperty<BoxConstraintsTween>('constraints', _constraints, showName: false, defaultValue: null));
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>('margin', _margin, defaultValue: null));
    description.add(ObjectFlagProperty<Matrix4Tween>.has('transform', _transform));
  }
}

/// Animated version of [Padding] which automatically transitions the
/// indentation over a given duration whenever the given inset changes.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_padding.mp4}
///
/// See also:
///
///  * [AnimatedContainer], which can transition more values at once.
///  * [AnimatedAlign], which automatically transitions its child's
///    position over a given duration whenever the given [alignment] changes.
class AnimatedPadding extends ImplicitlyAnimatedWidget {
  /// Creates a widget that insets its child by a value that animates
  /// implicitly.
  ///
  /// The [padding], [curve], and [duration] arguments must not be null.
  AnimatedPadding({
    Key key,
    @required this.padding,
    this.child,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(padding != null),
       assert(padding.isNonNegative),
       super(key: key, curve: curve, duration: duration);

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry padding;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _AnimatedPaddingState createState() => _AnimatedPaddingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

class _AnimatedPaddingState extends AnimatedWidgetBaseState<AnimatedPadding> {
  EdgeInsetsGeometryTween _padding;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _padding = visitor(_padding, widget.padding, (dynamic value) => EdgeInsetsGeometryTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _padding.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>('padding', _padding, defaultValue: null));
  }
}

/// Animated version of [Align] which automatically transitions the child's
/// position over a given duration whenever the given [alignment] changes.
///
/// Here's an illustration of what this can look like, using a [curve] of
/// [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_align.mp4}
///
/// See also:
///
///  * [AnimatedContainer], which can transition more values at once.
///  * [AnimatedPadding], which can animate the padding instead of the
///    alignment.
///  * [AnimatedPositioned], which, as a child of a [Stack], automatically
///    transitions its child's position over a given duration whenever the given
///    position changes.
class AnimatedAlign extends ImplicitlyAnimatedWidget {
  /// Creates a widget that positions its child by an alignment that animates
  /// implicitly.
  ///
  /// The [alignment], [curve], and [duration] arguments must not be null.
  const AnimatedAlign({
    Key key,
    @required this.alignment,
    this.child,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(alignment != null),
       super(key: key, curve: curve, duration: duration);

  /// How to align the child.
  ///
  /// The x and y values of the [Alignment] control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// See also:
  ///
  ///  * [Alignment], which has more details and some convenience constants for
  ///    common positions.
  ///  * [AlignmentDirectional], which has a horizontal coordinate orientation
  ///    that depends on the [TextDirection].
  final AlignmentGeometry alignment;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _AnimatedAlignState createState() => _AnimatedAlignState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }
}

class _AnimatedAlignState extends AnimatedWidgetBaseState<AnimatedAlign> {
  AlignmentGeometryTween _alignment;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(_alignment, widget.alignment, (dynamic value) => AlignmentGeometryTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _alignment.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<AlignmentGeometryTween>('alignment', _alignment, defaultValue: null));
  }
}

/// Animated version of [Positioned] which automatically transitions the child's
/// position over a given duration whenever the given position changes.
///
/// Only works if it's the child of a [Stack].
///
/// This widget is a good choice if the _size_ of the child would end up
/// changing as a result of this animation. If the size is intended to remain
/// the same, with only the _position_ changing over time, then consider
/// [SlideTransition] instead. [SlideTransition] only triggers a repaint each
/// frame of the animation, whereas [AnimatedPositioned] will trigger a relayout
/// as well.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_positioned.mp4}
///
/// See also:
///
///  * [AnimatedPositionedDirectional], which adapts to the ambient
///    [Directionality] (the same as this widget, but for animating
///    [PositionedDirectional]).
class AnimatedPositioned extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates its position implicitly.
  ///
  /// Only two out of the three horizontal values ([left], [right],
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
  ///
  /// The [curve] and [duration] arguments must not be null.
  const AnimatedPositioned({
    Key key,
    @required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(left == null || right == null || width == null),
       assert(top == null || bottom == null || height == null),
       super(key: key, curve: curve, duration: duration);

  /// Creates a widget that animates the rectangle it occupies implicitly.
  ///
  /// The [curve] and [duration] arguments must not be null.
  AnimatedPositioned.fromRect({
    Key key,
    this.child,
    Rect rect,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : left = rect.left,
       top = rect.top,
       width = rect.width,
       height = rect.height,
       right = null,
       bottom = null,
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The offset of the child's left edge from the left of the stack.
  final double left;

  /// The offset of the child's top edge from the top of the stack.
  final double top;

  /// The offset of the child's right edge from the right of the stack.
  final double right;

  /// The offset of the child's bottom edge from the bottom of the stack.
  final double bottom;

  /// The child's width.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can
  /// be set. The third must be null.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can
  /// be set. The third must be null.
  final double height;

  @override
  _AnimatedPositionedState createState() => _AnimatedPositionedState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('left', left, defaultValue: null));
    properties.add(DoubleProperty('top', top, defaultValue: null));
    properties.add(DoubleProperty('right', right, defaultValue: null));
    properties.add(DoubleProperty('bottom', bottom, defaultValue: null));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
  }
}

class _AnimatedPositionedState extends AnimatedWidgetBaseState<AnimatedPositioned> {
  Tween<double> _left;
  Tween<double> _top;
  Tween<double> _right;
  Tween<double> _bottom;
  Tween<double> _width;
  Tween<double> _height;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _left = visitor(_left, widget.left, (dynamic value) => Tween<double>(begin: value));
    _top = visitor(_top, widget.top, (dynamic value) => Tween<double>(begin: value));
    _right = visitor(_right, widget.right, (dynamic value) => Tween<double>(begin: value));
    _bottom = visitor(_bottom, widget.bottom, (dynamic value) => Tween<double>(begin: value));
    _width = visitor(_width, widget.width, (dynamic value) => Tween<double>(begin: value));
    _height = visitor(_height, widget.height, (dynamic value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: widget.child,
      left: _left?.evaluate(animation),
      top: _top?.evaluate(animation),
      right: _right?.evaluate(animation),
      bottom: _bottom?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(ObjectFlagProperty<Tween<double>>.has('left', _left));
    description.add(ObjectFlagProperty<Tween<double>>.has('top', _top));
    description.add(ObjectFlagProperty<Tween<double>>.has('right', _right));
    description.add(ObjectFlagProperty<Tween<double>>.has('bottom', _bottom));
    description.add(ObjectFlagProperty<Tween<double>>.has('width', _width));
    description.add(ObjectFlagProperty<Tween<double>>.has('height', _height));
  }
}

/// Animated version of [PositionedDirectional] which automatically transitions
/// the child's position over a given duration whenever the given position
/// changes.
///
/// The ambient [Directionality] is used to determine whether [start] is to the
/// left or to the right.
///
/// Only works if it's the child of a [Stack].
///
/// This widget is a good choice if the _size_ of the child would end up
/// changing as a result of this animation. If the size is intended to remain
/// the same, with only the _position_ changing over time, then consider
/// [SlideTransition] instead. [SlideTransition] only triggers a repaint each
/// frame of the animation, whereas [AnimatedPositionedDirectional] will trigger
/// a relayout as well. ([SlideTransition] is also text-direction-aware.)
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_positioned_directional.mp4}
///
/// See also:
///
///  * [AnimatedPositioned], which specifies the widget's position visually (the
///    same as this widget, but for animating [Positioned]).
class AnimatedPositionedDirectional extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates its position implicitly.
  ///
  /// Only two out of the three horizontal values ([start], [end], [width]), and
  /// only two out of the three vertical values ([top], [bottom], [height]), can
  /// be set. In each case, at least one of the three must be null.
  ///
  /// The [curve] and [duration] arguments must not be null.
  const AnimatedPositionedDirectional({
    Key key,
    @required this.child,
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(start == null || end == null || width == null),
       assert(top == null || bottom == null || height == null),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The offset of the child's start edge from the start of the stack.
  final double start;

  /// The offset of the child's top edge from the top of the stack.
  final double top;

  /// The offset of the child's end edge from the end of the stack.
  final double end;

  /// The offset of the child's bottom edge from the bottom of the stack.
  final double bottom;

  /// The child's width.
  ///
  /// Only two out of the three horizontal values ([start], [end], [width]) can
  /// be set. The third must be null.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can
  /// be set. The third must be null.
  final double height;

  @override
  _AnimatedPositionedDirectionalState createState() => _AnimatedPositionedDirectionalState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('start', start, defaultValue: null));
    properties.add(DoubleProperty('top', top, defaultValue: null));
    properties.add(DoubleProperty('end', end, defaultValue: null));
    properties.add(DoubleProperty('bottom', bottom, defaultValue: null));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
  }
}

class _AnimatedPositionedDirectionalState extends AnimatedWidgetBaseState<AnimatedPositionedDirectional> {
  Tween<double> _start;
  Tween<double> _top;
  Tween<double> _end;
  Tween<double> _bottom;
  Tween<double> _width;
  Tween<double> _height;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _start = visitor(_start, widget.start, (dynamic value) => Tween<double>(begin: value));
    _top = visitor(_top, widget.top, (dynamic value) => Tween<double>(begin: value));
    _end = visitor(_end, widget.end, (dynamic value) => Tween<double>(begin: value));
    _bottom = visitor(_bottom, widget.bottom, (dynamic value) => Tween<double>(begin: value));
    _width = visitor(_width, widget.width, (dynamic value) => Tween<double>(begin: value));
    _height = visitor(_height, widget.height, (dynamic value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return Positioned.directional(
      textDirection: Directionality.of(context),
      child: widget.child,
      start: _start?.evaluate(animation),
      top: _top?.evaluate(animation),
      end: _end?.evaluate(animation),
      bottom: _bottom?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(ObjectFlagProperty<Tween<double>>.has('start', _start));
    description.add(ObjectFlagProperty<Tween<double>>.has('top', _top));
    description.add(ObjectFlagProperty<Tween<double>>.has('end', _end));
    description.add(ObjectFlagProperty<Tween<double>>.has('bottom', _bottom));
    description.add(ObjectFlagProperty<Tween<double>>.has('width', _width));
    description.add(ObjectFlagProperty<Tween<double>>.has('height', _height));
  }
}

/// Animated version of [Opacity] which automatically transitions the child's
/// opacity over a given duration whenever the given opacity changes.
///
/// Animating an opacity is relatively expensive because it requires painting
/// the child into an intermediate buffer.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_opacity.mp4}
///
/// {@tool sample}
///
/// ```dart
/// class LogoFade extends StatefulWidget {
///   @override
///   createState() => LogoFadeState();
/// }
///
/// class LogoFadeState extends State<LogoFade> {
///   double opacityLevel = 1.0;
///
///   void _changeOpacity() {
///     setState(() => opacityLevel = opacityLevel == 0 ? 1.0 : 0.0);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       mainAxisAlignment: MainAxisAlignment.center,
///       children: [
///         AnimatedOpacity(
///           opacity: opacityLevel,
///           duration: Duration(seconds: 3),
///           child: FlutterLogo(),
///         ),
///         RaisedButton(
///           child: Text('Fade Logo'),
///           onPressed: _changeOpacity,
///         ),
///       ],
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [FadeTransition], an explicitly animated version of this widget, where
///    an [Animation] is provided by the caller instead of being built in.
class AnimatedOpacity extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates its opacity implicitly.
  ///
  /// The [opacity] argument must not be null and must be between 0.0 and 1.0,
  /// inclusive. The [curve] and [duration] arguments must not be null.
  const AnimatedOpacity({
    Key key,
    this.child,
    @required this.opacity,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(opacity != null && opacity >= 0.0 && opacity <= 1.0),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The target opacity.
  ///
  /// An opacity of 1.0 is fully opaque. An opacity of 0.0 is fully transparent
  /// (i.e., invisible).
  ///
  /// The opacity must not be null.
  final double opacity;

  @override
  _AnimatedOpacityState createState() => _AnimatedOpacityState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
  }
}

class _AnimatedOpacityState extends ImplicitlyAnimatedWidgetState<AnimatedOpacity> {
  Tween<double> _opacity;
  Animation<double> _opacityAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _opacity = visitor(_opacity, widget.opacity, (dynamic value) => Tween<double>(begin: value));
  }

  @override
  void didUpdateTweens() {
    _opacityAnimation = animation.drive(_opacity);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: widget.child,
    );
  }
}

/// Animated version of [DefaultTextStyle] which automatically transitions the
/// default text style (the text style to apply to descendant [Text] widgets
/// without explicit style) over a given duration whenever the given style
/// changes.
///
/// The [textAlign], [softWrap], [textOverflow], and [maxLines] properties are
/// not animated and take effect immediately when changed.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.elasticInOut].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_default_text_style.mp4}
class AnimatedDefaultTextStyle extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates the default text style implicitly.
  ///
  /// The [child], [style], [softWrap], [overflow], [curve], and [duration]
  /// arguments must not be null.
  const AnimatedDefaultTextStyle({
    Key key,
    @required this.child,
    @required this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(style != null),
       assert(child != null),
       assert(softWrap != null),
       assert(overflow != null),
       assert(maxLines == null || maxLines > 0),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The target text style.
  ///
  /// The text style must not be null.
  ///
  /// When this property is changed, the style will be animated over [duration] time.
  final TextStyle style;

  /// How the text should be aligned horizontally.
  ///
  /// This property takes effect immediately when changed, it is not animated.
  final TextAlign textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// This property takes effect immediately when changed, it is not animated.
  ///
  /// See [DefaultTextStyle.softWrap] for more details.
  final bool softWrap;

  /// How visual overflow should be handled.
  ///
  /// This property takes effect immediately when changed, it is not animated.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// This property takes effect immediately when changed, it is not animated.
  ///
  /// See [DefaultTextStyle.maxLines] for more details.
  final int maxLines;

  @override
  _AnimatedDefaultTextStyleState createState() => _AnimatedDefaultTextStyleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    style?.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(FlagProperty('softWrap', value: softWrap, ifTrue: 'wrapping at box width', ifFalse: 'no wrapping except at line break characters', showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
  }
}

class _AnimatedDefaultTextStyleState extends AnimatedWidgetBaseState<AnimatedDefaultTextStyle> {
  TextStyleTween _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(_style, widget.style, (dynamic value) => TextStyleTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: _style.evaluate(animation),
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      child: widget.child,
    );
  }
}

/// Animated version of [PhysicalModel].
///
/// The [borderRadius] and [elevation] are animated.
///
/// The [color] is animated if the [animateColor] property is set; otherwise,
/// the color changes immediately at the start of the animation for the other
/// two properties. This allows the color to be animated independently (e.g.
/// because it is being driven by an [AnimatedTheme]).
///
/// The [shape] is not animated.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.fastOutSlowIn].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_physical_model.mp4}
class AnimatedPhysicalModel extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates the properties of a [PhysicalModel].
  ///
  /// The [child], [shape], [borderRadius], [elevation], [color], [shadowColor], [curve], and
  /// [duration] arguments must not be null. Additionally, [elevation] must be
  /// non-negative.
  ///
  /// Animating [color] is optional and is controlled by the [animateColor] flag.
  ///
  /// Animating [shadowColor] is optional and is controlled by the [animateShadowColor] flag.
  const AnimatedPhysicalModel({
    Key key,
    @required this.child,
    @required this.shape,
    this.clipBehavior = Clip.none,
    this.borderRadius = BorderRadius.zero,
    @required this.elevation,
    @required this.color,
    this.animateColor = true,
    @required this.shadowColor,
    this.animateShadowColor = true,
    Curve curve = Curves.linear,
    @required Duration duration,
  }) : assert(child != null),
       assert(shape != null),
       assert(clipBehavior != null),
       assert(borderRadius != null),
       assert(elevation != null && elevation >= 0.0),
       assert(color != null),
       assert(shadowColor != null),
       assert(animateColor != null),
       assert(animateShadowColor != null),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The type of shape.
  ///
  /// This property is not animated.
  final BoxShape shape;

  /// {@macro flutter.widgets.Clip}
  final Clip clipBehavior;

  /// The target border radius of the rounded corners for a rectangle shape.
  final BorderRadius borderRadius;

  /// The target z-coordinate relative to the parent at which to place this
  /// physical object.
  ///
  /// The value will always be non-negative.
  final double elevation;

  /// The target background color.
  final Color color;

  /// Whether the color should be animated.
  final bool animateColor;

  /// The target shadow color.
  final Color shadowColor;

  /// Whether the shadow color should be animated.
  final bool animateShadowColor;

  @override
  _AnimatedPhysicalModelState createState() => _AnimatedPhysicalModelState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxShape>('shape', shape));
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(DiagnosticsProperty<Color>('color', color));
    properties.add(DiagnosticsProperty<bool>('animateColor', animateColor));
    properties.add(DiagnosticsProperty<Color>('shadowColor', shadowColor));
    properties.add(DiagnosticsProperty<bool>('animateShadowColor', animateShadowColor));
  }
}

class _AnimatedPhysicalModelState extends AnimatedWidgetBaseState<AnimatedPhysicalModel> {
  BorderRadiusTween _borderRadius;
  Tween<double> _elevation;
  ColorTween _color;
  ColorTween _shadowColor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _borderRadius = visitor(_borderRadius, widget.borderRadius, (dynamic value) => BorderRadiusTween(begin: value));
    _elevation = visitor(_elevation, widget.elevation, (dynamic value) => Tween<double>(begin: value));
    _color = visitor(_color, widget.color, (dynamic value) => ColorTween(begin: value));
    _shadowColor = visitor(_shadowColor, widget.shadowColor, (dynamic value) => ColorTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      child: widget.child,
      shape: widget.shape,
      clipBehavior: widget.clipBehavior,
      borderRadius: _borderRadius.evaluate(animation),
      elevation: _elevation.evaluate(animation),
      color: widget.animateColor ? _color.evaluate(animation) : widget.color,
      shadowColor: widget.animateShadowColor
          ? _shadowColor.evaluate(animation)
          : widget.shadowColor,
    );
  }
}
