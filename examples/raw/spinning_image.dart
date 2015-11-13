// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:sky_services/pointer/pointer.mojom.dart';

Duration timeBase = null;

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
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = (timeStamp - timeBase).inMicroseconds / Duration.MICROSECONDS_PER_MILLISECOND;
  ui.Rect paintBounds = ui.Point.origin & ui.window.size;
  ui.Picture picture = paint(paintBounds, delta);
  ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
  ui.window.scheduleFrame();
}


void handleImageLoad(result) {
  if (result != image) {
    print("${result.width}x${result.width} image loaded!");
    image = result;
    ui.window.scheduleFrame();
  } else {
    print("Existing image was loaded again");
  }
}

void handlePointerPacket(ByteData serializedPacket) {
  bindings.Message message = new bindings.Message(
      serializedPacket, <core.MojoHandle>[],
      serializedPacket.lengthInBytes, 0);
  PointerPacket packet = PointerPacket.deserialize(message);

  for (Pointer pointer in packet.pointers) {
    if (pointer.type == PointerType.UP) {
      imageCache.load(url2).first.then(handleImageLoad);
    }
  }
}

void main() {
  imageCache.load(url1).first.then(handleImageLoad);
  ui.window.onPointerPacket = handlePointerPacket;
  ui.window.onBeginFrame = beginFrame;
}
