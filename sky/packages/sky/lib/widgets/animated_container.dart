// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vector_math/vector_math.dart';

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/base/lerp.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/animated_component.dart';

class AnimatedBoxConstraintsValue extends AnimatedValue<BoxConstraints> {
  AnimatedBoxConstraintsValue(BoxConstraints begin, { BoxConstraints end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setProgress(double t) {
    // TODO(abarth): We should lerp the BoxConstraints.
    value = end;
  }
}

class AnimatedBoxDecorationValue extends AnimatedValue<BoxDecoration> {
  AnimatedBoxDecorationValue(BoxDecoration begin, { BoxDecoration end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setProgress(double t) {
    if (t == 1.0) {
      value = end;
      return;
    }
    value = lerpBoxDecoration(begin, end, t);
  }
}

class AnimatedEdgeDimsValue extends AnimatedValue<EdgeDims> {
  AnimatedEdgeDimsValue(EdgeDims begin, { EdgeDims end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setProgress(double t) {
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

class AnimatedMatrix4Value extends AnimatedValue<Matrix4> {
  AnimatedMatrix4Value(Matrix4 begin, { Matrix4 end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setProgress(double t) {
    if (t == 1.0) {
      value = end;
      return;
    }
    // TODO(mpcomplete): Animate the full matrix. Will animating the cells
    // separately work?
    Vector3 beginT = begin.getTranslation();
    Vector3 endT = end.getTranslation();
    Vector3 lerpT = beginT*(1.0-t) + endT*t;
    value = new Matrix4.identity()..translate(lerpT);
  }
}

abstract class AnimationBehavior {
  void initFields(AnimatedContainer original);
  void syncFields(AnimatedContainer original, AnimatedContainer updated);
}

class ImplicitlyAnimatedValue<T> {
  final AnimationPerformance performance = new AnimationPerformance();
  final AnimatedValue<T> _variable;

  ImplicitlyAnimatedValue(this._variable, Duration duration) {
    performance
      ..variable = _variable
      ..duration = duration;
  }

  T get value => _variable.value;
  void animateTo(T newValue) {
    _variable.begin = _variable.value;
    _variable.end = newValue;
    if (_variable.value != _variable.end) {
      performance
        ..progress = 0.0
        ..play();
    }
  }
}

abstract class ImplicitlyAnimatedFieldBehavior<T> extends AnimationBehavior {
  ImplicitlyAnimatedFieldBehavior(this.duration);

  Duration duration;
  ImplicitlyAnimatedValue<T> field;

  // Overrides.
  T getter(AnimatedContainer container);
  void setter(AnimatedContainer container, T value);
  AnimatedValue<T> initField(T value);

  void initFields(AnimatedContainer original) {
    _updateField(original, getter(original));
  }

  void syncFields(AnimatedContainer original, AnimatedContainer updated) {
    _updateField(original, getter(updated));
  }

  void _updateField(AnimatedContainer original, T newValue) {
    if (field != null) {
      // Animate to newValue (possibly null).
      field.animateTo(newValue);
    } else if (newValue != null) {
      // Set the value and prepare it for future animations.
      field = new ImplicitlyAnimatedValue<T>(initField(newValue), duration);
      field.performance.addListener(() {
        original.setState(() { setter(original, field.value); });
      });
    }
  }
}

class ImplicitlyAnimatedConstraintsBehavior extends ImplicitlyAnimatedFieldBehavior<BoxConstraints> {
  ImplicitlyAnimatedConstraintsBehavior(Duration duration) : super(duration);

  BoxConstraints getter(AnimatedContainer container) => container.constraints;
  void setter(AnimatedContainer container, BoxConstraints val) { container.constraints = val; }
  AnimatedValue initField(BoxConstraints val) => new AnimatedBoxConstraintsValue(val);
}

class ImplicitlyAnimatedDecorationBehavior extends ImplicitlyAnimatedFieldBehavior<BoxDecoration> {
  ImplicitlyAnimatedDecorationBehavior(Duration duration) : super(duration);

  BoxDecoration getter(AnimatedContainer container) => container.decoration;
  void setter(AnimatedContainer container, BoxDecoration val) { container.decoration = val; }
  AnimatedValue initField(BoxDecoration val) => new AnimatedBoxDecorationValue(val);
}

class ImplicitlyAnimatedMarginBehavior extends ImplicitlyAnimatedFieldBehavior<EdgeDims> {
  ImplicitlyAnimatedMarginBehavior(Duration duration) : super(duration);

  EdgeDims getter(AnimatedContainer container) => container.margin;
  void setter(AnimatedContainer container, EdgeDims val) { container.margin = val; }
  AnimatedValue initField(EdgeDims val) => new AnimatedEdgeDimsValue(val);
}

class ImplicitlyAnimatedPaddingBehavior extends ImplicitlyAnimatedFieldBehavior<EdgeDims> {
  ImplicitlyAnimatedPaddingBehavior(Duration duration) : super(duration);

  EdgeDims getter(AnimatedContainer container) => container.padding;
  void setter(AnimatedContainer container, EdgeDims val) { container.padding = val; }
  AnimatedValue initField(EdgeDims val) => new AnimatedEdgeDimsValue(val);
}

class ImplicitlyAnimatedTransformBehavior extends ImplicitlyAnimatedFieldBehavior<Matrix4> {
  ImplicitlyAnimatedTransformBehavior(Duration duration) : super(duration);

  Matrix4 getter(AnimatedContainer container) => container.transform;
  void setter(AnimatedContainer container, Matrix4 val) { container.transform = val; }
  AnimatedValue initField(Matrix4 val) => new AnimatedMatrix4Value(val);
}

class ImplicitlyAnimatedWidthBehavior extends ImplicitlyAnimatedFieldBehavior<double> {
  ImplicitlyAnimatedWidthBehavior(Duration duration) : super(duration);

  double getter(AnimatedContainer container) => container.width;
  void setter(AnimatedContainer container, double val) { container.width = val; }
  AnimatedValue initField(double val) => new AnimatedValue<double>(val);
}

class ImplicitlyAnimatedHeightBehavior extends ImplicitlyAnimatedFieldBehavior<double> {
  ImplicitlyAnimatedHeightBehavior(Duration duration) : super(duration);

  double getter(AnimatedContainer container) => container.height;
  void setter(AnimatedContainer container, double val) { container.height = val; }
  AnimatedValue initField(double val) => new AnimatedValue<double>(val);
}

List<AnimationBehavior> implicitlyAnimate(Duration duration) {
  return [
    new ImplicitlyAnimatedConstraintsBehavior(duration),
    new ImplicitlyAnimatedDecorationBehavior(duration),
    new ImplicitlyAnimatedMarginBehavior(duration),
    new ImplicitlyAnimatedPaddingBehavior(duration),
    new ImplicitlyAnimatedTransformBehavior(duration),
    new ImplicitlyAnimatedWidthBehavior(duration),
    new ImplicitlyAnimatedHeightBehavior(duration)
  ];
}

class AnimatedContainer extends AnimatedComponent {
  AnimatedContainer({
    Key key,
    this.child,
    this.behavior,
    this.constraints,
    this.decoration,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.transform
  }) : super(key: key);

  Widget child;
  BoxConstraints constraints;
  BoxDecoration decoration;
  EdgeDims margin;
  EdgeDims padding;
  Matrix4 transform;
  double width;
  double height;

  List<AnimationBehavior> behavior;

  void initState() {
    for (AnimationBehavior i in behavior)
      i.initFields(this);
  }

  void syncFields(AnimatedContainer updated) {
    child = updated.child;
    for (AnimationBehavior i in behavior)
      i.syncFields(this, updated);
  }

  Widget build() {
    return new Container(
      child: child,
      constraints: constraints,
      decoration: decoration,
      margin: margin,
      padding: padding,
      transform: transform,
      width: width,
      height: height
    );
  }
}
