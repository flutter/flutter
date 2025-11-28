// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart'
    if (dart.library.html) 'package:ui/src/engine/skwasm/skwasm_stub.dart';
import 'package:ui/ui.dart';

import '../common/rendering.dart';

Picture drawPicture(void Function(Canvas) drawCommands) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  drawCommands(canvas);
  return recorder.endRecording();
}

/// Draws the [Picture]. This is in preparation for a golden test.
Future<void> drawPictureUsingCurrentRenderer(Picture picture) async {
  final sb = SceneBuilder();
  sb.pushOffset(0, 0);
  sb.addPicture(Offset.zero, picture);
  await renderScene(sb.build());
}

// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> createPlatformView(int id, String viewType) {
  final completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('create', <String, dynamic>{'id': id, 'viewType': viewType})),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

/// Disposes of the platform view with the given [id].
Future<void> disposePlatformView(int id) {
  final completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('dispose', id)),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

Future<bool> matchImage(Image left, Image right) async {
  if (left.width != right.width || left.height != right.height) {
    return false;
  }
  int getPixel(ByteData data, int x, int y) => data.getUint32((x + y * left.width) * 4);
  final ByteData leftData = (await left.toByteData())!;
  final ByteData rightData = (await right.toByteData())!;
  for (var y = 0; y < left.height; y++) {
    for (var x = 0; x < left.width; x++) {
      if (getPixel(leftData, x, y) != getPixel(rightData, x, y)) {
        return false;
      }
    }
  }
  return true;
}

/// Convenience getter for the implicit view.
FlutterView get implicitView => EnginePlatformDispatcher.instance.implicitView!;

/// Returns [true] if this test is running in the CanvasKit renderer.
bool get isCanvasKit => renderer is CanvasKitRenderer;

bool get isSkwasm => renderer is SkwasmRenderer;

bool get isMultiThreaded => isSkwasm && (renderer as SkwasmRenderer).isMultiThreaded;
