// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('Picture construction invokes onCreate once', () async {
    var onCreateInvokedCount = 0;
    Picture? createdPicture;
    Picture.onCreate = (Picture picture) {
      onCreateInvokedCount++;
      createdPicture = picture;
    };

    final Picture picture1 = _createPicture();

    expect(onCreateInvokedCount, 1);
    expect(createdPicture, picture1);

    final Picture picture2 = _createPicture();

    expect(onCreateInvokedCount, 2);
    expect(createdPicture, picture2);
    Picture.onCreate = null;
  });

  test('approximateBytesUsed is available for onCreate', () async {
    var pictureSize = -1;

    Picture.onCreate = (Picture picture) => pictureSize = picture.approximateBytesUsed;

    _createPicture();

    expect(pictureSize >= 0, true);
    Picture.onCreate = null;
  });

  test('dispose() invokes onDispose once', () async {
    var onDisposeInvokedCount = 0;
    Picture? disposedPicture;
    Picture.onDispose = (Picture picture) {
      onDisposeInvokedCount++;
      disposedPicture = picture;
    };

    final Picture picture1 = _createPicture()..dispose();

    expect(onDisposeInvokedCount, 1);
    expect(disposedPicture, picture1);

    final Picture picture2 = _createPicture()..dispose();

    expect(onDisposeInvokedCount, 2);
    expect(disposedPicture, picture2);

    Picture.onDispose = null;
  });

  test('toImage throws for dimensions exceeding hard limit', () async {
    final picture = _createPicture();

    // Test exceeding hard limit (8192 pixels)
    expect(
      () => picture.toImage(8193, 100),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('exceed the maximum supported size'),
      )),
    );

    expect(
      () => picture.toImage(100, 8193),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('exceed the maximum supported size'),
      )),
    );

    picture.dispose();
  });

  test('toImageSync throws for dimensions exceeding hard limit', () async {
    final picture = _createPicture();

    // Test exceeding hard limit (8192 pixels)
    expect(
      () => picture.toImageSync(8193, 100),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('exceed the maximum supported size'),
      )),
    );

    expect(
      () => picture.toImageSync(100, 8193),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('exceed the maximum supported size'),
      )),
    );

    picture.dispose();
  });

  test('toImage succeeds for normal dimensions', () async {
    final picture = _createPicture();

    // Should not throw for normal dimensions
    final image = await picture.toImage(100, 100);
    expect(image.width, 100);
    expect(image.height, 100);

    image.dispose();
    picture.dispose();
  });

  test('toImageSync succeeds for normal dimensions', () async {
    final picture = _createPicture();

    // Should not throw for normal dimensions
    final image = picture.toImageSync(100, 100);
    expect(image.width, 100);
    expect(image.height, 100);

    image.dispose();
    picture.dispose();
  });
}

Picture _createPicture() {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
