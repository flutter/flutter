// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:sky";

import 'package:sky/animation/curves.dart';
import 'package:sky/animation/direction.dart';
import 'package:sky/base/lerp.dart';

export 'package:sky/animation/curves.dart' show Interval;

abstract class AnimatedVariable {
  void setProgress(double t, Direction direction);
  String toString();
}

abstract class CurvedVariable implements AnimatedVariable {
  CurvedVariable({this.interval, this.reverseInterval, this.curve, this.reverseCurve});

  Interval interval;
  Interval reverseInterval;
  Curve curve;
  Curve reverseCurve;

  double _transform(double t, Direction direction) {
    Interval interval = _getInterval(direction);
    if (interval != null)
      t = interval.transform(t);
    if (t == 1.0) // Or should we support inverse curves?
      return t;
    Curve curve = _getCurve(direction);
    if (curve != null)
      t = curve.transform(t);
    return t;
  }

  Interval _getInterval(Direction direction) {
    if (direction == Direction.forward || reverseInterval == null)
      return interval;
    return reverseInterval;
  }

  Curve _getCurve(Direction direction) {
    if (direction == Direction.forward || reverseCurve == null)
      return curve;
    return reverseCurve;
  }
}

class AnimatedValue<T extends dynamic> extends CurvedVariable {
  AnimatedValue(this.begin, { this.end, Interval interval, Curve curve, Curve reverseCurve })
    : super(interval: interval, curve: curve, reverseCurve: reverseCurve) {
    value = begin;
  }

  T value;
  T begin;
  T end;

  T lerp(double t) => begin + (end - begin) * t;

  void setProgress(double t, Direction direction) {
    if (end != null) {
      t = _transform(t, direction);
      value = (t == 1.0) ? end : lerp(t);
    }
  }

  String toString() => 'AnimatedValue(begin=$begin, end=$end, value=$value)';
}

class AnimatedList extends CurvedVariable {
  List<AnimatedVariable> variables;

  AnimatedList(this.variables, { Interval interval, Curve curve, Curve reverseCurve })
    : super(interval: interval, curve: curve, reverseCurve: reverseCurve);

  void setProgress(double t, Direction direction) {
    double adjustedTime = _transform(t, direction);
    for (AnimatedVariable variable in variables)
      variable.setProgress(adjustedTime, direction);
  }

  String toString() => 'AnimatedList([$variables])';
}

class AnimatedColorValue extends AnimatedValue<Color> {
  AnimatedColorValue(Color begin, { Color end, Curve curve })
    : super(begin, end: end, curve: curve);

  Color lerp(double t) => lerpColor(begin, end, t);
}

class AnimatedRect extends AnimatedValue<Rect> {
  AnimatedRect(Rect begin, { Rect end, Curve curve })
    : super(begin, end: end, curve: curve);

  Rect lerp(double t) => lerpRect(begin, end, t);
}
