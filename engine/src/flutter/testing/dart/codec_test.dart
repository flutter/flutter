// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:litetest/litetest.dart';
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
    try {
      await ui.instantiateImageCodec(data);
      fail('exception not thrown');
    } on Exception catch (e) {
      expect(e.toString(), contains('Invalid image data'));
    }
  });

  test('getNextFrame fails with invalid data', () async {
    Uint8List data = await _getSkiaResource('flutter_logo.jpg').readAsBytes();
    data = Uint8List.view(data.buffer, 0, 4000);
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    try {
      await codec.getNextFrame();
      fail('exception not thrown');
    } on Exception catch (e) {
      expect(e.toString(), contains('Codec failed'));
    }
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

  test('with size', () async {
    final Uint8List data = await _getSkiaResource('baby_tux.png').readAsBytes();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(data);
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (int intrinsicWidth, int intrinsicHeight) {
        return ui.TargetImageSize(
          width: intrinsicWidth ~/ 2,
          height: intrinsicHeight ~/ 2,
        );
      },
    );
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
      <int>[0, 120, 123],
      <int>[0, 120, 123],
    ]));
  });

  test('disposed decoded image', () async {
    final Uint8List data = await _getSkiaResource('flutter_logo.jpg').readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    expect(frameInfo.image, isNotNull);
    frameInfo.image.dispose();
    try {
      await codec.getNextFrame();
      fail('exception not thrown');
    } on Exception catch (e) {
      expect(e.toString(), contains('Decoded image has been disposed'));
    }
  });

  test('Animated gif can reuse across multiple frames', () async {
    // Regression test for b/271947267 and https://github.com/flutter/flutter/issues/122134

    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'four_frame_with_reuse.gif'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // Capture the final frame of animation. If we have not composited
    // correctly, it will be clipped strangely.
    late ui.FrameInfo frameInfo;
    for (int i = 0; i < 4; i++) {
      frameInfo = await codec.getNextFrame();
    }

    final ui.Image image = frameInfo.image;
    final ByteData imageData = (await image.toByteData(format: ui.ImageByteFormat.png))!;

    final Uint8List goldenData = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'four_frame_with_reuse_end.png'),
    ).readAsBytesSync();

    expect(imageData.buffer.asUint8List(), goldenData);
  });

  test('Animated webp can reuse across multiple frames', () async {
    // Regression test for https://github.com/flutter/flutter/issues/61150#issuecomment-679055858

    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'heart.webp'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // Capture the final frame of animation. If we have not composited
    // correctly, the hearts will be incorrectly repeated in the image.
    late ui.FrameInfo frameInfo;
    for (int i = 0; i < 69; i++) {
      frameInfo  = await codec.getNextFrame();
    }

    final ui.Image image = frameInfo.image;
    final ByteData imageData = (await image.toByteData(format: ui.ImageByteFormat.png))!;

    final Uint8List goldenData = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'heart_end.png'),
    ).readAsBytesSync();

    expect(imageData.buffer.asUint8List(), goldenData);

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
