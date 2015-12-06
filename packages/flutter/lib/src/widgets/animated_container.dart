// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'framework.dart';

import 'package:vector_math/vector_math_64.dart';

class AnimatedBoxConstraintsValue extends AnimatedValue<BoxConstraints> {
  AnimatedBoxConstraintsValue(BoxConstraints begin, { BoxConstraints end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  BoxConstraints lerp(double t) => BoxConstraints.lerp(begin, end, t);
}

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

class AnimatedEdgeDimsValue extends AnimatedValue<EdgeDims> {
  AnimatedEdgeDimsValue(EdgeDims begin, { EdgeDims end, Curve curve, Curve reverseCurve })
    : super(begin, end: end, curve: curve, reverseCurve: reverseCurve);

  EdgeDims lerp(double t) => EdgeDims.lerp(begin, end, t);
}

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

class AnimatedContainer extends StatefulComponent {
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
    this.curve: Curves.linear,
    this.duration
  }) : super(key: key) {
    assert(margin == null || margin.isNonNegative);
    assert(padding == null || padding.isNonNegative);
    assert(curve != null);
    assert(duration != null || decoration.debugAssertValid());
  }

  final Widget child;

  final BoxConstraints constraints;
  final Decoration decoration;
  final Decoration foregroundDecoration;
  final EdgeDims margin;
  final EdgeDims padding;
  final Matrix4 transform;
  final double width;
  final double height;

  final Curve curve;
  final Duration duration;

  _AnimatedContainerState createState() => new _AnimatedContainerState();
}

class _AnimatedContainerState extends State<AnimatedContainer> {
  AnimatedBoxConstraintsValue _constraints;
  AnimatedDecorationValue _decoration;
  AnimatedDecorationValue _foregroundDecoration;
  AnimatedEdgeDimsValue _margin;
  AnimatedEdgeDimsValue _padding;
  AnimatedMatrix4Value _transform;
  AnimatedValue<double> _width;
  AnimatedValue<double> _height;

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

  void didUpdateConfig(AnimatedContainer oldConfig) {
    if (config.curve != oldConfig.curve)
      _updateCurve();
    _performanceController.duration = config.duration;
    if (_configAllVariables()) {
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
      _updateVariable(_constraints);
      _updateVariable(_decoration);
      _updateVariable(_foregroundDecoration);
      _updateVariable(_margin);
      _updateVariable(_padding);
      _updateVariable(_transform);
      _updateVariable(_width);
      _updateVariable(_height);
    });
  }

  bool _configVariable(AnimatedValue variable, dynamic targetValue) {
    if (targetValue == variable.end)
      return false;
    dynamic currentValue = variable.value;
    variable.end = targetValue;
    variable.begin = currentValue;
    return currentValue != targetValue;
  }

  bool _configAllVariables() {
    bool needsAnimation = false;
    if (config.constraints != null) {
      _constraints ??= new AnimatedBoxConstraintsValue(config.constraints);
      if (_configVariable(_constraints, config.constraints))
        needsAnimation = true;
    } else {
      _constraints = null;
    }

    if (config.decoration != null) {
      _decoration ??= new AnimatedDecorationValue(config.decoration);
      if (_configVariable(_decoration, config.decoration))
        needsAnimation = true;
    } else {
      _decoration = null;
    }

    if (config.foregroundDecoration != null) {
      _foregroundDecoration ??= new AnimatedDecorationValue(config.foregroundDecoration);
      if (_configVariable(_foregroundDecoration, config.foregroundDecoration))
        needsAnimation = true;
    } else {
      _foregroundDecoration = null;
    }

    if (config.margin != null) {
      _margin ??= new AnimatedEdgeDimsValue(config.margin);
      if (_configVariable(_margin, config.margin))
        needsAnimation = true;
    } else {
      _margin = null;
    }

    if (config.padding != null) {
      _padding ??= new AnimatedEdgeDimsValue(config.padding);
      if (_configVariable(_padding, config.padding))
        needsAnimation = true;
    } else {
      _padding = null;
    }

    if (config.transform != null) {
      _transform ??= new AnimatedMatrix4Value(config.transform);
      if (_configVariable(_transform, config.transform))
        needsAnimation = true;
    } else {
      _transform = null;
    }

    if (config.width != null) {
      _width ??= new AnimatedValue<double>(config.width);
      if (_configVariable(_width, config.width))
        needsAnimation = true;
    } else {
      _width = null;
    }

    if (config.height != null) {
      _height ??= new AnimatedValue<double>(config.height);
      if (_configVariable(_height, config.height))
        needsAnimation = true;
    } else {
      _height = null;
    }

    return needsAnimation;
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
