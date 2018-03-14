// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the ui.Canvas interface to draw various shapes
// with gradients and transforms.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

ui.Picture paint(ui.Rect paintBounds) {
  // First we create a PictureRecorder to record the commands we're going to
  // feed in the canvas. The PictureRecorder will eventually produce a Picture,
  // which is an immutable record of those commands.
  final ui.PictureRecorder recorder = new ui.PictureRecorder();

  // Next, we create a canvas from the recorder. The canvas is an interface
  // which can receive drawing commands. The canvas interface is modeled after
  // the SkCanvas interface from Skia. The paintBounds establishes a "cull rect"
  // for the canvas, which lets the implementation discard any commands that
  // are entirely outside this rectangle.
  final ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  final ui.Paint paint = new ui.Paint();
  canvas.drawPaint(new ui.Paint()..color = const ui.Color(0xFFFFFFFF));

  final ui.Size size = paintBounds.size;
  final ui.Offset mid = size.center(ui.Offset.zero);
  final double radius = size.shortestSide / 2.0;

  final double devicePixelRatio = ui.window.devicePixelRatio;
  final ui.Size logicalSize = ui.window.physicalSize / devicePixelRatio;

  canvas.save();
  canvas.translate(-mid.dx / 2.0, logicalSize.height * 2.0);
  canvas.clipRect(new ui.Rect.fromLTRB(0.0, -logicalSize.height, logicalSize.width, radius));

  canvas.translate(mid.dx, mid.dy);
  paint.color = const ui.Color.fromARGB(128, 255, 0, 255);
  canvas.rotate(math.pi/4.0);

  final ui.Gradient yellowBlue = new ui.Gradient.linear(
    new ui.Offset(-radius, -radius),
    const ui.Offset(0.0, 0.0),
    <ui.Color>[const ui.Color(0xFFFFFF00), const ui.Color(0xFF0000FF)],
  );
  canvas.drawRect(new ui.Rect.fromLTRB(-radius, -radius, radius, radius),
                  new ui.Paint()..shader = yellowBlue);

  // Scale x and y by 0.5.
  final Float64List scaleMatrix = new Float64List.fromList(<double>[
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.5, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
  ]);
  canvas.transform(scaleMatrix);
  paint.color = const ui.Color.fromARGB(128, 0, 255, 0);
  canvas.drawCircle(ui.Offset.zero, radius, paint);
  canvas.restore();

  paint.color = const ui.Color.fromARGB(128, 255, 0, 0);
  canvas.drawCircle(const ui.Offset(150.0, 300.0), radius, paint);

  // When we're done issuing painting commands, we end the recording an receive
  // a Picture, which is an immutable record of the commands we've issued. You
  // can draw a Picture into another canvas or include it as part of a
  // composited scene.
  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  final Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  final ui.SceneBuilder sceneBuilder = new ui.SceneBuilder()
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
  final ui.Picture picture = paint(paintBounds);
  final ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
