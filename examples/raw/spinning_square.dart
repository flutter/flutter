// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:typed_data';

double timeBase = null;

void beginFrame(double timeStamp) {
  sky.tracing.begin('beginFrame');
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;

  // paint
  sky.Rect paintBounds = new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width, sky.view.height);
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, paintBounds);
  canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.drawRect(new sky.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new sky.Paint()..color = const sky.Color.fromARGB(255, 0, 255, 0));
  sky.Picture picture = recorder.endRecording();

  // composite
  final double devicePixelRatio = sky.view.devicePixelRatio;
  sky.Rect sceneBounds = new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width * devicePixelRatio, sky.view.height * devicePixelRatio);
  Float32List deviceTransform = new Float32List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  sky.SceneBuilder sceneBuilder = new sky.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(sky.Offset.zero, picture, paintBounds)
    ..pop();
  sky.view.scene = sceneBuilder.build();

  sky.tracing.end('beginFrame');
  sky.view.scheduleFrame();
}

void main() {
  sky.view.setFrameCallback(beginFrame);
  sky.view.scheduleFrame();
}
