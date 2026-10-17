// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'impeller_enabled.dart';

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
    final data = Uint8List.fromList(<int>[1, 2, 3]);
    try {
      await ui.instantiateImageCodec(data);
      fail('exception not thrown');
    } on Exception catch (e) {
      expect(e.toString(), contains('Invalid image data'));
    }
  });

  test('getNextFrame fails with invalid data', () async {
    Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    data = Uint8List.view(data.buffer, 0, 4000);
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    try {
      await codec.getNextFrame();
      fail('exception not thrown');
    } on Exception catch (e) {
      if (impellerEnabled) {
        expect(e.toString(), contains('Could not decompress image.'));
      } else {
        expect(e.toString(), contains('Codec failed'));
      }
    } finally {
      codec.dispose();
    }
  });

  test('nextFrame', () async {
    final Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    final decodedFrameInfos = <List<int>>[];
    for (var i = 0; i < 5; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add(<int>[
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    codec.dispose();
    expect(
      decodedFrameInfos,
      equals(<List<int>>[
        <int>[200, 640, 479],
        <int>[200, 640, 479],
        <int>[200, 640, 479],
        <int>[200, 640, 479],
        <int>[200, 640, 479],
      ]),
    );
  });

  test('non animated image', () async {
    final Uint8List data = await _getSkiaResource('baby_tux.png').readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    final decodedFrameInfos = <List<int>>[];
    for (var i = 0; i < 2; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add(<int>[
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    codec.dispose();
    expect(
      decodedFrameInfos,
      equals(<List<int>>[
        <int>[0, 240, 246],
        <int>[0, 240, 246],
      ]),
    );
  });

  test('with size', () async {
    final Uint8List data = await _getSkiaResource('baby_tux.png').readAsBytes();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(data);
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (int intrinsicWidth, int intrinsicHeight) {
        return ui.TargetImageSize(width: intrinsicWidth ~/ 2, height: intrinsicHeight ~/ 2);
      },
    );
    final decodedFrameInfos = <List<int>>[];
    for (var i = 0; i < 2; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      decodedFrameInfos.add(<int>[
        frameInfo.duration.inMilliseconds,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    codec.dispose();
    expect(
      decodedFrameInfos,
      equals(<List<int>>[
        <int>[0, 120, 123],
        <int>[0, 120, 123],
      ]),
    );
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
    codec.dispose();
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
    for (var i = 0; i < 4; i++) {
      frameInfo = await codec.getNextFrame();
    }
    codec.dispose();

    final ui.Image image = frameInfo.image;
    final ByteData imageData = (await image.toByteData(format: ui.ImageByteFormat.png))!;

    final fileName = impellerEnabled
        ? 'impeller_four_frame_with_reuse_end.png'
        : 'four_frame_with_reuse_end.png';
    final Uint8List goldenData = File(path.join('flutter', 'lib', 'ui', 'fixtures', fileName))
        .readAsBytesSync();

    expect(imageData.buffer.asUint8List(), goldenData);
  });

  test('Animated webp decodes a frame with alpha after an opaque first frame', () async {
    // Regression test for https://github.com/flutter/flutter/issues/85831
    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'opaque_first_frame_then_alpha.webp'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // The test image contains two solid frames. The first is opaque red, and
    // the second is blue with alpha=128.
    ui.Image image = (await codec.getNextFrame()).image;
    ByteData imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0xFF0000FF);
    image = (await codec.getNextFrame()).image;
    imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0x00008080);
    codec.dispose();
  });

  test('Animated gif decodes a frame with alpha after an opaque first frame', () async {
    // Regression test for https://github.com/flutter/flutter/issues/85831
    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'opaque_first_frame_then_alpha.gif'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // The test image contains two frames that restore to the background. The
    // first is opaque red, and the second is transparent except for one blue
    // pixel in the top left corner.
    ui.Image image = (await codec.getNextFrame()).image;
    ByteData imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0xFF0000FF);
    image = (await codec.getNextFrame()).image;
    imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0x0000FFFF);
    expect(imageData.getUint32(4), 0x00000000);
    codec.dispose();
  });

  test('Animated webp can reuse across multiple frames', () async {
    // Regression test for https://github.com/flutter/flutter/issues/61150#issuecomment-679055858

    final Uint8List data = File(path.join('flutter', 'lib', 'ui', 'fixtures', 'heart.webp'))
        .readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // Capture the final frame of animation. If we have not composited
    // correctly, the hearts will be incorrectly repeated in the image.
    late ui.FrameInfo frameInfo;
    for (var i = 0; i < 69; i++) {
      frameInfo = await codec.getNextFrame();
    }
    codec.dispose();

    final ui.Image image = frameInfo.image;
    final ByteData imageData = (await image.toByteData(format: ui.ImageByteFormat.png))!;

    final fileName = impellerEnabled ? 'impeller_heart_end.png' : 'heart_end.png';

    final Uint8List goldenData = File(path.join('flutter', 'lib', 'ui', 'fixtures', fileName))
        .readAsBytesSync();

    expect(imageData.buffer.asUint8List(), goldenData);
  });

  test('Animated apng can reuse pre-pre-frame', () async {
    // https://github.com/flutter/engine/pull/42153

    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', '2_dispose_op_restore_previous.apng'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // Capture the 67,68,69 frames of animation and then compare the pixels.
    late ui.FrameInfo frameInfo;
    for (var i = 0; i < 70; i++) {
      frameInfo = await codec.getNextFrame();
      if (i >= 67) {
        final ui.Image image = frameInfo.image;
        final ByteData imageData = (await image.toByteData(format: ui.ImageByteFormat.png))!;

        final fileName = impellerEnabled
            ? 'impeller_2_dispose_op_restore_previous.apng.$i.png'
            : '2_dispose_op_restore_previous.apng.$i.png';

        final Uint8List goldenData = File(path.join('flutter', 'lib', 'ui', 'fixtures', fileName))
            .readAsBytesSync();

        expect(imageData.buffer.asUint8List(), goldenData);
      }
    }
    codec.dispose();
  });

  test('Animated apng alpha type handling', () async {
    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'alpha_animated.apng'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // The test image contains two frames of solid red.  The first has
    // alpha=0.2, and the second has alpha=0.6.
    ui.Image image = (await codec.getNextFrame()).image;
    ByteData imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0x33000033);
    image = (await codec.getNextFrame()).image;
    imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0x99000099);
    codec.dispose();
  });

  test('Animated apng background color restore', () async {
    final Uint8List data = File(
      path.join('flutter', 'lib', 'ui', 'fixtures', 'dispose_op_background.apng'),
    ).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data);

    // First frame is solid red
    ui.Image image = (await codec.getNextFrame()).image;
    ByteData imageData = (await image.toByteData())!;
    expect(imageData.getUint32(0), 0xFF0000FF);

    // Third frame is blue in the lower right corner.
    await codec.getNextFrame();
    image = (await codec.getNextFrame()).image;
    imageData = (await image.toByteData())!;
    expect(imageData.getUint32(imageData.lengthInBytes - 4), 0x0000FFFF);

    // Fourth frame is transparent in the lower right corner
    image = (await codec.getNextFrame()).image;
    imageData = (await image.toByteData())!;
    expect(imageData.getUint32(imageData.lengthInBytes - 4), 0x00000000);
    codec.dispose();
  });

  test('Animated apng frame decode does not crash with invalid destination region', () async {
    final Uint8List data = File(path.join('flutter', 'lib', 'ui', 'fixtures', 'out_of_bounds.apng'))
        .readAsBytesSync();

    final ui.Codec codec = await ui.instantiateImageCodec(data);
    try {
      await codec.getNextFrame();
      fail('exception not thrown');
    } on Exception catch (e) {
      if (impellerEnabled) {
        expect(e.toString(), contains('Could not decompress image.'));
      } else {
        expect(e.toString(), contains('Codec failed'));
      }
    } finally {
      codec.dispose();
    }
  });

  test(
    'Animated apng frame decode does not crash with invalid destination region and bounds wrapping',
    () async {
      final Uint8List data = File(
        path.join('flutter', 'lib', 'ui', 'fixtures', 'out_of_bounds_wrapping.apng'),
      ).readAsBytesSync();

      final ui.Codec codec = await ui.instantiateImageCodec(data);
      try {
        await codec.getNextFrame();
        fail('exception not thrown');
      } on Exception catch (e) {
        if (impellerEnabled) {
          expect(e.toString(), contains('Could not decompress image.'));
        } else {
          expect(e.toString(), contains('Codec failed'));
        }
      } finally {
        codec.dispose();
      }
    },
  );

  test('Animated gif frames are resized to targetWidth and targetHeight', () async {
    // Regression test for https://github.com/flutter/flutter/issues/90804
    final Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(
      data,
      targetWidth: 160,
      targetHeight: 120,
    );
    expect(codec.frameCount, 4);

    // Decode two loops so that frames composited on top of a cached backdrop
    // after the animation wraps around are covered as well.
    for (var i = 0; i < codec.frameCount * 2; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image.width, 160);
      expect(frameInfo.image.height, 120);
      frameInfo.image.dispose();
    }
    codec.dispose();
  });

  test('Animated webp frames are resized when only targetWidth is given', () async {
    final Uint8List data = File(path.join('flutter', 'lib', 'ui', 'fixtures', 'heart.webp'))
        .readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(data, targetWidth: 100);
    expect(codec.frameCount, 69);

    for (var i = 0; i < codec.frameCount; i++) {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image.width, 100);
      expect(frameInfo.image.height, 100);
      frameInfo.image.dispose();
    }
    codec.dispose();
  });

  test('instantiateImageCodecWithSize resizes animated images', () async {
    // Regression test for https://github.com/flutter/flutter/issues/137668
    final Uint8List data = File(path.join('flutter', 'lib', 'ui', 'fixtures', 'heart.webp'))
        .readAsBytesSync();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(data);
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (int intrinsicWidth, int intrinsicHeight) {
        expect(intrinsicWidth, 500);
        expect(intrinsicHeight, 500);
        return const ui.TargetImageSize(width: 50, height: 50);
      },
    );

    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    expect(frameInfo.image.width, 50);
    expect(frameInfo.image.height, 50);
    frameInfo.image.dispose();
    codec.dispose();
  });

  test('Resized animated frames match the downscaled full-size frames', () async {
    // Frames of animated images are composited at the intrinsic size of the
    // image, and only the finished frame is resized. At exactly half of the
    // intrinsic size, bilinear filtering samples every destination pixel
    // exactly between four source pixels, so each resized pixel must be the
    // average of the corresponding 2x2 block of the full-size frame. This
    // covers frame reuse, disposal and blending in GIF, WebP and APNG.
    final fixtures = <String, Uint8List>{
      'alphabetAnim.gif': await _getSkiaResource('alphabetAnim.gif').readAsBytes(),
      for (final name in <String>[
        'four_frame_with_reuse.gif',
        'heart.webp',
        '2_dispose_op_restore_previous.apng',
        'dispose_op_background.apng',
      ])
        name: File(path.join('flutter', 'lib', 'ui', 'fixtures', name)).readAsBytesSync(),
    };

    for (final MapEntry<String, Uint8List> fixture in fixtures.entries) {
      final ui.Codec fullCodec = await ui.instantiateImageCodec(fixture.value);
      ui.Codec? halfCodec;
      for (var i = 0; i < fullCodec.frameCount; i++) {
        final ui.Image full = (await fullCodec.getNextFrame()).image;
        expect(full.width.isEven && full.height.isEven, isTrue, reason: fixture.key);
        halfCodec ??= await ui.instantiateImageCodec(
          fixture.value,
          targetWidth: full.width ~/ 2,
          targetHeight: full.height ~/ 2,
        );
        final ui.Image half = (await halfCodec.getNextFrame()).image;
        expect(half.width, full.width ~/ 2, reason: fixture.key);
        expect(half.height, full.height ~/ 2, reason: fixture.key);

        final Uint8List expected = _downscaleByHalf(
          (await full.toByteData())!.buffer.asUint8List(),
          full.width,
          full.height,
        );
        final Uint8List actual = (await half.toByteData())!.buffer.asUint8List();
        expect(
          _maxChannelDifference(actual, expected),
          lessThanOrEqualTo(1),
          reason: '${fixture.key}, frame $i',
        );
        full.dispose();
        half.dispose();
      }
      fullCodec.dispose();
      halfCodec?.dispose();
    }
  });
}

