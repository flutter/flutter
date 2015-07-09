// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vector_math/vector_math.dart';

import '../animation/animation_performance.dart';
import '../animation/curves.dart';
import '../base/lerp.dart';
import '../painting/box_painter.dart';
import '../theme/shadows.dart';
import 'basic.dart';

// This class builds a Container object from a collection of optionally-
// animated properties. Use syncFields to update the Container's properties,
// which will optionally animate them using an AnimationPerformance.
class AnimatedContainer {
  AnimatedType<Point> position;
  AnimatedType<double> shadow;
  AnimatedColor backgroundColor;

  Map<AnimatedVariable, AnimationPerformance> _variableToPerformance =
      new Map<AnimatedVariable, AnimationPerformance>();

  AnimatedContainer();

  AnimationPerformance createPerformance(AnimatedType variable,
                                         {Duration duration}) {
    AnimationPerformance performance = new AnimationPerformance()
      ..duration = duration
      ..variable = variable;
    _variableToPerformance[variable] = performance;
    return performance;
  }

  Widget build(Widget child) {
    Widget current = child;
    if (shadow != null || backgroundColor != null) {
      current = new DecoratedBox(
        decoration: new BoxDecoration(
          boxShadow: shadow != null ? _computeShadow(shadow.value) : null,
          backgroundColor: backgroundColor != null ? backgroundColor.value : null),
        child: current);
    }

    if (position != null) {
      Matrix4 transform = new Matrix4.identity();
      transform.translate(position.value.x, position.value.y);
      current = new Transform(transform: transform, child: child);
    }

    return current;
  }

  void syncFields(AnimatedContainer source) {
    _syncField(position, source.position);
    _syncField(shadow, source.shadow);
    _syncField(backgroundColor, source.backgroundColor);
  }

  void _syncField(AnimatedType variable, AnimatedType sourceVariable) {
    if (variable == null)
      return;  // TODO(mpcomplete): Should we handle transition from null?

    AnimationPerformance performance = _variableToPerformance[variable];
    if (performance == null) {
      // If there's no performance, no need to animate.
      if (sourceVariable != null)
        variable.value = sourceVariable.value;
      return;
    }

    if (variable.value != sourceVariable.value) {
      variable
        ..begin = variable.value
        ..end = sourceVariable.value;
      performance
        ..progress = 0.0
        ..play();
    }
  }
}

class AnimatedColor extends AnimatedType<Color> {
  AnimatedColor(Color begin, {Color end, Curve curve: linear})
      : super(begin, end: end, curve: curve);

  void setFraction(double t) {
    value = lerpColor(begin, end, t);
  }
}

List<BoxShadow> _computeShadow(double level) {
  if (level < 1.0)  // shadows[1] is the first shadow
    return null;

  int level1 = level.floor();
  int level2 = level.ceil();
  double t = level - level1.toDouble();

  List<BoxShadow> shadow = new List<BoxShadow>();
  for (int i = 0; i < shadows[level1].length; ++i)
    shadow.add(lerpBoxShadow(shadows[level1][i], shadows[level2][i], t));
  return shadow;
}
