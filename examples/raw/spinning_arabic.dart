// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

Duration timeBase = null;
ui.Paragraph paragraph;

ui.Picture paint(ui.Rect paintBounds, double delta) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  canvas.translate(ui.window.size.width / 2.0, ui.window.size.height / 2.0);
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
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = (timeStamp - timeBase).inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND;
  ui.Rect paintBounds = ui.Point.origin & ui.window.size;
  ui.Picture picture = paint(paintBounds, delta);
  ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
  ui.window.scheduleFrame();
}

void main() {
  // TODO(abarth): We're missing some bidi style information:
  //   block.style['direction'] = 'rtl';
  //   block.style['unicode-bidi'] = 'plaintext';
  ui.ParagraphBuilder builder = new ui.ParagraphBuilder();
  builder.addText("هذا هو قليلا طويلة من النص الذي يجب التفاف .");
  builder.addText(" و أكثر قليلا لجعله أطول. ");
  paragraph = builder.build(new ui.ParagraphStyle());

  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
