// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:typed_data';

ui.Picture paint(ui.Rect paintBounds) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  double size = 100.0;
  canvas.translate(size + 10.0, size + 10.0);

  ui.Paint paint = new ui.Paint();
  paint.color = const ui.Color.fromARGB(255, 0, 255, 0);
  var builder = new ui.LayerDrawLooperBuilder()
    // Shadow layer.
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()
          ..setPaintBits(ui.PaintBits.all)
          ..setOffset(const ui.Offset(5.0, 5.0))
          ..setColorMode(ui.TransferMode.src),
        new ui.Paint()
          ..color = const ui.Color.fromARGB(128, 55, 55, 55)
          ..maskFilter = new ui.MaskFilter.blur(ui.BlurStyle.normal, 5.0)
    )
    // Main layer.
    ..addLayerOnTop(new ui.DrawLooperLayerInfo(), new ui.Paint());
  paint.drawLooper = builder.build();

  canvas.drawPaint(
      new ui.Paint()..color = const ui.Color.fromARGB(255, 255, 255, 255));
  canvas.drawRect(new ui.Rect.fromLTRB(-size, -size, size, size), paint);

  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  ui.Rect sceneBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.window.size.width * devicePixelRatio, ui.window.size.height * devicePixelRatio);
  Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  ui.SceneBuilder sceneBuilder = new ui.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture, paintBounds)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  ui.Rect paintBounds = ui.Point.origin & ui.window.size;
  ui.Picture picture = paint(paintBounds);
  ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
