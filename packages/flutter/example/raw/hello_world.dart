// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

Picture draw(int a, int r, int g, int b) {
  Size size = new Size(view.width, view.height);

  PictureRecorder recorder = new PictureRecorder();
  Canvas canvas = new Canvas(recorder, Point.origin & size);
  double radius = size.shortestSide * 0.45;

  Paint paint = new Paint()..color = new Color.fromARGB(a, r, g, b);
  canvas.drawCircle(size.center(Point.origin), radius, paint);
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

  if (event.type == "back") {
    print("Pressed back button.");
    return true;
  }

  return false;
}

void main() {
  print("Hello, world");
  view.picture = draw(255, 0, 255, 0);
  view.scheduleFrame();

  view.setEventCallback(handleEvent);
}
