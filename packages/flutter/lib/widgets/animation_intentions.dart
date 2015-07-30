// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains a set of common intentions to use with AnimationContainer
// for describing how to animate certain properties.

import 'dart:sky';

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/widgets/animated_container.dart';
import 'package:sky/widgets/basic.dart';
import 'package:vector_math/vector_math.dart';

// Slides a container in from |start| to |end| when the container's |tag| is
// true (reverses if false).
class SlideInIntention extends AnimationIntention {
  SlideInIntention({Duration duration, this.performance, Point start, Point end}) {
    if (performance == null) {
      assert(duration != null);
      performance = new AnimationPerformance(duration: duration);
    }
    _position = new AnimatedValue<Point>(start, end: end);
    performance.addVariable(_position);
  }

  AnimatedValue<Point> _position;
  AnimationPerformance performance;

  void initFields(AnimatedContainer container) {
    performance.addListener(() { _updateProgress(container); });
    performance.progress = 0.0;
    if (container.tag)
      performance.play();
  }

  void syncFields(AnimatedContainer original, AnimatedContainer updated) {
    if (original.tag != updated.tag) {
      original.tag = updated.tag;
      performance.play(original.tag ? Direction.forward : Direction.reverse);
    }
  }

  void _updateProgress(AnimatedContainer container) {
    container.setState(() {
      container.transform = new Matrix4.identity()
        ..translate(_position.value.x, _position.value.y);
    });
  }
}

// Changes color from |start| to |end| when the container's |tag| is true
// (reverses if false).
class ColorTransitionIntention extends AnimationIntention {
  ColorTransitionIntention({Duration duration, this.performance, Color start, Color end}) {
    if (performance == null) {
      assert(duration != null);
      performance = new AnimationPerformance(duration: duration);
    }
    _color = new AnimatedColorValue(start, end: end);
    performance.addVariable(_color);
  }

  AnimatedColorValue _color;
  AnimationPerformance performance;

  void initFields(AnimatedContainer container) {
    performance.addListener(() { _updateProgress(container); });
    performance.progress = 0.0;
    if (container.tag)
      performance.play();
  }

  void syncFields(AnimatedContainer original, AnimatedContainer updated) {
    if (original.tag != updated.tag) {
      original.tag = updated.tag;
      performance.play(original.tag ? Direction.forward : Direction.reverse);
    }
  }

  void _updateProgress(AnimatedContainer container) {
    container.setState(() {
      container.decoration = new BoxDecoration(backgroundColor: _color.value);
    });
  }
}
