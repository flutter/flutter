// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:sky";

import 'package:sky/animation/curves.dart';
import 'package:sky/base/lerp.dart';

abstract class AnimatedVariable {
  void setProgress(double t);
  String toString();
}

class Interval {
  final double start;
  final double end;

  double adjustTime(double t) {
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  Interval(this.start, this.end) {
    assert(start >= 0.0);
    assert(start <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
  }
}

class AnimatedValue<T extends dynamic> extends AnimatedVariable {
  AnimatedValue(this.begin, { this.end, this.interval, this.curve: linear }) {
    value = begin;
  }

  T value;
  T begin;
  T end;
  Interval interval;
  Curve curve;

  void setProgress(double t) {
    if (end != null) {
      double adjustedTime = interval == null ? t : interval.adjustTime(t);
      if (adjustedTime == 1.0) {
        value = end;
      } else {
        // TODO(mpcomplete): Reverse the timeline and curve.
        value = begin + (end - begin) * curve.transform(adjustedTime);
      }
    }
  }

  String toString() => 'AnimatedValue(begin=$begin, end=$end, value=$value)';
}

class AnimatedList extends AnimatedVariable {
  List<AnimatedVariable> variables;
  Interval interval;

  AnimatedList(this.variables, { this.interval });

  void setProgress(double t) {
    double adjustedTime = interval == null ? t : interval.adjustTime(t);
    for (AnimatedVariable variable in variables)
      variable.setProgress(adjustedTime);
  }

  String toString() => 'AnimatedList([$variables])';
}

class AnimatedColorValue extends AnimatedValue<Color> {
  AnimatedColorValue(Color begin, { Color end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setProgress(double t) {
    value = lerpColor(begin, end, t);
  }
}

class AnimatedRect extends AnimatedValue<Rect> {
  AnimatedRect(Rect begin, { Rect end, Curve curve: linear })
    : super(begin, end: end, curve: curve);

  void setProgress(double t) {
    value = lerpRect(begin, end, t);
  }
}
