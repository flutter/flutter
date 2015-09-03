// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:typed_data';

sky.Picture paint(sky.Rect paintBounds) {
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, paintBounds);

  double size = 100.0;
  canvas.translate(size + 10.0, size + 10.0);

  sky.Paint paint = new sky.Paint();
  paint.color = const sky.Color.fromARGB(255, 0, 255, 0);
  var builder = new sky.LayerDrawLooperBuilder()
    // Shadow layer.
    ..addLayerOnTop(
        new sky.DrawLooperLayerInfo()
          ..setPaintBits(sky.PaintBits.all)
          ..setOffset(const sky.Offset(5.0, 5.0))
          ..setColorMode(sky.TransferMode.src),
        new sky.Paint()
          ..color = const sky.Color.fromARGB(128, 55, 55, 55)
          ..setMaskFilter(
            new sky.MaskFilter.blur(sky.BlurStyle.normal, 5.0))
    )
    // Main layer.
    ..addLayerOnTop(new sky.DrawLooperLayerInfo(), new sky.Paint());
  paint.setDrawLooper(builder.build());

  canvas.drawPaint(
      new sky.Paint()..color = const sky.Color.fromARGB(255, 255, 255, 255));
  canvas.drawRect(new sky.Rect.fromLTRB(-size, -size, size, size), paint);

  return recorder.endRecording();
}

sky.Scene composite(sky.Picture picture, sky.Rect paintBounds) {
  final double devicePixelRatio = sky.view.devicePixelRatio;
  sky.Rect sceneBounds = new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width * devicePixelRatio, sky.view.height * devicePixelRatio);
  Float32List deviceTransform = new Float32List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  sky.SceneBuilder sceneBuilder = new sky.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(sky.Offset.zero, picture, paintBounds)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(double timeStamp) {
  sky.Rect paintBounds = new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width, sky.view.height);
  sky.Picture picture = paint(paintBounds);
  sky.Scene scene = composite(picture, paintBounds);
  sky.view.scene = scene;
}

void main() {
  sky.view.setFrameCallback(beginFrame);
  sky.view.scheduleFrame();
}
