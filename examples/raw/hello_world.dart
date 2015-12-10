// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:sky_services/pointer/pointer.mojom.dart';

ui.Color color;

ui.Picture paint(ui.Rect paintBounds) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
  ui.Size size = paintBounds.size;

  double radius = size.shortestSide * 0.45;
  ui.Paint paint = new ui.Paint()
    ..color = color;
  canvas.drawCircle(size.center(ui.Point.origin), radius, paint);

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
  ui.Rect paintBounds = ui.Point.origin & ui.window.size;
  ui.Picture picture = paint(paintBounds);
  ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
}

void handlePopRoute() {
  print('Pressed back button.');
}

void handlePointerPacket(ByteData serializedPacket) {
  bindings.Message message = new bindings.Message(
      serializedPacket, <core.MojoHandle>[],
      serializedPacket.lengthInBytes, 0);
  PointerPacket packet = PointerPacket.deserialize(message);

  for (Pointer pointer in packet.pointers) {
    if (pointer.type == PointerType.DOWN) {
      color = new ui.Color.fromARGB(255, 0, 0, 255);
      ui.window.scheduleFrame();
    } else if (pointer.type == PointerType.UP) {
      color = new ui.Color.fromARGB(255, 0, 255, 0);
      ui.window.scheduleFrame();
    }
  }
}

void main() {
  print('Hello, world');
  color = new ui.Color.fromARGB(255, 0, 255, 0);
  ui.window.onBeginFrame = beginFrame;
  ui.window.onPopRoute = handlePopRoute;
  ui.window.onPointerPacket = handlePointerPacket;
  ui.window.scheduleFrame();
}
