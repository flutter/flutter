// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'animated_component.dart';
import 'basic.dart';
import '../framework/animation/animated_value.dart';
import '../framework/animation/curves.dart';

typedef void ValueChanged(value);

const double _kCheckDuration = 200.0;

abstract class Toggleable extends AnimatedComponent {

  Toggleable({
    Object key,
    this.value,
    this.onChanged
  }) : super(key: key) {
    toggleAnimation = new AnimatedValue(value ? 1.0 : 0.0);
  }

  bool value;
  AnimatedValue toggleAnimation;
  ValueChanged onChanged;

  void syncFields(Toggleable source) {
    onChanged = source.onChanged;
    if (value != source.value) {
      value = source.value;
      double targetValue = value ? 1.0 : 0.0;
      double difference = (toggleAnimation.value - targetValue).abs();
      if (difference > 0) {
        toggleAnimation.stop();
        double t = difference * duration;
        Curve curve = targetValue > toggleAnimation.value ? curveUp : curveDown;
        toggleAnimation.animateTo(targetValue, t, curve: curve);
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
  Size get size => const Size.zero;
  EdgeDims get margin => const EdgeDims.symmetric(horizontal: 5.0);
  double get duration => 200.0;
  Curve get curveUp => easeIn;
  Curve get curveDown => easeOut;

  UINode build() {
    return new EventListenerNode(
      new Container(
        margin: margin,
        width: size.width,
        height: size.height,
        child: new CustomPaint(
          token: toggleAnimation.value,
          callback: customPaintCallback
        )
      ),
      onGestureTap: _handleClick
    );
  }
}
