// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'text.dart';
import 'ticker_provider.dart';

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
/// Typically this will only have useful results if the [begin] and [end]
/// decorations have the same type; decorations of differing types generally do
/// not have a useful animation defined, and will just jump to the [end]
/// immediately.
///
/// See [Tween] for a discussion on how to use interpolation objects.
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
    final Vector3 beginTranslation = new Vector3.zero();
    final Vector3 endTranslation = new Vector3.zero();
    final Quaternion beginRotation = new Quaternion.identity();
    final Quaternion endRotation = new Quaternion.identity();
    final Vector3 beginScale = new Vector3.zero();
    final Vector3 endScale = new Vector3.zero();
    begin.decompose(beginTranslation, beginRotation, beginScale);
    end.decompose(endTranslation, endRotation, endScale);
    final Vector3 lerpTranslation =
        beginTranslation * (1.0 - t) + endTranslation * t;
    // TODO(alangardner): Implement slerp for constant rotation
    final Quaternion lerpRotation =
        (beginRotation.scaled(1.0 - t) + endRotation.scaled(t)).normalized();
    final Vector3 lerpScale = beginScale * (1.0 - t) + endScale * t;
    return new Matrix4.compose(lerpTranslation, lerpRotation, lerpScale);
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
    this.curve: Curves.linear,
    @required this.duration
  }) : assert(curve != null),
       assert(duration != null),
       super(key: key);

  /// The curve to apply when animating the parameters of this container.
  final Curve curve;

  /// The duration over which to animate the parameters of this container.
  final Duration duration;

  @override
  AnimatedWidgetBaseState<ImplicitlyAnimatedWidget> createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
  }
}

/// Signature for a [Tween] factory.
///
/// This is the type of one of the arguments of [TweenVisitor], the signature
/// used by [AnimatedWidgetBaseState.forEachTween].
typedef Tween<T> TweenConstructor<T>(T targetValue);

/// Signature for callbacks passed to [AnimatedWidgetBaseState.forEachTween].
typedef Tween<T> TweenVisitor<T>(Tween<T> tween, T targetValue, TweenConstructor<T> constructor);

/// A base class for widgets with implicit animations.
///
/// Subclasses must implement the [forEachTween] method to help
/// [AnimatedWidgetBaseState] iterate through the subclasses' widget's fields
/// and animate them.
abstract class AnimatedWidgetBaseState<T extends ImplicitlyAnimatedWidget> extends State<T> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  /// The animation driving this widget's implicit animations.
  Animation<double> get animation => _animation;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: widget.duration,
      debugLabel: '${widget.toStringShort()}',
      vsync: this,
    )..addListener(_handleAnimationChanged);
    _updateCurve();
    _constructTweens();
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
    }
  }

  void _updateCurve() {
    if (widget.curve != null)
      _animation = new CurvedAnimation(parent: _controller, curve: widget.curve);
    else
      _animation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationChanged() {
    setState(() { });
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
  /// value to use as the current value the next time that the forEachTween()
  /// method is called.
  void forEachTween(TweenVisitor<dynamic> visitor);
}

/// A container that gradually changes its values over a period of time.
///
/// The [AnimatedContainer] will automatically animate between the old and
/// new values of properties when they change using the provided curve and
/// duration. Properties that are null are not animated.
///
/// This class is useful for generating simple implicit transitions between
/// different parameters to [Container] with its internal [AnimationController].
/// For more complex animations, you'll likely want to use a subclass of
/// [AnimatedWidget] such as the [DecoratedBoxTransition] or use your own
/// [AnimationController].
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
    Curve curve: Curves.linear,
    @required Duration duration,
  }) : assert(margin == null || margin.isNonNegative),
       assert(padding == null || padding.isNonNegative),
       assert(decoration == null || decoration.debugAssertIsValid()),
       assert(constraints == null || constraints.debugAssertIsValid()),
       assert(color == null || decoration == null,
         'Cannot provide both a color and a decoration\n'
         'The color argument is just a shorthand for "decoration: new BoxDecoration(backgroundColor: color)".'
       ),
       decoration = decoration ?? (color != null ? new BoxDecoration(color: color) : null),
       constraints =
        (width != null || height != null)
          ? constraints?.tighten(width: width, height: height)
            ?? new BoxConstraints.tightFor(width: width, height: height)
          : constraints,
       super(key: key, curve: curve, duration: duration);

  /// The [child] contained by the container.
  ///
  /// If null, and if the [constraints] are unbounded or also null, the
  /// container will expand to fill all available space in its parent, unless
  /// the parent provides unbounded constraints, in which case the container
  /// will attempt to be as small as possible.
  final Widget child;

  /// Align the [child] within the container.
  ///
  /// If non-null, the container will expand to fill its parent and position its
  /// child within itself according to the given value. If the incoming
  /// constraints are unbounded, then the child will be shrink-wrapped instead.
  ///
  /// Ignored if [child] is null.
  final FractionalOffsetGeometry alignment;

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
  _AnimatedContainerState createState() => new _AnimatedContainerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<FractionalOffsetGeometry>('alignment', alignment, showName: false, defaultValue: null));
    description.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    description.add(new DiagnosticsProperty<Decoration>('bg', decoration, defaultValue: null));
    description.add(new DiagnosticsProperty<Decoration>('fg', foregroundDecoration, defaultValue: null));
    description.add(new DiagnosticsProperty<BoxConstraints>('constraints', constraints, defaultValue: null, showName: false));
    description.add(new DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    description.add(new ObjectFlagProperty<Matrix4>.has('transform', transform));
  }
}