/// Returns a File handle to a file in the skia/resources directory.
File _getSkiaResource(String fileName) {
  // As Platform.script is not working for flutter_tester
  // (https://github.com/flutter/flutter/issues/12847), this is currently
  // assuming the curent working directory is engine/src.
  // This is fragile and should be changed once the Platform.script issue is
  // resolved.
  final String assetPath = path.join(
    'flutter',
    'third_party',
    'skia',
    'resources',
    'images',
    fileName,
  );
  return File(assetPath);
}

/// Averages every 2x2 block of an RGBA image whose dimensions are even.
Uint8List _downscaleByHalf(Uint8List rgba, int width, int height) {
  final int halfWidth = width ~/ 2;
  final int halfHeight = height ~/ 2;
  final result = Uint8List(halfWidth * halfHeight * 4);
  for (var y = 0; y < halfHeight; y++) {
    for (var x = 0; x < halfWidth; x++) {
      final int topLeft = (2 * y * width + 2 * x) * 4;
      final int bottomLeft = topLeft + width * 4;
      for (var channel = 0; channel < 4; channel++) {
        final int sum =
            rgba[topLeft + channel] +
            rgba[topLeft + 4 + channel] +
            rgba[bottomLeft + channel] +
            rgba[bottomLeft + 4 + channel];
        result[(y * halfWidth + x) * 4 + channel] = (sum + 2) >> 2;
      }
    }
  }
  return result;
}

/// Returns the largest difference between two equally sized byte buffers.
int _maxChannelDifference(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
  var maxDifference = 0;
  for (var i = 0; i < a.length; i++) {
    final int difference = (a[i] - b[i]).abs();
    if (difference > maxDifference) {
      maxDifference = difference;
    }
  }
  return maxDifference;
}
