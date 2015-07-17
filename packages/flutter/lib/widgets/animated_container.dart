// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vector_math/vector_math.dart';

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/base/lerp.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/animated_component.dart';

class AnimatedBoxConstraintsValue extends AnimatedType<BoxConstraints> {
  AnimatedBoxConstraintsValue(BoxConstraints begin, { BoxConstraints end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setFraction(double t) {
    // TODO(abarth): We should lerp the BoxConstraints.
    value = end;
  }
}

class AnimatedBoxDecorationValue extends AnimatedType<BoxDecoration> {
  AnimatedBoxDecorationValue(BoxDecoration begin, { BoxDecoration end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setFraction(double t) {
    if (t == 1.0) {
      value = end;
      return;
    }
    value = lerpBoxDecoration(begin, end, t);
  }
}

class AnimatedEdgeDimsValue extends AnimatedType<EdgeDims> {
  AnimatedEdgeDimsValue(EdgeDims begin, { EdgeDims end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setFraction(double t) {
    if (t == 1.0) {
      value = end;
      return;
    }
    value = new EdgeDims(
      lerpNum(begin.top, end.top, t),
      lerpNum(begin.right, end.right, t),
      lerpNum(begin.bottom, end.bottom, t),
      lerpNum(begin.bottom, end.left, t)
    );
  }
}

class ImplicitlyAnimatedValue<T> {
  final AnimationPerformance performance = new AnimationPerformance();
  final AnimatedType<T> _variable;

  ImplicitlyAnimatedValue(this._variable, Duration duration) {
    performance
      ..variable = _variable
      ..duration = duration;
  }

  T get value => _variable.value;
  void set value(T newValue) {
    _variable.begin = _variable.value;
    _variable.end = newValue;
    if (_variable.value != _variable.end) {
      performance
        ..progress = 0.0
        ..play();
    }
  }
}

class AnimatedContainer extends AnimatedComponent {
  AnimatedContainer({
    String key,
    this.child,
    this.duration,
    this.constraints,
    this.decoration,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.transform
  }) : super(key: key);

  Widget child;
  Duration duration; // TODO(abarth): Support separate durations for each value.
  BoxConstraints constraints;
  BoxDecoration decoration;
  EdgeDims margin;
  EdgeDims padding;
  Matrix4 transform;
  double width;
  double height;

  ImplicitlyAnimatedValue<BoxConstraints> _constraints;
  ImplicitlyAnimatedValue<BoxDecoration> _decoration;
  ImplicitlyAnimatedValue<EdgeDims> _margin;
  ImplicitlyAnimatedValue<EdgeDims> _padding;
  ImplicitlyAnimatedValue<Matrix4> _transform;
  ImplicitlyAnimatedValue<double> _width;
  ImplicitlyAnimatedValue<double> _height;

  void initState() {
    _updateFields();
  }

  void syncFields(AnimatedContainer source) {
    child = source.child;
    constraints = source.constraints;
    decoration = source.decoration;
    margin = source.margin;
    padding = source.padding;
    width = source.width;
    height = source.height;
    _updateFields();
  }

  void _updateFields() {
    _updateConstraints();
    _updateDecoration();
    _updateMargin();
    _updatePadding();
    _updateTransform();
    _updateWidth();
    _updateHeight();
  }

  void _updateField(dynamic value, ImplicitlyAnimatedValue animatedValue, Function initField) {
    if (animatedValue != null)
      animatedValue.value = value;
    else if (value != null)
      initField();
  }

  void _updateConstraints() {
    _updateField(constraints, _constraints, () {
      _constraints = new ImplicitlyAnimatedValue<BoxConstraints>(new AnimatedBoxConstraintsValue(constraints), duration);
      watch(_constraints.performance);
    });
  }

  void _updateDecoration() {
    _updateField(decoration, _decoration, () {
      _decoration = new ImplicitlyAnimatedValue<BoxDecoration>(new AnimatedBoxDecorationValue(decoration), duration);
      watch(_decoration.performance);
    });
  }

  void _updateMargin() {
    _updateField(margin, _margin, () {
      _margin = new ImplicitlyAnimatedValue<EdgeDims>(new AnimatedEdgeDimsValue(margin), duration);
      watch(_margin.performance);
    });
  }

  void _updatePadding() {
    _updateField(padding, _padding, () {
      _padding = new ImplicitlyAnimatedValue<EdgeDims>(new AnimatedEdgeDimsValue(padding), duration);
      watch(_padding.performance);
    });
  }

  void _updateTransform() {
    _updateField(transform, _transform, () {
      _transform = new ImplicitlyAnimatedValue<Matrix4>(new AnimatedType<Matrix4>(transform), duration);
      watch(_transform.performance);
    });
  }

  void _updateWidth() {
    _updateField(width, _width, () {
      _width = new ImplicitlyAnimatedValue<double>(new AnimatedType<double>(width), duration);
      watch(_width.performance);
    });
  }

  void _updateHeight() {
    _updateField(height, _height, () {
      _height = new ImplicitlyAnimatedValue<double>( new AnimatedType<double>(height), duration);
      watch(_height.performance);
    });
  }

  dynamic _getValue(dynamic value, ImplicitlyAnimatedValue animatedValue) {
    return animatedValue == null ? value : animatedValue.value;
  }

  Widget build() {
    return new Container(
      child: child,
      constraints:  _getValue(constraints, _constraints),
      decoration: _getValue(decoration, _decoration),
      margin: _getValue(margin, _margin),
      padding: _getValue(padding, _padding),
      transform: _getValue(transform, _transform),
      width: _getValue(width, _width),
      height: _getValue(height, _height)
    );
  }
}