class _AnimatedContainerState extends AnimatedWidgetBaseState<AnimatedContainer> {
  FractionalOffsetGeometryTween _alignment;
  EdgeInsetsGeometryTween _padding;
  DecorationTween _decoration;
  DecorationTween _foregroundDecoration;
  BoxConstraintsTween _constraints;
  EdgeInsetsGeometryTween _margin;
  Matrix4Tween _transform;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(_alignment, widget.alignment, (dynamic value) => new FractionalOffsetGeometryTween(begin: value));
    _padding = visitor(_padding, widget.padding, (dynamic value) => new EdgeInsetsGeometryTween(begin: value));
    _decoration = visitor(_decoration, widget.decoration, (dynamic value) => new DecorationTween(begin: value));
    _foregroundDecoration = visitor(_foregroundDecoration, widget.foregroundDecoration, (dynamic value) => new DecorationTween(begin: value));
    _constraints = visitor(_constraints, widget.constraints, (dynamic value) => new BoxConstraintsTween(begin: value));
    _margin = visitor(_margin, widget.margin, (dynamic value) => new EdgeInsetsGeometryTween(begin: value));
    _transform = visitor(_transform, widget.transform, (dynamic value) => new Matrix4Tween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
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
    description.add(new DiagnosticsProperty<FractionalOffsetGeometryTween>('alignment', _alignment, showName: false, defaultValue: null));
    description.add(new DiagnosticsProperty<EdgeInsetsGeometryTween>('padding', _padding, defaultValue: null));
    description.add(new DiagnosticsProperty<DecorationTween>('bg', _decoration, defaultValue: null));
    description.add(new DiagnosticsProperty<DecorationTween>('fg', _foregroundDecoration, defaultValue: null));
    description.add(new DiagnosticsProperty<BoxConstraintsTween>('constraints', _constraints, showName: false, defaultValue: null));
    description.add(new DiagnosticsProperty<EdgeInsetsGeometryTween>('margin', _margin, defaultValue: null));
    description.add(new ObjectFlagProperty<Matrix4Tween>.has('transform', _transform));
  }
}

