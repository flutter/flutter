// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:math";
import 'dart:sky';

PaintingNode paintingNode = null;
Picture draw(int a, int r, int g, int b) {
  Rect bounds = new Rect.fromLTRB(0.0, 0.0, view.width, view.height);
  Size size = new Size(view.width, view.height);

  PictureRecorder recorder = new PictureRecorder();
  Canvas canvas = new Canvas(recorder, bounds);
  double radius = size.shortestSide * 0.45;

  Paint paint = new Paint()..color = new Color.fromARGB(a, r, g, b);
  canvas.drawCircle(size.center(Point.origin), radius, paint);

  if (paintingNode == null) {
    paintingNode = new PaintingNode();
    Paint innerPaint = new Paint()..color = new Color.fromARGB(a, 255 - r, 255 - g, 255 - b);
    PictureRecorder innerRecorder = new PictureRecorder();
    Canvas innerCanvas = new Canvas(innerRecorder, bounds);
    innerCanvas.drawCircle(size.center(Point.origin), radius * 0.5, innerPaint);

    paintingNode.setBackingDrawable(innerRecorder.endRecordingAsDrawable());
  }
  canvas.drawPaintingNode(paintingNode);

  return recorder.endRecording();
}

bool handleEvent(Event event) {
  if (event.type == "pointerdown") {
    view.picture = draw(255, 0, 0, 255);
    view.scheduleFrame();
    return true;
  }

  if (event.type == "pointerup") {
    view.picture = draw(255, 0, 255, 0);
    view.scheduleFrame();
    return true;
  }

  return false;
}

void main() {
  view.picture = draw(255, 0, 255, 0);
  view.scheduleFrame();

  view.setEventCallback(handleEvent);
}
