// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:typed_data';

double timeBase = null;
sky.LayoutRoot layoutRoot = new sky.LayoutRoot();

sky.Picture paint(sky.Rect paintBounds, double delta) {
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, paintBounds);

  canvas.translate(sky.view.width / 2.0, sky.view.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.drawRect(new sky.Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new sky.Paint()..color = const sky.Color.fromARGB(255, 0, 255, 0));

  double sin = math.sin(delta / 200);
  layoutRoot.maxWidth = 150.0 + (50 * sin);
  layoutRoot.layout();

  canvas.translate(layoutRoot.maxWidth / -2.0, (layoutRoot.maxWidth / 2.0) - 125);
  layoutRoot.paint(canvas);

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
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  sky.Rect paintBounds = new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width, sky.view.height);
  sky.Picture picture = paint(paintBounds, delta);
  sky.Scene scene = composite(picture, paintBounds);
  sky.view.scene = scene;
  sky.view.scheduleFrame();
}

void main() {
  var document = new sky.Document();
  var arabic = document.createText("هذا هو قليلا طويلة من النص الذي يجب التفاف .");
  var more = document.createText(" و أكثر قليلا لجعله أطول. ");
  var block = document.createElement('p');
  block.style['display'] = 'paragraph';
  block.style['direction'] = 'rtl';
  block.style['unicode-bidi'] = 'plaintext';
  block.style['color'] = 'black';
  block.appendChild(arabic);
  block.appendChild(more);

  layoutRoot.rootElement = block;

  sky.view.setFrameCallback(beginFrame);
  sky.view.scheduleFrame();
}