/// Animated version of [Positioned] which automatically transitions the child's
/// position over a given duration whenever the given position changes.
///
/// Only works if it's the child of a [Stack].
///
/// See also:
///
///  * [AnimatedPositionedDirectional], which adapts to the ambient
///    [Directionality].
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
    Curve curve: Curves.linear,
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
    Curve curve: Curves.linear,
    @required Duration duration
  }) : left = rect.left,
       top = rect.top,
       width = rect.width,
       height = rect.height,
       right = null,
       bottom = null,
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
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
  /// Only two out of the three horizontal values (left, right, width) can be
  /// set. The third must be null.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values (top, bottom, height) can be
  /// set. The third must be null.
  final double height;

  @override
  _AnimatedPositionedState createState() => new _AnimatedPositionedState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('left', left, defaultValue: null));
    description.add(new DoubleProperty('top', top, defaultValue: null));
    description.add(new DoubleProperty('right', right, defaultValue: null));
    description.add(new DoubleProperty('bottom', bottom, defaultValue: null));
    description.add(new DoubleProperty('width', width, defaultValue: null));
    description.add(new DoubleProperty('height', height, defaultValue: null));
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
    _left = visitor(_left, widget.left, (dynamic value) => new Tween<double>(begin: value));
    _top = visitor(_top, widget.top, (dynamic value) => new Tween<double>(begin: value));
    _right = visitor(_right, widget.right, (dynamic value) => new Tween<double>(begin: value));
    _bottom = visitor(_bottom, widget.bottom, (dynamic value) => new Tween<double>(begin: value));
    _width = visitor(_width, widget.width, (dynamic value) => new Tween<double>(begin: value));
    _height = visitor(_height, widget.height, (dynamic value) => new Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return new Positioned(
      child: widget.child,
      left: _left?.evaluate(animation),
      top: _top?.evaluate(animation),
      right: _right?.evaluate(animation),
      bottom: _bottom?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation)
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new ObjectFlagProperty<Tween<double>>.has('left', _left));
    description.add(new ObjectFlagProperty<Tween<double>>.has('top', _top));
    description.add(new ObjectFlagProperty<Tween<double>>.has('right', _right));
    description.add(new ObjectFlagProperty<Tween<double>>.has('bottom', _bottom));
    description.add(new ObjectFlagProperty<Tween<double>>.has('width', _width));
    description.add(new ObjectFlagProperty<Tween<double>>.has('height', _height));
  }
}

/// Animated version of [PositionedDirectional] which automatically transitions the child's
/// position over a given duration whenever the given position changes.
///
/// Only works if it's the child of a [Stack].
///
/// See also:
///
///  * [AnimatedPositioned], which specifies the widget's position visually.
class AnimatedPositionedDirectional extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates its position implicitly.
  ///
  /// Only two out of the three horizontal values ([start], [end],
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
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
    Curve curve: Curves.linear,
    @required Duration duration,
  }) : assert(start == null || end == null || width == null),
       assert(top == null || bottom == null || height == null),
      super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
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
  /// Only two out of the three horizontal values (start, end, width) can be
  /// set. The third must be null.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values (top, bottom, height) can be
  /// set. The third must be null.
  final double height;

  @override
  _AnimatedPositionedDirectionalState createState() => new _AnimatedPositionedDirectionalState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('start', start, defaultValue: null));
    description.add(new DoubleProperty('top', top, defaultValue: null));
    description.add(new DoubleProperty('end', end, defaultValue: null));
    description.add(new DoubleProperty('bottom', bottom, defaultValue: null));
    description.add(new DoubleProperty('width', width, defaultValue: null));
    description.add(new DoubleProperty('height', height, defaultValue: null));
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
    _start = visitor(_start, widget.start, (dynamic value) => new Tween<double>(begin: value));
    _top = visitor(_top, widget.top, (dynamic value) => new Tween<double>(begin: value));
    _end = visitor(_end, widget.end, (dynamic value) => new Tween<double>(begin: value));
    _bottom = visitor(_bottom, widget.bottom, (dynamic value) => new Tween<double>(begin: value));
    _width = visitor(_width, widget.width, (dynamic value) => new Tween<double>(begin: value));
    _height = visitor(_height, widget.height, (dynamic value) => new Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return new PositionedDirectional(
      child: widget.child,
      start: _start?.evaluate(animation),
      top: _top?.evaluate(animation),
      end: _end?.evaluate(animation),
      bottom: _bottom?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation)
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new ObjectFlagProperty<Tween<double>>.has('start', _start));
    description.add(new ObjectFlagProperty<Tween<double>>.has('top', _top));
    description.add(new ObjectFlagProperty<Tween<double>>.has('end', _end));
    description.add(new ObjectFlagProperty<Tween<double>>.has('bottom', _bottom));
    description.add(new ObjectFlagProperty<Tween<double>>.has('width', _width));
    description.add(new ObjectFlagProperty<Tween<double>>.has('height', _height));
  }
}

