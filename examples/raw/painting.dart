// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';

ui.Picture paint(ui.Rect paintBounds) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
  ui.Size size = paintBounds.size;

  ui.Paint paint = new ui.Paint();
  ui.Point mid = size.center(ui.Point.origin);
  double radius = size.shortestSide / 2.0;
  canvas.drawPaint(new ui.Paint()..color = const ui.Color(0xFFFFFFFF));

  canvas.save();
  canvas.translate(-mid.x/2.0, ui.window.size.height*2.0);
  canvas.clipRect(
      new ui.Rect.fromLTRB(0.0, -ui.window.size.height, ui.window.size.width, radius));

  canvas.translate(mid.x, mid.y);
  paint.color = const ui.Color.fromARGB(128, 255, 0, 255);
  canvas.rotate(math.PI/4.0);

  ui.Gradient yellowBlue = new ui.Gradient.linear(
    <ui.Point>[new ui.Point(-radius, -radius), new ui.Point(0.0, 0.0)],
    <ui.Color>[const ui.Color(0xFFFFFF00), const ui.Color(0xFF0000FF)]
  );
  canvas.drawRect(new ui.Rect.fromLTRB(-radius, -radius, radius, radius),
                  new ui.Paint()..shader = yellowBlue);

  // Scale x and y by 0.5.
  Float64List scaleMatrix = new Float64List.fromList(<double>[
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.5, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
  ]);
  canvas.concat(scaleMatrix);
  paint.color = const ui.Color.fromARGB(128, 0, 255, 0);
  canvas.drawCircle(ui.Point.origin, radius, paint);

  canvas.restore();

  canvas.translate(0.0, 50.0);
  ui.LayerDrawLooperBuilder builder = new ui.LayerDrawLooperBuilder()
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()
          ..setOffset(const ui.Offset(150.0, 0.0))
          ..setColorMode(ui.TransferMode.src)
          ..setPaintBits(ui.PaintBits.all),
        new ui.Paint()
          ..color = const ui.Color.fromARGB(128, 255, 255, 0)
          ..colorFilter = new ui.ColorFilter.mode(
              const ui.Color.fromARGB(128, 0, 0, 255),
              ui.TransferMode.srcIn
            )
          ..maskFilter = new ui.MaskFilter.blur(
              ui.BlurStyle.normal, 3.0, highQuality: true
            )
      )
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()
          ..setOffset(const ui.Offset(75.0, 75.0))
          ..setColorMode(ui.TransferMode.src)
          ..setPaintBits(ui.PaintBits.shader),
        new ui.Paint()
          ..shader = new ui.Gradient.radial(
              new ui.Point(0.0, 0.0), radius/3.0,
              <ui.Color>[
                const ui.Color(0xFFFFFF00),
                const ui.Color(0xFFFF0000)
              ],
              null,
              ui.TileMode.mirror
            )
          // Since we're don't set ui.PaintBits.maskFilter, this has no effect.
          ..maskFilter = new ui.MaskFilter.blur(
              ui.BlurStyle.normal, 50.0, highQuality: true
            )
      )
    ..addLayerOnTop(
        new ui.DrawLooperLayerInfo()..setOffset(const ui.Offset(225.0, 75.0)),
        // Since this layer uses a DST color mode, this has no effect.
        new ui.Paint()..color = const ui.Color.fromARGB(128, 255, 0, 0)
      );
  paint.drawLooper = builder.build();
  canvas.drawCircle(ui.Point.origin, radius, paint);

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
