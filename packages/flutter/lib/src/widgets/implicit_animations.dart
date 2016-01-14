// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';

import 'package:vector_math/vector_math_64.dart';

/// An animated value that interpolates [BoxConstraint]s.
class AnimatedBoxConstraintsValue extends AnimatedValue<BoxConstraints> {
  AnimatedBoxConstraintsValue(BoxConstraints begin, { BoxConstraints end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  BoxConstraints lerp(double t) => BoxConstraints.lerp(begin, end, t);
}

/// An animated value that interpolates [Decoration]s.
class AnimatedDecorationValue extends AnimatedValue<Decoration> {
  AnimatedDecorationValue(Decoration begin, { Decoration end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Decoration lerp(double t) {
    if (begin == null && end == null)
      return null;
    if (end == null)
      return begin.lerpTo(end, t);
    return end.lerpFrom(begin, t);
  }
}

/// An animated value that interpolates [EdgeDims].
class AnimatedEdgeDimsValue extends AnimatedValue<EdgeDims> {
  AnimatedEdgeDimsValue(EdgeDims begin, { EdgeDims end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  EdgeDims lerp(double t) => EdgeDims.lerp(begin, end, t);
}

/// An animated value that interpolates [Matrix4]s.
///
/// Currently this class works only for translations.
class AnimatedMatrix4Value extends AnimatedValue<Matrix4> {
  AnimatedMatrix4Value(Matrix4 begin, { Matrix4 end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Matrix4 lerp(double t) {
    // TODO(mpcomplete): Animate the full matrix. Will animating the cells
    // separately work?
    Vector3 beginT = begin.getTranslation();
    Vector3 endT = end.getTranslation();
    Vector3 lerpT = beginT*(1.0-t) + endT*t;
    return new Matrix4.identity()..translate(lerpT);
  }
}

/// An abstract widget for building components that gradually change their
/// values over a period of time.
abstract class AnimatedWidgetBase extends StatefulComponent {
  AnimatedWidgetBase({
    Key key,
    this.curve: Curves.linear,
    this.duration
  }) : super(key: key) {
    assert(curve != null);
    assert(duration != null);
  }

  /// The curve to apply when animating the parameters of this container.
  final Curve curve;

  /// The duration over which to animate the parameters of this container.
  final Duration duration;

  AnimatedWidgetBaseState createState();

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('duration: ${duration.inMilliseconds}ms');
  }
}

typedef AnimatedValue<T> VariableConstructor<T>(T targetValue);
typedef AnimatedValue<T> VariableVisitor<T>(AnimatedValue<T> variable, T targetValue, VariableConstructor<T> constructor);

abstract class AnimatedWidgetBaseState<T extends AnimatedWidgetBase> extends State<T> {
  Performance _performanceController;
  PerformanceView _performance;

  void initState() {
    super.initState();
    _performanceController = new Performance(
      duration: config.duration,
      debugLabel: '${config.toStringShort()}'
    );
    _updateCurve();
    _configAllVariables();
  }

  void didUpdateConfig(T oldConfig) {
    if (config.curve != oldConfig.curve)
      _updateCurve();
    _performanceController.duration = config.duration;
    if (_configAllVariables()) {
      forEachVariable((AnimatedValue variable, dynamic targetValue, VariableConstructor<T> constructor) {
        _updateBeginValue(variable); return variable;
      });
      _performanceController.progress = 0.0;
      _performanceController.play();
    }
  }

  void _updateCurve() {
    _performance?.removeListener(_updateAllVariables);
    if (config.curve != null)
      _performance = new CurvedPerformance(_performanceController, curve: config.curve);
    else
      _performance = _performanceController;
    _performance.addListener(_updateAllVariables);
  }

  void dispose() {
    _performanceController.stop();
    super.dispose();
  }

  void _updateVariable(Animatable variable) {
    if (variable != null)
      _performance.updateVariable(variable);
  }

  void _updateAllVariables() {
    setState(() {
      forEachVariable((AnimatedValue variable, dynamic targetValue, VariableConstructor<T> constructor) {
        _updateVariable(variable); return variable;
      });
    });
  }

  bool _updateEndValue(AnimatedValue variable, dynamic targetValue) {
    if (targetValue == variable.end)
      return false;
    variable.end = targetValue;
    return true;
  }

  void _updateBeginValue(AnimatedValue variable) {
    variable?.begin = variable.value;
  }

  bool _configAllVariables() {
    bool startAnimation = false;
    forEachVariable((AnimatedValue variable, dynamic targetValue, VariableConstructor<T> constructor) { 
      if (targetValue != null) {
        variable ??= constructor(targetValue);
        if (_updateEndValue(variable, targetValue))
          startAnimation = true;
      } else {
        variable = null;
      }
      return variable;
    });
    return startAnimation;
  }

  /// Subclasses must implement this function by running through the following
  /// steps for for each animatable facet in the class:
  ///
  /// 1. Call the visitor callback with three arguments, the first argument
  /// being the current value of the AnimatedValue<T> object that represents the
  /// variable (initially null), the second argument, of type T, being the value
  /// on the Widget (config) that represents the current target value of the
  /// variable, and the third being a callback that takes a value T (which will
  /// be the second argument to the visitor callback), and that returns an
  /// AnimatedValue<T> object for the variable, configured with the given value
  /// as the begin value.
  ///
  /// 2. Take the value returned from the callback, and store it. This is the
  /// value to use as the current value the next time that the forEachVariable()
  /// method is called.
  void forEachVariable(VariableVisitor visitor);
}

/// A container that gradually changes its values over a period of time.
///
/// This class is useful for generating simple implicit transitions between
/// different parameters to [Container]. For more complex animations, you'll
/// likely want to use a subclass of [Transition] or control a [Performance]
/// yourself.
class AnimatedContainer extends AnimatedWidgetBase {
  AnimatedContainer({
    Key key,
    this.child,
    this.constraints,
    this.decoration,
    this.foregroundDecoration,
    this.margin,
    this.padding,
    this.transform,
    this.width,
    this.height,
    Curve curve: Curves.linear,
    Duration duration
  }) : super(key: key, curve: curve, duration: duration) {
    assert(decoration == null || decoration.debugAssertValid());
    assert(foregroundDecoration == null || foregroundDecoration.debugAssertValid());
    assert(margin == null || margin.isNonNegative);
    assert(padding == null || padding.isNonNegative);
  }

  final Widget child;

  /// Additional constraints to apply to the child.
  final BoxConstraints constraints;

  /// The decoration to paint behind the child.
  final Decoration decoration;

  /// The decoration to paint in front of the child.
  final Decoration foregroundDecoration;

  /// Empty space to surround the decoration.
  final EdgeDims margin;

  /// Empty space to inscribe inside the decoration.
  final EdgeDims padding;

  /// The transformation matrix to apply before painting the container.
  final Matrix4 transform;

  /// If non-null, requires the decoration to have this width.
  final double width;

  /// If non-null, requires the decoration to have this height.
  final double height;

  _AnimatedContainerState createState() => new _AnimatedContainerState();

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (constraints != null)
      description.add('$constraints');
    if (decoration != null)
      description.add('has background');
    if (foregroundDecoration != null)
      description.add('has foreground');
    if (margin != null)
      description.add('margin: $margin');
    if (padding != null)
      description.add('padding: $padding');
    if (transform != null)
      description.add('has transform');
    if (width != null)
      description.add('width: $width');
    if (height != null)
      description.add('height: $height');
  }
}

class _AnimatedContainerState extends AnimatedWidgetBaseState<AnimatedContainer> {
  AnimatedBoxConstraintsValue _constraints;
  AnimatedDecorationValue _decoration;
  AnimatedDecorationValue _foregroundDecoration;
  AnimatedEdgeDimsValue _margin;
  AnimatedEdgeDimsValue _padding;
  AnimatedMatrix4Value _transform;
  AnimatedValue<double> _width;
  AnimatedValue<double> _height;

  void forEachVariable(VariableVisitor visitor) {
    // TODO(ianh): Use constructor tear-offs when it becomes possible
    _constraints = visitor(_constraints, config.constraints, (dynamic value) => new AnimatedBoxConstraintsValue(value));
    _decoration = visitor(_decoration, config.decoration, (dynamic value) => new AnimatedDecorationValue(value));
    _foregroundDecoration = visitor(_foregroundDecoration, config.foregroundDecoration, (dynamic value) => new AnimatedDecorationValue(value));
    _margin = visitor(_margin, config.margin, (dynamic value) => new AnimatedEdgeDimsValue(value));
    _padding = visitor(_padding, config.padding, (dynamic value) => new AnimatedEdgeDimsValue(value));
    _transform = visitor(_transform, config.transform, (dynamic value) => new AnimatedMatrix4Value(value));
    _width = visitor(_width, config.width, (dynamic value) => new AnimatedValue<double>(value));
    _height = visitor(_height, config.height, (dynamic value) => new AnimatedValue<double>(value));
  }

  Widget build(BuildContext context) {
    return new Container(
      child: config.child,
      constraints: _constraints?.value,
      decoration: _decoration?.value,
      foregroundDecoration: _foregroundDecoration?.value,
      margin: _margin?.value,
      padding: _padding?.value,
      transform: _transform?.value,
      width: _width?.value,
      height: _height?.value
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (_constraints != null)
      description.add('has constraints');
    if (_decoration != null)
      description.add('has background');
    if (_foregroundDecoration != null)
      description.add('has foreground');
    if (_margin != null)
      description.add('has margin');
    if (_padding != null)
      description.add('has padding');
    if (_transform != null)
      description.add('has transform');
    if (_width != null)
      description.add('has width');
    if (_height != null)
      description.add('has height');
  }
}

/// Animated version of [Positioned] which automatically transitions the child's
/// position over a given duration whenever the given positon changes.
///
/// Only works if it's the child of a [Stack].
class AnimatedPositioned extends AnimatedWidgetBase {
  AnimatedPositioned({
    Key key,
    this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    Curve curve: Curves.linear,
    Duration duration
  }) : super(key: key, curve: curve, duration: duration) {
    assert(left == null || right == null || width == null);
    assert(top == null || bottom == null || height == null);
  }

  AnimatedPositioned.fromRect({
    Key key,
    this.child,
    Rect rect,
    Curve curve: Curves.linear,
    Duration duration
  }) : left = rect.left,
       top = rect.top,
       width = rect.width,
       height = rect.height,
       right = null,
       bottom = null,
       super(key: key, curve: curve, duration: duration);

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

  _AnimatedPositionedState createState() => new _AnimatedPositionedState();
}

class _AnimatedPositionedState extends AnimatedWidgetBaseState<AnimatedPositioned> {
  AnimatedValue<double> _left;
  AnimatedValue<double> _top;
  AnimatedValue<double> _right;
  AnimatedValue<double> _bottom;
  AnimatedValue<double> _width;
  AnimatedValue<double> _height;

  void forEachVariable(VariableVisitor visitor) {
    // TODO(ianh): Use constructor tear-offs when it becomes possible
    _left = visitor(_left, config.left, (dynamic value) => new AnimatedValue<double>(value));
    _top = visitor(_top, config.top, (dynamic value) => new AnimatedValue<double>(value));
    _right = visitor(_right, config.right, (dynamic value) => new AnimatedValue<double>(value));
    _bottom = visitor(_bottom, config.bottom, (dynamic value) => new AnimatedValue<double>(value));
    _width = visitor(_width, config.width, (dynamic value) => new AnimatedValue<double>(value));
    _height = visitor(_height, config.height, (dynamic value) => new AnimatedValue<double>(value));
  }

  Widget build(BuildContext context) {
    return new Positioned(
      child: config.child,
      left: _left?.value,
      top: _top?.value,
      right: _right?.value,
      bottom: _bottom?.value,
      width: _width?.value,
      height: _height?.value
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (_left != null)
      description.add('has left');
    if (_top != null)
      description.add('has top');
    if (_right != null)
      description.add('has right');
    if (_bottom != null)
      description.add('has bottom');
    if (_width != null)
      description.add('has width');
    if (_height != null)
      description.add('has height');
  }
}