/// Animated version of [Opacity] which automatically transitions the child's
/// opacity over a given duration whenever the given opacity changes.
///
/// Animating an opacity is relatively expensive because it requires painting
/// the child into an intermediate buffer.
class AnimatedOpacity extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates its opacity implicitly.
  ///
  /// The [opacity] argument must not be null and must be between 0.0 and 1.0,
  /// inclusive. The [curve] and [duration] arguments must not be null.
  const AnimatedOpacity({
    Key key,
    this.child,
    @required this.opacity,
    Curve curve: Curves.linear,
    @required Duration duration,
  }) : assert(opacity != null && opacity >= 0.0 && opacity <= 1.0),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The target opacity.
  ///
  /// An opacity of 1.0 is fully opaque. An opacity of 0.0 is fully transparent
  /// (i.e., invisible).
  ///
  /// The opacity must not be null.
  final double opacity;

  @override
  _AnimatedOpacityState createState() => new _AnimatedOpacityState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('opacity', opacity));
  }
}

class _AnimatedOpacityState extends AnimatedWidgetBaseState<AnimatedOpacity> {
  Tween<double> _opacity;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _opacity = visitor(_opacity, widget.opacity, (dynamic value) => new Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return new Opacity(
      opacity: _opacity.evaluate(animation),
      child: widget.child
    );
  }
}

/// Animated version of [DefaultTextStyle] which automatically transitions the
/// default text style (the text style to apply to descendant [Text] widgets
/// without explicit style) over a given duration whenever the given style
/// changes.
class AnimatedDefaultTextStyle extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates the default text style implicitly.
  ///
  /// The [child], [style], [curve], and [duration] arguments must not be null.
  const AnimatedDefaultTextStyle({
    Key key,
    @required this.child,
    @required this.style,
    Curve curve: Curves.linear,
    @required Duration duration,
  }) : assert(style != null),
       assert(child != null),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The target text style.
  ///
  /// The text style must not be null.
  final TextStyle style;

  @override
  _AnimatedDefaultTextStyleState createState() => new _AnimatedDefaultTextStyleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    style?.debugFillProperties(description);
  }
}

class _AnimatedDefaultTextStyleState extends AnimatedWidgetBaseState<AnimatedDefaultTextStyle> {
  TextStyleTween _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(_style, widget.style, (dynamic value) => new TextStyleTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTextStyle(
      style: _style.evaluate(animation),
      child: widget.child
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
class AnimatedPhysicalModel extends ImplicitlyAnimatedWidget {
  /// Creates a widget that animates the properties of a [PhysicalModel].
  ///
  /// The [child], [shape], [borderRadius], [elevation], [color], [curve], and
  /// [duration] arguments must not be null.
  ///
  /// Animating [color] is optional and is controlled by the [animateColor] flag.
  const AnimatedPhysicalModel({
    Key key,
    @required this.child,
    @required this.shape,
    this.borderRadius: BorderRadius.zero,
    @required this.elevation,
    @required this.color,
    this.animateColor: true,
    Curve curve: Curves.linear,
    @required Duration duration,
  }) : assert(child != null),
       assert(shape != null),
       assert(borderRadius != null),
       assert(elevation != null),
       assert(color != null),
       super(key: key, curve: curve, duration: duration);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The type of shape.
  ///
  /// This property is not animated.
  final BoxShape shape;

  /// The target border radius of the rounded corners for a rectangle shape.
  final BorderRadius borderRadius;

  /// The target z-coordinate at which to place this physical object.
  final double elevation;

  /// The target background color.
  final Color color;

  /// Whether the color should be animated.
  final bool animateColor;

  @override
  _AnimatedPhysicalModelState createState() => new _AnimatedPhysicalModelState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new EnumProperty<BoxShape>('shape', shape));
    description.add(new DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    description.add(new DoubleProperty('elevation', elevation));
    description.add(new DiagnosticsProperty<Color>('color', color));
    description.add(new DiagnosticsProperty<bool>('animateColor', animateColor));
  }
}

class _AnimatedPhysicalModelState extends AnimatedWidgetBaseState<AnimatedPhysicalModel> {
  BorderRadiusTween _borderRadius;
  Tween<double> _elevation;
  ColorTween _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _borderRadius = visitor(_borderRadius, widget.borderRadius, (dynamic value) => new BorderRadiusTween(begin: value));
    _elevation = visitor(_elevation, widget.elevation, (dynamic value) => new Tween<double>(begin: value));
    _color = visitor(_color, widget.color, (dynamic value) => new ColorTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return new PhysicalModel(
      child: widget.child,
      shape: widget.shape,
      borderRadius: _borderRadius.evaluate(animation),
      elevation: _elevation.evaluate(animation),
      color: widget.animateColor ? _color.evaluate(animation) : widget.color,
    );
  }
}
