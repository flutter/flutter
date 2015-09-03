// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:math' as math;
import 'dart:typed_data';

sky.Picture paint(sky.Rect paintBounds) {
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, paintBounds);
  sky.Size size = paintBounds.size;

  sky.Paint paint = new sky.Paint();
  sky.Point mid = size.center(sky.Point.origin);
  double radius = size.shortestSide / 2.0;
  canvas.drawPaint(new sky.Paint()..color = const sky.Color(0xFFFFFFFF));

  canvas.save();
  canvas.translate(-mid.x/2.0, sky.view.height*2.0);
  canvas.clipRect(
      new sky.Rect.fromLTRB(0.0, -sky.view.height, sky.view.width, radius));

  canvas.translate(mid.x, mid.y);
  paint.color = const sky.Color.fromARGB(128, 255, 0, 255);
  canvas.rotate(math.PI/4.0);

  sky.Gradient yellowBlue = new sky.Gradient.linear(
      [new sky.Point(-radius, -radius), new sky.Point(0.0, 0.0)],
      [const sky.Color(0xFFFFFF00), const sky.Color(0xFF0000FF)]);
  canvas.drawRect(new sky.Rect.fromLTRB(-radius, -radius, radius, radius),
                   new sky.Paint()..setShader(yellowBlue));

  // Scale x and y by 0.5.
  var scaleMatrix = new Float32List.fromList([
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.5, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
  ]);
  canvas.concat(scaleMatrix);
  paint.color = const sky.Color.fromARGB(128, 0, 255, 0);
  canvas.drawCircle(sky.Point.origin, radius, paint);

  canvas.restore();

  canvas.translate(0.0, 50.0);
  var builder = new sky.LayerDrawLooperBuilder()
      ..addLayerOnTop(
          new sky.DrawLooperLayerInfo()
            ..setOffset(const sky.Offset(150.0, 0.0))
            ..setColorMode(sky.TransferMode.src)
            ..setPaintBits(sky.PaintBits.all),
          new sky.Paint()
            ..color = const sky.Color.fromARGB(128, 255, 255, 0)
            ..setColorFilter(new sky.ColorFilter.mode(
              const sky.Color.fromARGB(128, 0, 0, 255), sky.TransferMode.srcIn))
            ..setMaskFilter(new sky.MaskFilter.blur(
              sky.BlurStyle.normal, 3.0, highQuality: true)))
      ..addLayerOnTop(
          new sky.DrawLooperLayerInfo()
            ..setOffset(const sky.Offset(75.0, 75.0))
            ..setColorMode(sky.TransferMode.src)
            ..setPaintBits(sky.PaintBits.shader),
          new sky.Paint()
            ..setShader(new sky.Gradient.radial(
                new sky.Point(0.0, 0.0), radius/3.0,
                [const sky.Color(0xFFFFFF00), const sky.Color(0xFFFF0000)],
                null, sky.TileMode.mirror))
            // Since we're don't set sky.PaintBits.maskFilter, this has no effect.
            ..setMaskFilter(new sky.MaskFilter.blur(
              sky.BlurStyle.normal, 50.0, highQuality: true)))
      ..addLayerOnTop(
          new sky.DrawLooperLayerInfo()..setOffset(const sky.Offset(225.0, 75.0)),
          // Since this layer uses a DST color mode, this has no effect.
          new sky.Paint()..color = const sky.Color.fromARGB(128, 255, 0, 0));
  paint.setDrawLooper(builder.build());
  canvas.drawCircle(sky.Point.origin, radius, paint);

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
