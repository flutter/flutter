// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

void beginFrame(double timeStamp) {
  var size = 100.0;
  PictureRecorder canvas = new PictureRecorder(view.width, view.height);
  canvas.translate(size + 10.0, size + 10.0);

  Paint paint = new Paint();
  paint.color = const Color.fromARGB(255, 0, 255, 0);
  var builder = new LayerDrawLooperBuilder()
    // Shadow layer.
    ..addLayerOnTop(
        new DrawLooperLayerInfo()
          ..setPaintBits(PaintBits.all)
          ..setOffset(const Point(5.0, 5.0))
          ..setColorMode(TransferMode.srcInMode),
        (Paint layerPaint) {
      layerPaint.color = const Color.fromARGB(128, 55, 55, 55);
      layerPaint.setMaskFilter(
          new MaskFilter.blur(BlurStyle.normal, 5.0, highQuality: true));
    })
    // Main layer.
    ..addLayerOnTop(new DrawLooperLayerInfo(), (Paint) {});
  paint.setDrawLooper(builder.build());

  canvas.drawPaint(
      new Paint()..color = const Color.fromARGB(255, 255, 255, 255));
  canvas.drawRect(new Rect.fromLTRB(-size, -size, size, size), paint);
  view.picture = canvas.endRecording();
}

void main() {
  view.setBeginFrameCallback(beginFrame);
  view.scheduleFrame();
}
