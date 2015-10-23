// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

double timeBase = null;
ui.Paragraph paragraph;

ui.Picture paint(ui.Rect paintBounds, double delta) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  canvas.translate(ui.view.width / 2.0, ui.view.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.drawRect(new ui.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0));

  double sin = math.sin(delta / 200);
  paragraph.maxWidth = 150.0 + (50 * sin);
  paragraph.layout();

  canvas.translate(paragraph.maxWidth / -2.0, (paragraph.maxWidth / 2.0) - 125);
  paragraph.paint(canvas, ui.Offset.zero);

  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.view.devicePixelRatio;
  ui.Rect sceneBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width * devicePixelRatio, ui.view.height * devicePixelRatio);
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

void beginFrame(double timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  ui.Rect paintBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width, ui.view.height);
  ui.Picture picture = paint(paintBounds, delta);
  ui.Scene scene = composite(picture, paintBounds);
  ui.view.scene = scene;
  ui.view.scheduleFrame();
}

void main() {
  // TODO(abarth): We're missing some bidi style information:
  //   block.style['direction'] = 'rtl';
  //   block.style['unicode-bidi'] = 'plaintext';
  ui.ParagraphBuilder builder = new ui.ParagraphBuilder();
  builder.addText("هذا هو قليلا طويلة من النص الذي يجب التفاف .");
  builder.addText(" و أكثر قليلا لجعله أطول. ");
  paragraph = builder.build(new ui.ParagraphStyle());

  ui.view.setFrameCallback(beginFrame);
  ui.view.scheduleFrame();
}
