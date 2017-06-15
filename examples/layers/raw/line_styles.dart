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
  const double kRadius = 100.0;
  const double kTwoPi = math.PI * 2.0;
  const double kVerticalOffset = 100.0;

  final ui.Rect paintBounds =
      ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
  final ui.PictureRecorder recorder = new ui.PictureRecorder();
  final ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
  canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);

  // Here we determine the rotation speed according to the timeStamp given to us
  // by the engine.
  final double t = (timeStamp.inMicroseconds /
          Duration.MICROSECONDS_PER_MILLISECOND /
          3200.0) % 1.0;

  final List<ui.Offset> points = <ui.Offset>[
    const ui.Offset(kRadius, kVerticalOffset),
    const ui.Offset(0.0, kVerticalOffset),
    new ui.Offset(kRadius * math.cos(t * kTwoPi),
        kRadius * math.sin(t * kTwoPi) + kVerticalOffset),
  ];

  // Try changing values for the stroke style and see what the results are
  // for different line drawing primitives.
  final ui.Paint paint = new ui.Paint()
    ..color = const ui.Color.fromARGB(255, 0, 255, 0)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.butt  // Other choices are round and square.
    ..strokeJoin = ui.StrokeJoin.miter  // Other choices are round and bevel.
    ..strokeMiterLimit = 5.0 // Try smaller and larger values greater than zero.
    ..strokeWidth = 20.0;
  canvas.drawPoints(ui.PointMode.polygon, points, paint);

  final ui.Path path = new ui.Path()
    ..moveTo(points[0].dx, points[0].dy - 2 * kVerticalOffset)
    ..lineTo(points[1].dx, points[1].dy - 2 * kVerticalOffset)
    ..lineTo(points[2].dx, points[2].dy - 2 * kVerticalOffset)
    ..close();
  canvas.drawPath(path, paint);
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
