// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 transparent PNG bytes.
final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  test('createTestImage creates and caches an image', () async {
    final ui.Image image1 = await createTestImage(width: 10, height: 10);
    expect(image1.width, 10);
    expect(image1.height, 10);

    final ui.Image image2 = await createTestImage(width: 10, height: 10);
    expect(image2.width, 10);
    expect(image2.height, 10);
  });

  test('precacheTestImage can be used in a standalone test', () async {
    final provider = MemoryImage(kTransparentImage);
    await precacheTestImage(provider);
    expect(imageCache.containsKey(provider), isTrue);
    imageCache.clear();
  });

  testWidgets('precacheTestImage synchronously loads image into ImageCache for first frame', (
    WidgetTester tester,
  ) async {
    addTearDown(imageCache.clear);
    final provider = MemoryImage(kTransparentImage);
    await precacheTestImage(provider);

    bool? wasSynchronouslyLoaded;
    await tester.pumpWidget(
      Image(
        image: provider,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool synchronouslyLoaded) {
          wasSynchronouslyLoaded = synchronouslyLoaded;
          return child;
        },
      ),
    );

    expect(wasSynchronouslyLoaded, isTrue);
  });

  testWidgets('precacheTestImage reports errors to onError handler', (WidgetTester tester) async {
    final errorProvider = _FailingImageProvider();
    Object? caughtError;
    StackTrace? caughtStackTrace;

    await precacheTestImage(
      errorProvider,
      onError: (Object error, StackTrace? stackTrace) {
        caughtError = error;
        caughtStackTrace = stackTrace;
      },
    );

    expect(caughtError, isA<StateError>());
    expect(caughtStackTrace, isNotNull);
  });

  testWidgets('precacheTestImage throws if onError is not provided and load fails', (
    WidgetTester tester,
  ) async {
    final errorProvider = _FailingImageProvider();

    await expectLater(() => precacheTestImage(errorProvider), throwsA(isA<StateError>()));
  });
}

class _FailingImageProvider extends ImageProvider<Object> {
  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    return Future<Object>.value(this);
  }

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('Failed to load test image')),
    );
  }
}
