// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:math";
import 'dart:sky';

void main() {
  print("Hello, world");

  double width = 500.0;
  double height = 500.0;

  PictureRecorder recorder = new PictureRecorder(width, height);
  double radius = min(width, height) * 0.45;

  Paint paint = new Paint()..setARGB(255, 0, 255, 0);

  recorder.drawCircle(width / 2, height / 2, radius, paint);

  print("Storing picture");
  view.picture = recorder.endRecording();

  print("Scheduling paint");
  view.schedulePaint();
}
