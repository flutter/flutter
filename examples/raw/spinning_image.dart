// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';

double timeBase = null;

ui.Image image = null;
String url1 = "https://raw.githubusercontent.com/dart-lang/logos/master/logos_and_wordmarks/dart-logo.png";
String url2 = "http://i2.kym-cdn.com/photos/images/facebook/000/581/296/c09.jpg";

ui.Picture paint(ui.Rect paintBounds, double delta) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

  canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.scale(0.2, 0.2);
  ui.Paint paint = new ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0);

  // Draw image
  if (image != null)
    canvas.drawImage(image, new ui.Point(-image.width / 2.0, -image.height / 2.0), paint);

  // Draw cut out of image
  canvas.rotate(math.PI * delta / 1800);
  if (image != null) {
    var w = image.width.toDouble();
    var h = image.width.toDouble();
    canvas.drawImageRect(image,
      new ui.Rect.fromLTRB(w * 0.25, h * 0.25, w * 0.75, h * 0.75),
      new ui.Rect.fromLTRB(-w / 4.0, -h / 4.0, w / 4.0, h / 4.0),
      paint);
  }

  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
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
  return sceneBuilder.build();
}

void beginFrame(double timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  ui.Rect paintBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width, ui.view.height);
  ui.Picture picture = paint(paintBounds, delta);
  ui.Scene scene = composite(picture, paintBounds);
  ui.view.scene = scene;
  ui.view.scheduleFrame();
}


void handleImageLoad(result) {
  if (result != image) {
    print("${result.width}x${result.width} image loaded!");
    image = result;
    ui.view.scheduleFrame();
  } else {
    print("Existing image was loaded again");
  }
}

bool handleEvent(ui.Event event) {
  if (event.type == "pointerdown") {
    return true;
  }

  if (event.type == "pointerup") {
    imageCache.load(url2).first.then(handleImageLoad);
    return true;
  }

  return false;
}

void main() {
  imageCache.load(url1).first.then(handleImageLoad);
  ui.view.setEventCallback(handleEvent);
  ui.view.setFrameCallback(beginFrame);
}
