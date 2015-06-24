// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky';

import 'package:sky/mojo/net/image_cache.dart' as image_cache;

double timeBase = null;

Image image = null;
String url1 = "https://www.dartlang.org/logos/dart-logo.png";
String url2 = "http://i2.kym-cdn.com/photos/images/facebook/000/581/296/c09.jpg";

void beginFrame(double timeStamp) {
  if (timeBase == null) timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  PictureRecorder recorder = new PictureRecorder();
  Canvas canvas = new Canvas(recorder, view.width, view.height);
  canvas.translate(view.width / 2.0, view.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.scale(0.2, 0.2);
  Paint paint = new Paint()..color = const Color.fromARGB(255, 0, 255, 0);

  // Draw image
  if (image != null)
    canvas.drawImage(image, -image.width / 2.0, -image.height / 2.0, paint);

  // Draw cut out of image
  canvas.rotate(math.PI * delta / 1800);
  if (image != null) {
    var w = image.width.toDouble();
    var h = image.width.toDouble();
    canvas.drawImageRect(image,
      new Rect.fromLTRB(w * 0.25, h * 0.25, w * 0.75, h * 0.75),
      new Rect.fromLTRB(-w / 4.0, -h / 4.0, w / 4.0, h / 4.0),
      paint);
  }

  view.picture = recorder.endRecording();
  view.scheduleFrame();
}

void handleImageLoad(result) {
  if (result != image) {
    print("${result.width}x${result.width} image loaded!");
    image = result;
    view.scheduleFrame();
  } else {
    print("Existing image was loaded again");
  }
}

bool handleEvent(Event event) {
  if (event.type == "pointerdown") {
    return true;
  }

  if (event.type == "pointerup") {
    image_cache.load(url2, handleImageLoad);
    return true;
  }

  return false;
}

void main() {
  image_cache.load(url1, handleImageLoad);
  image_cache.load(url1, handleImageLoad);
  view.setEventCallback(handleEvent);
  view.setBeginFrameCallback(beginFrame);
}
