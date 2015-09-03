// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'dart:typed_data';

import 'package:sky/mojo/net/image_cache.dart' as image_cache;

double timeBase = null;

sky.Image image = null;
String url1 = "https://www.dartlang.org/logos/dart-logo.png";
String url2 = "http://i2.kym-cdn.com/photos/images/facebook/000/581/296/c09.jpg";

sky.Picture paint(sky.Rect paintBounds, double delta) {
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, paintBounds);

  canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.scale(0.2, 0.2);
  sky.Paint paint = new sky.Paint()..color = const sky.Color.fromARGB(255, 0, 255, 0);

  // Draw image
  if (image != null)
    canvas.drawImage(image, new sky.Point(-image.width / 2.0, -image.height / 2.0), paint);

  // Draw cut out of image
  canvas.rotate(math.PI * delta / 1800);
  if (image != null) {
    var w = image.width.toDouble();
    var h = image.width.toDouble();
    canvas.drawImageRect(image,
      new sky.Rect.fromLTRB(w * 0.25, h * 0.25, w * 0.75, h * 0.75),
      new sky.Rect.fromLTRB(-w / 4.0, -h / 4.0, w / 4.0, h / 4.0),
      paint);
  }

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


void handleImageLoad(result) {
  if (result != image) {
    print("${result.width}x${result.width} image loaded!");
    image = result;
    sky.view.scheduleFrame();
  } else {
    print("Existing image was loaded again");
  }
}

bool handleEvent(sky.Event event) {
  if (event.type == "pointerdown") {
    return true;
  }

  if (event.type == "pointerup") {
    image_cache.load(url2).first.then(handleImageLoad);
    return true;
  }

  return false;
}

void main() {
  image_cache.load(url1).first.then(handleImageLoad);
  sky.view.setEventCallback(handleEvent);
  sky.view.setFrameCallback(beginFrame);
}
