// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

Duration timeBase = null;

void beginFrame(Duration timeStamp) {
  Timeline.timeSync('beginFrame', () {
    if (timeBase == null)
      timeBase = timeStamp;
    double delta = (timeStamp - timeBase).inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND;

    // paint
    ui.Rect paintBounds = ui.Point.origin & ui.window.size;
    ui.PictureRecorder recorder = new ui.PictureRecorder();
    ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
    canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);
    canvas.rotate(math.PI * delta / 1800);
    canvas.drawRect(new ui.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                    new ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0));
    ui.Picture picture = recorder.endRecording();

    // composite
    final double devicePixelRatio = ui.window.devicePixelRatio;
    ui.Rect sceneBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.window.size.width * devicePixelRatio, ui.window.size.height * devicePixelRatio);
    Float64List deviceTransform = new Float64List(16)
      ..[0] = devicePixelRatio
      ..[5] = devicePixelRatio
      ..[10] = 1.0
      ..[15] = 1.0;
    ui.SceneBuilder sceneBuilder = new ui.SceneBuilder(sceneBounds)
      ..pushTransform(deviceTransform)
      ..addPicture(ui.Offset.zero, picture, paintBounds)
      ..pop();
    ui.window.render(sceneBuilder.build());
  });

  ui.window.scheduleFrame();
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
