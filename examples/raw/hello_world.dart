// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:typed_data';

sky.Color color;

sky.Picture paint(sky.Rect paintBounds) {
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, paintBounds);
  sky.Size size = paintBounds.size;

  double radius = size.shortestSide * 0.45;
  sky.Paint paint = new sky.Paint()
    ..color = color;
  canvas.drawCircle(size.center(sky.Point.origin), radius, paint);

  return recorder.endRecording();
}

sky.Scene composite(sky.Picture picture, sky.Rect paintBounds) {
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
  return sceneBuilder.build();
}

void beginFrame(double timeStamp) {
  sky.Rect paintBounds = new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width, sky.view.height);
  sky.Picture picture = paint(paintBounds);
  sky.Scene scene = composite(picture, paintBounds);
  sky.view.scene = scene;
}

bool handleEvent(sky.Event event) {
  if (event.type == 'pointerdown') {
    color = new sky.Color.fromARGB(255, 0, 0, 255);
    sky.view.scheduleFrame();
    return true;
  }

  if (event.type == 'pointerup') {
    color = new sky.Color.fromARGB(255, 0, 255, 0);
    sky.view.scheduleFrame();
    return true;
  }

  if (event.type == 'back') {
    print('Pressed back button.');
    return true;
  }

  return false;
}

void main() {
  print('Hello, world');
  color = new sky.Color.fromARGB(255, 0, 255, 0);
  sky.view.setFrameCallback(beginFrame);
  sky.view.setEventCallback(handleEvent);
  sky.view.scheduleFrame();
}
