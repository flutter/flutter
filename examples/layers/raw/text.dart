// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:typed_data';

ui.Paragraph paragraph;

ui.Picture paint(ui.Rect paintBounds) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  canvas.translate(ui.window.size.width / 2.0, ui.window.size.height / 2.0);
  canvas.drawRect(new ui.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0));

  canvas.translate(paragraph.maxWidth / -2.0, (paragraph.maxWidth / 2.0) - 125);
  paragraph.paint(canvas, ui.Offset.zero);

  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  ui.Rect sceneBounds = new ui.Rect.fromLTWH(
    0.0,
    0.0,
    ui.window.size.width * devicePixelRatio,
    ui.window.size.height * devicePixelRatio
  );
  Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  ui.SceneBuilder sceneBuilder = new ui.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
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
  ui.ParagraphBuilder builder = new ui.ParagraphBuilder()
    ..pushStyle(new ui.TextStyle(color: const ui.Color(0xFF0000FF)))
    ..addText("Hello, ")
    ..pushStyle(new ui.TextStyle(fontWeight: ui.FontWeight.bold))
    ..addText("world. ")
    ..pop()
    ..addText("هذا هو قليلا طويلة من النص الذي يجب التفاف .")
    ..pop()
    ..addText(" و أكثر قليلا لجعله أطول. ");
  paragraph = builder.build(new ui.ParagraphStyle())
    ..maxWidth = 180.0
    ..layout();

  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
