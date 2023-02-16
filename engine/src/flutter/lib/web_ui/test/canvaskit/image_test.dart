// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/canvaskit/image.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest();

  test('toImage succeeds', () async {
    final ui.Image image = await _createImage();
    expect(image.runtimeType.toString(), equals('CkImage'));
    image.dispose();
  });

  test('Image constructor invokes onCreate once', () async {
    int onCreateInvokedCount = 0;
    ui.Image? createdImage;
    ui.Image.onCreate = (ui.Image image) {
      onCreateInvokedCount++;
      createdImage = image;
    };

    final ui.Image  image1 = await _createImage();

    expect(onCreateInvokedCount, 1);
    expect(createdImage, image1);

    final ui.Image image2 = await _createImage();

    expect(onCreateInvokedCount, 2);
    expect(createdImage, image2);

    ui.Image.onCreate = null;
  });

  test('dispose() invokes onDispose once', () async {
    int onDisposeInvokedCount = 0;
    ui.Image? disposedImage;
    ui.Image.onDispose = (ui.Image image) {
      onDisposeInvokedCount++;
      disposedImage = image;
    };

    final ui.Image image1 = await _createImage()..dispose();

    expect(onDisposeInvokedCount, 1);
    expect(disposedImage, image1);

    final ui.Image image2 = await _createImage()..dispose();

    expect(onDisposeInvokedCount, 2);
    expect(disposedImage, image2);

    ui.Image.onDispose = null;
  });

  test('fetchImage fetches image in chunks', () async {
    final List<int> cumulativeBytesLoadedInvocations = <int>[];
    final List<int> expectedTotalBytesInvocations = <int>[];
    final Uint8List result = await fetchImage('/long_test_payload?length=100000&chunk=1000', (int cumulativeBytesLoaded, int expectedTotalBytes) {
      cumulativeBytesLoadedInvocations.add(cumulativeBytesLoaded);
      expectedTotalBytesInvocations.add(expectedTotalBytes);
    });

    // Check that image payload was chunked.
    expect(cumulativeBytesLoadedInvocations, hasLength(greaterThan(1)));

    // Check that reported total byte count is the same across all invocations.
    for (final int expectedTotalBytes in expectedTotalBytesInvocations) {
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
    expect(
      result,
      List<int>.generate(100000, (int i) => i & 0xFF),
    );
  });
}

Future<ui.Image> _createImage() => _createPicture().toImage(10, 10);

ui.Picture _createPicture() {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  const ui.Rect rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
