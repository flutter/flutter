// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

double timeBase = null;

Image image = null;

void beginFrame(double timeStamp) {
  if (timeBase == null) timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  PictureRecorder canvas = new PictureRecorder(view.width, view.height);
  canvas.translate(view.width / 2.0, view.height / 2.0);
  canvas.rotateDegrees(delta / 10);
  canvas.scale(0.2, 0.2);
  Paint paint = new Paint()..setARGB(255, 0, 255, 0);
  if (image != null)
    canvas.drawImage(image, -image.width / 2.0, -image.height / 2.0, paint);
  view.picture = canvas.endRecording();
  view.scheduleFrame();
}

void main() {
  new ImageLoader("https://www.dartlang.org/logos/dart-logo.png", (result) {
    if (result != null) {
      print("${result.width}x${result.width} image loaded!");
      image = result;
      view.scheduleFrame();
    } else {
      print("Image failed to load");
    }
  }).load();
  view.setBeginFrameCallback(beginFrame);
}
