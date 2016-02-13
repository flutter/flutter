// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

void main() {
  // A green box...
  RenderBox green = new RenderDecoratedBox(
    decoration: const BoxDecoration(backgroundColor: const Color(0xFF00FF00))
  );
  // of a certain size...
  RenderBox square = new RenderConstrainedBox(
    additionalConstraints: const BoxConstraints.tightFor(width: 200.0, height: 200.0),
    child: green
  );
  // With a given rotation (starts off as the identity transform)...
  RenderTransform spin = new RenderTransform(
    transform: new Matrix4.identity(),
    alignment: const FractionalOffset(0.5, 0.5),
    child: square
  );
  // centered...
  RenderBox root = new RenderPositionedBox(
    alignment: const FractionalOffset(0.5, 0.5),
    child: spin
  );
  // on the screen.
  new RenderingFlutterBinding(root: root);

  // A repeating animation every 1800 milliseconds...
  AnimationController animation = new AnimationController(
    duration: const Duration(milliseconds: 1800)
  )..repeat();
  // From 0.0 to math.PI.
  Tween<double> tween = new Tween<double>(begin: 0.0, end: math.PI);
  animation.addListener(() {
    // Each frame of the animation, set the rotation of the square.
    spin.transform = new Matrix4.rotationZ(tween.evaluate(animation));
  });
}
