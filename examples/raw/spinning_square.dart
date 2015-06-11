// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'dart:math' as math;

double timeBase = null;

void beginFrame(double timeStamp) {
  tracing.begin('beginFrame');
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  PictureRecorder canvas = new PictureRecorder(view.width, view.height);
  canvas.translate(view.width / 2.0, view.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.drawRect(new Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new Paint()..color = Color.fromARGB(255, 0, 255, 0));
  view.picture = canvas.endRecording();
  view.scheduleFrame();
  tracing.end('beginFrame');
}

void main() {
  view.setBeginFrameCallback(beginFrame);
  view.scheduleFrame();
}
