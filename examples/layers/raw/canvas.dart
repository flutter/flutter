// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the ui.Canvas interface to draw various shapes
// with gradients and transforms.

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';

ui.Picture paint(ui.Rect paintBounds) {
  // First we create a PictureRecorder to record the commands we're going to
  // feed in the canvas. The PictureRecorder will eventually produce a Picture,
  // which is an immutable record of those commands.
  ui.PictureRecorder recorder = new ui.PictureRecorder();

  // Next, we create a canvas from the recorder. The canvas is an interface
  // which can receive drawing commands. The canvas interface is modeled after
  // the SkCanvas interface from Skia. The paintBounds establishes a "cull rect"
  // for the canvas, which lets the implementation discard any commands that
  // are entirely outside this rectangle.
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  ui.Paint paint = new ui.Paint();
  canvas.drawPaint(new ui.Paint()..color = const ui.Color(0xFFFFFFFF));

  ui.Size size = paintBounds.size;
  ui.Point mid = size.center(ui.Point.origin);
  double radius = size.shortestSide / 2.0;

  final double devicePixelRatio = ui.window.devicePixelRatio;
  final ui.Size logicalSize = ui.window.physicalSize / devicePixelRatio;

  canvas.save();
  canvas.translate(-mid.x/2.0, logicalSize.height*2.0);
  canvas.clipRect(
      new ui.Rect.fromLTRB(0.0, -logicalSize.height, logicalSize.width, radius));

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
  canvas.transform(scaleMatrix);
  paint.color = const ui.Color.fromARGB(128, 0, 255, 0);
  canvas.drawCircle(ui.Point.origin, radius, paint);
  canvas.restore();

  paint.color = const ui.Color.fromARGB(128, 255, 0, 0);
  canvas.drawCircle(new ui.Point(150.0, 300.0), radius, paint);

  // When we're done issuing painting commands, we end the recording an receive
  // a Picture, which is an immutable record of the commands we've issued. You
  // can draw a Picture into another canvas or include it as part of a
  // composited scene.
  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  ui.SceneBuilder sceneBuilder = new ui.SceneBuilder()
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  ui.Rect paintBounds = ui.Point.origin & (ui.window.physicalSize / ui.window.devicePixelRatio);
  ui.Picture picture = paint(paintBounds);
  ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
