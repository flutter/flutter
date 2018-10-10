// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {

  test('Animation metadata', () async {
    Uint8List data = await _getSkiaResource('alphabetAnim.gif').readAsBytes();
    ui.Codec codec = await ui.instantiateImageCodec(data);
    expect(codec, isNotNull);
    expect(codec.frameCount, 13);
    expect(codec.repetitionCount, 0);
    codec.dispose();

    data = await _getSkiaResource('test640x479.gif').readAsBytes();
    codec = await ui.instantiateImageCodec(data);
    expect(codec.frameCount, 4);
    expect(codec.repetitionCount, -1);
  });

  test('Fails with invalid data', () async {
    Uint8List data = new Uint8List.fromList([1, 2, 3]);
    expect(
      ui.instantiateImageCodec(data),
      throwsA(exceptionWithMessage('operation failed'))
    );
  });

  test('nextFrame', () async {
    Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    ui.Codec codec = await ui.instantiateImageCodec(data);
    List<List<int>> decodedFrameInfos = [];
    for (int i = 0; i < 5; i++) {
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add([
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals([
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
    ]));
  });

  test('decodedCacheRatioCap', () async {
    // No real way to test the native layer, but a smoke test here to at least
    // verify that animation is still consistent with caching disabled.
    Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    ui.Codec codec = await ui.instantiateImageCodec(data, decodedCacheRatioCap: 1.0);
    List<List<int>> decodedFrameInfos = [];
    for (int i = 0; i < 5; i++) {
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add([
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals([
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
    ]));
  });

  test('non animated image', () async {
    Uint8List data = await _getSkiaResource('baby_tux.png').readAsBytes();
    ui.Codec codec = await ui.instantiateImageCodec(data);
    List<List<int>> decodedFrameInfos = [];
    for (int i = 0; i < 2; i++) {
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add([
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals([
      [0, 240, 246],
      [0, 240, 246],
    ]));
  });
}

/// Returns a File handle to a file in the skia/resources directory.
File _getSkiaResource(String fileName) {
  // As Platform.script is not working for flutter_tester
  // (https://github.com/flutter/flutter/issues/12847), this is currently
  // assuming the curent working directory is engine/src.
  // This is fragile and should be changed once the Platform.script issue is
  // resolved.
  String assetPath =
    path.join('third_party', 'skia', 'resources', 'images', fileName);
  return new File(assetPath);
}

Matcher exceptionWithMessage(String m) {
  return predicate((e) {
    return e is Exception && e.toString().contains(m);
  });
}
