// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

void drawText(sky.Canvas canvas, String lh) {
  sky.Paint paint = new sky.Paint();

  // offset down
  canvas.translate(0.0, 100.0);

  // set up the text
  sky.Document document = new sky.Document();
  sky.Text arabic = document.createText("مرحبا");
  sky.Text english = document.createText(" Hello");
  sky.Element block = document.createElement('div');
  block.style['display'] = 'paragraph';
  block.style['font-family'] = 'monospace';
  block.style['font-size'] = '50px';
  block.style['line-height'] = lh;
  block.style['color'] = '#0000A0';
  block.appendChild(arabic);
  block.appendChild(english);
  sky.LayoutRoot layoutRoot = new sky.LayoutRoot();
  layoutRoot.rootElement = block;
  layoutRoot.maxWidth = sky.view.width - 20.0; // you need to set a width for this to paint
  layoutRoot.layout();

  // draw a line at the text's baseline
  sky.Path path = new sky.Path();
  path.moveTo(0.0, 0.0);
  path.lineTo(block.maxContentWidth, 0.0);
  path.moveTo(0.0, block.alphabeticBaseline);
  path.lineTo(block.maxContentWidth, block.alphabeticBaseline);
  path.moveTo(0.0, block.height);
  path.lineTo(block.maxContentWidth, block.height);
  paint.color = const sky.Color(0xFFFF9000);
  paint.setStyle(sky.PaintingStyle.stroke);
  paint.strokeWidth = 3.0;
  canvas.drawPath(path, paint);  

  // paint the text
  layoutRoot.paint(canvas);
}

void main() {
  // prepare the rendering
  sky.PictureRecorder canvas = new sky.PictureRecorder(sky.view.width, sky.view.height);

  // background
  sky.Paint paint = new sky.Paint();
  paint.color = const sky.Color(0xFFFFFFFF);
  paint.setStyle(sky.PaintingStyle.fill);
  canvas.drawRect(new sky.Rect.fromLTRB(0.0, 0.0, sky.view.width, sky.view.height), paint);

  canvas.translate(10.0, 0.0);
  drawText(canvas, '1.0');
  drawText(canvas, 'lh');

  // put it on the screen
  sky.view.picture = canvas.endRecording();
  sky.view.scheduleFrame();
}
