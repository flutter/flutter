// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

double timeBase = null;

void beginFrame(double timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  PictureRecorder canvas = new PictureRecorder(view.width, view.height);
  canvas.translate(view.width / 2.0, view.height / 2.0);
  canvas.rotateDegrees(delta / 10);
  canvas.drawRect(new Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new Paint()..setARGB(255, 0, 255, 0));
  view.picture = canvas.endRecording();
  view.scheduleFrame();
}

void main() {
  view.setBeginFrameCallback(beginFrame);
  view.scheduleFrame();
}
