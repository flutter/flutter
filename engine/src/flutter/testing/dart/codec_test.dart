// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    final Uint8List data = Uint8List.fromList(<int>[1, 2, 3]);
    expect(
      () => ui.instantiateImageCodec(data),
      throwsA(exceptionWithMessage('Could not instantiate image codec.'))
    );
  });

  test('nextFrame', () async {
    final Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    final List<List<int>> decodedFrameInfos = <List<int>>[];
    for (int i = 0; i < 5; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add(<int>[
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals(<List<int>>[
      <int>[200, 640, 479],
      <int>[200, 640, 479],
      <int>[200, 640, 479],
      <int>[200, 640, 479],
      <int>[200, 640, 479],
    ]));
  });

  test('non animated image', () async {
    final Uint8List data = await _getSkiaResource('baby_tux.png').readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    final List<List<int>> decodedFrameInfos = <List<int>>[];
    for (int i = 0; i < 2; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add(<int>[
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals(<List<int>>[
      <int>[0, 240, 246],
      <int>[0, 240, 246],
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
  final String assetPath =
    path.join('third_party', 'skia', 'resources', 'images', fileName);
  return File(assetPath);
}

Matcher exceptionWithMessage(String m) {
  return predicate<Exception>((Exception e) {
    return e is Exception && e.toString().contains(m);
  });
}
