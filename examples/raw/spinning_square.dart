// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

double timeBase = null;

void beginFrame(double timeStamp) {
  ui.tracing.begin('beginFrame');
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;

  // paint
  ui.Rect paintBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width, ui.view.height);
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
  canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.drawRect(new ui.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0));
  ui.Picture picture = recorder.endRecording();

  // composite
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
  ui.view.scene = sceneBuilder.build();

  ui.tracing.end('beginFrame');
  ui.view.scheduleFrame();
}

void main() {
  ui.view.setFrameCallback(beginFrame);
  ui.view.scheduleFrame();
}
