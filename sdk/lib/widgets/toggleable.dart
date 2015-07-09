// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../animation/animation_performance.dart';
import '../animation/curves.dart';
import 'animated_component.dart';
import 'basic.dart';

typedef void ValueChanged(value);

const Duration _kCheckDuration = const Duration(milliseconds: 200);

abstract class Toggleable extends AnimatedComponent {

  Toggleable({
    String key,
    this.value,
    this.onChanged
  }) : super(key: key) {
    position = new AnimatedType<double>(0.0, end: 1.0);
    performance = new AnimationPerformance()
      ..variable = position
      ..duration = _kCheckDuration
      ..progress = value ? 1.0 : 0.0;
    watchPerformance(performance);
  }

  bool value;
  ValueChanged onChanged;

  AnimatedType<double> position;
  AnimationPerformance performance;

  void syncFields(Toggleable source) {
    onChanged = source.onChanged;
    if (value != source.value) {
      value = source.value;
      // TODO(abarth): Setting the curve on the position means there's a
      // discontinuity when we reverse the timeline.
      if (value) {
        position.curve = curveUp;
        performance.play();
      } else {
        position.curve = curveDown;
        performance.reverse();
      }
    }
    super.syncFields(source);
  }

  void _handleClick(sky.Event e) {
    onChanged(!value);
  }

  // Override these methods to draw yourself
  void customPaintCallback(sky.Canvas canvas, Size size) {
    assert(false);
  }
  Size get size => Size.zero;
  EdgeDims get margin => const EdgeDims.symmetric(horizontal: 5.0);
  double get duration => 200.0;
  Curve get curveUp => easeIn;
  Curve get curveDown => easeOut;

  Widget build() {
    return new Listener(
      child: new Container(
        margin: margin,
        width: size.width,
        height: size.height,
        child: new CustomPaint(
          token: position.value,
          callback: customPaintCallback
        )
      ),
      onGestureTap: _handleClick
    );
  }
}
