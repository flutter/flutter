// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/animation.dart';

// The easing curves of the Material Library

/// The standard easing curve in the Material specification.
///
/// Elements that begin and end at rest use standard easing.
/// They speed up quickly and slow down gradually, in order
/// to emphasize the end of the transition.
///
/// See also:
/// * <https://material.io/design/motion/speed.html#easing>
const Curve standardEasing = Curves.fastOutSlowIn;

/// The accelerate easing curve in the Material specification.
///
/// Elements exiting a screen use acceleration easing,
/// where they start at rest and end at peak velocity.
///
/// See also:
/// * <https://material.io/design/motion/speed.html#easing>
const Curve accelerateEasing = Cubic(0.4, 0.0, 1.0, 1.0);

/// The decelerate easing curve in the Material specification.
///
/// Incoming elements are animated using deceleration easing,
/// which starts a transition at peak velocity (the fastest
/// point of an element’s movement) and ends at rest.
///
/// See also:
/// * <https://material.io/design/motion/speed.html#easing>
const Curve decelerateEasing = Cubic(0.0, 0.0, 0.2, 1.0);
