// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class SpinningSquare extends StatelessWidget {
  const SpinningSquare({super.key});

  @override
  Widget build(BuildContext context) {
    return RepeatingTweenAnimationBuilder<double>(
      // We use 3600 milliseconds instead of 1800 milliseconds because 0.0 -> 1.0
      // represents an entire turn of the square whereas in the other examples
      // we used 0.0 -> math.pi, which is only half a turn.
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 3600),
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.rotate(angle: value * 2 * math.pi, child: child);
      },
      child: Container(width: 200.0, height: 200.0, color: const Color(0xFF00FF00)),
    );
  }
}

void main() {
  runApp(const Center(child: SpinningSquare()));
}
