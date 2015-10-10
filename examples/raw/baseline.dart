// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:typed_data';

void drawText(ui.Canvas canvas, String lh) {
  ui.Paint paint = new ui.Paint();

  // offset down
  canvas.translate(0.0, 100.0);

  // set up the text
  ui.Document document = new ui.Document();
  ui.Text arabic = document.createText("مرحبا");
  ui.Text english = document.createText(" Hello");
  ui.Element block = document.createElement('div');
  block.style['display'] = 'paragraph';
  block.style['font-family'] = 'monospace';
  block.style['font-size'] = '50px';
  block.style['line-height'] = lh;
  block.style['color'] = '#0000A0';
  block.appendChild(arabic);
  block.appendChild(english);
  ui.LayoutRoot layoutRoot = new ui.LayoutRoot();
  layoutRoot.rootElement = block;
  layoutRoot.maxWidth = ui.view.width - 20.0; // you need to set a width for this to paint
  layoutRoot.layout();

  // draw a line at the text's baseline
  ui.Path path = new ui.Path();
  path.moveTo(0.0, 0.0);
  path.lineTo(block.maxContentWidth, 0.0);
  path.moveTo(0.0, block.alphabeticBaseline);
  path.lineTo(block.maxContentWidth, block.alphabeticBaseline);
  path.moveTo(0.0, block.height);
  path.lineTo(block.maxContentWidth, block.height);
  paint.color = const ui.Color(0xFFFF9000);
  paint.setStyle(ui.PaintingStyle.stroke);
  paint.strokeWidth = 3.0;
  canvas.drawPath(path, paint);

  // paint the text
  layoutRoot.paint(canvas);
}

ui.Picture paint(ui.Rect paintBounds) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  ui.Paint paint = new ui.Paint();
  paint.color = const ui.Color(0xFFFFFFFF);
  paint.setStyle(ui.PaintingStyle.fill);
  canvas.drawRect(new ui.Rect.fromLTRB(0.0, 0.0, ui.view.width, ui.view.height), paint);

  canvas.translate(10.0, 0.0);
  drawText(canvas, '1.0');
  drawText(canvas, 'lh');

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
  ui.Rect paintBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width, ui.view.height);
  ui.Picture picture = paint(paintBounds);
  ui.Scene scene = composite(picture, paintBounds);
  ui.view.scene = scene;
}

void main() {
  ui.view.setFrameCallback(beginFrame);
  ui.view.scheduleFrame();
}
