// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows the draw operations to warm up the GPU shaders by default.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<void> beginFrame(Duration timeStamp) async {
  // PAINT
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  const ui.Rect paintBounds = ui.Rect.fromLTRB(0, 0, 1000, 1000);
  final ui.Canvas canvas = ui.Canvas(recorder, paintBounds);
  final ui.Paint backgroundPaint = ui.Paint()..color = Colors.white;
  canvas.drawRect(paintBounds, backgroundPaint);
  await const DefaultShaderWarmUp(
          drawCallSpacing: 80.0, canvasSize: ui.Size(1024, 1024))
      .warmUpOnCanvas(canvas);
  final ui.Picture picture = recorder.endRecording();

  // COMPOSITE
  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
    ..pushClipRect(paintBounds)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  ui.window.render(sceneBuilder.build());
}

Future<void> main() async {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
