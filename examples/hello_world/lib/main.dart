// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

void main() =>
  runApp(
    Center(
      child:
        CustomPaint(
          painter: Foo(),
          size: Size(100, 100),
        )
      ),
    );


class Foo extends CustomPainter {
  static final ui.FragmentProgram program = ui.FragmentProgram.fromAsset('shaders/example.frag');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = program.shader());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
