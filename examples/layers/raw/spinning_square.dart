// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to perform a simple animation using the raw interface
// to the engine.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

void beginFrame(Duration timeStamp) {
  // The timeStamp argument to beginFrame indicates the timing information we
  // should use to clock our animations. It's important to use timeStamp rather
  // than reading the system time because we want all the parts of the system to
  // coordinate the timings of their animations. If each component read the
  // system clock independently, the animations that we processed later would be
  // slightly ahead of the animations we processed earlier.

  // PAINT

  final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
  final ui.PictureRecorder recorder = new ui.PictureRecorder();
  final ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
  canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);

  // Here we determine the rotation according to the timeStamp given to us by
  // the engine.
  final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1800.0;
  canvas.rotate(math.pi * (t % 1.0));

  canvas.drawRect(new ui.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0));
  final ui.Picture picture = recorder.endRecording();

  // COMPOSITE

  final double devicePixelRatio = ui.window.devicePixelRatio;
  final Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  final ui.SceneBuilder sceneBuilder = new ui.SceneBuilder()
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  ui.window.render(sceneBuilder.build());

  // After rendering the current frame of the animation, we ask the engine to
  // schedule another frame. The engine will call beginFrame again when its time
  // to produce the next frame.
  ui.window.scheduleFrame();
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}
