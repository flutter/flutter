// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_data.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest();

  tearDown(() {
    ui.Image.onCreate = null;
    ui.Image.onDispose = null;
  });

  test('toImage succeeds', () async {
    final ui.Image image = await _createImage();
    expect(image.runtimeType.toString(), equals('CkImage'));
    image.dispose();
  });

  test('fetchImage fetches image in chunks', () async {
    final cumulativeBytesLoadedInvocations = <int>[];
    final expectedTotalBytesInvocations = <int>[];
    final Uint8List result = await fetchImage('/long_test_payload?length=100000&chunk=1000', (
      int cumulativeBytesLoaded,
      int expectedTotalBytes,
    ) {
      cumulativeBytesLoadedInvocations.add(cumulativeBytesLoaded);
      expectedTotalBytesInvocations.add(expectedTotalBytes);
    });

    // Check that image payload was chunked.
    expect(cumulativeBytesLoadedInvocations, hasLength(greaterThan(1)));

    // Check that reported total byte count is the same across all invocations.
    for (final expectedTotalBytes in expectedTotalBytesInvocations) {
      expect(expectedTotalBytes, 100000);
    }

    // Check that cumulative byte count grows with each invocation.
    cumulativeBytesLoadedInvocations.reduce((int previous, int next) {
      expect(next, greaterThan(previous));
      return next;
    });

    // Check that the last cumulative byte count matches the total byte count.
    expect(cumulativeBytesLoadedInvocations.last, 100000);

    // Check the contents of the returned data.
    expect(result, List<int>.generate(100000, (int i) => i & 0xFF));
  });

  test('CkImage does not close image source too early', () async {
    final ImageSource imageSource = ImageBitmapImageSource(
      await createImageBitmap(createBlankDomImageData(4, 4)),
    );

    final SkImage skImage1 = canvasKit.MakeAnimatedImageFromEncoded(
      k4x4PngImage,
    )!.makeImageAtCurrentFrame();
    final image1 = CkImage(skImage1, imageSource: imageSource);

    final SkImage skImage2 = canvasKit.MakeAnimatedImageFromEncoded(
      k4x4PngImage,
    )!.makeImageAtCurrentFrame();
    final image2 = CkImage(skImage2, imageSource: imageSource);

    final CkImage image3 = image1.clone();

    expect(imageSource.debugIsClosed, isFalse);

    image1.dispose();
    expect(imageSource.debugIsClosed, isFalse);

    image2.dispose();
    expect(imageSource.debugIsClosed, isFalse);

    image3.dispose();
    expect(imageSource.debugIsClosed, isTrue);
  });
}

Future<ui.Image> _createImage() => _createPicture().toImage(10, 10);

ui.Picture _createPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
