// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter/painting.dart' show DefaultShaderWarmUp, PaintingBinding;
import 'package:macrobenchmarks/main.dart' as app;

class CubicBezierShaderWarmUp extends DefaultShaderWarmUp {
  @override
  Future<void> warmUpOnCanvas(Canvas canvas) async {
    await super.warmUpOnCanvas(canvas);

    // Warm up the cubic shaders used by CubicBezierPage.
    //
    // This tests that our custom shader warm up is working properly.
    // Without this custom shader warm up, the worst frame time is about 115ms.
    // With this, the worst frame time is about 70ms. (Data collected on a Moto
    // G4 based on Flutter version 704814c67a874077710524d30412337884bf0254.
    final Path path = Path();
    path.moveTo(20.0, 20.0);
    // This cubic path is based on
    // https://skia.org/user/api/SkPath_Reference#SkPath_cubicTo
    path.cubicTo(300.0, 80.0, -140.0, 90.0, 220.0, 10.0);
    final Paint paint = Paint();
    paint.isAntiAlias = true;
    paint.strokeWidth = 18.0;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }
}

void main() {
  PaintingBinding.shaderWarmUp = CubicBezierShaderWarmUp();
  enableFlutterDriverExtension();
  app.main();
}
