// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

class TestImage implements ui.Image {
  TestImage({ this.width, this.height });

  @override
  final int width;

  @override
  final int height;

  @override
  void dispose() { }

  @override
  Future<ByteData> toByteData({ ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba }) async {
    throw UnsupportedError('Cannot encode test image');
  }
}

class TestCanvas implements Canvas {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  setUp(() {
    debugFlushLastFrameImageSizeInfo();
  });

  test('Cover and align', () {
    final TestImage image = TestImage(width: 300, height: 300);
    final TestCanvas canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      fit: BoxFit.cover,
      alignment: const Alignment(-1.0, 0.0),
    );

    final Invocation command = canvas.invocations.firstWhere((Invocation invocation) {
      return invocation.memberName == #drawImageRect;
    });

    expect(command, isNotNull);
    expect(command.positionalArguments[0], equals(image));
    expect(command.positionalArguments[1], equals(const Rect.fromLTWH(0.0, 75.0, 300.0, 150.0)));
    expect(command.positionalArguments[2], equals(const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0)));
  });

  testWidgets('Reports Image painting', (WidgetTester tester) async {
    ImageSizeInfo imageSizeInfo;
    int count = 0;
    debugOnPaintImage = (ImageSizeInfo info) {
      count += 1;
      imageSizeInfo = info;
    };

    final TestImage image = TestImage(width: 300, height: 300);
    final TestCanvas canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      debugImageLabel: 'test.png',
    );

    expect(count, 1);
    expect(imageSizeInfo, isNotNull);
    expect(imageSizeInfo.source, 'test.png');
    expect(imageSizeInfo.imageSize, const Size(300, 300));
    expect(imageSizeInfo.displaySize, const Size(200, 100));

    // Make sure that we don't report an identical image size info if we
    // redraw in the next frame.
    tester.binding.scheduleForcedFrame();
    await tester.pump();

    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      debugImageLabel: 'test.png',
    );

    expect(count, 1);

    debugOnPaintImage = null;
  });

  testWidgets('Reports Image painting - change per frame', (WidgetTester tester) async {
    ImageSizeInfo imageSizeInfo;
    int count = 0;
    debugOnPaintImage = (ImageSizeInfo info) {
      count += 1;
      imageSizeInfo = info;
    };

    final TestImage image = TestImage(width: 300, height: 300);
    final TestCanvas canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      debugImageLabel: 'test.png',
    );

    expect(count, 1);
    expect(imageSizeInfo, isNotNull);
    expect(imageSizeInfo.source, 'test.png');
    expect(imageSizeInfo.imageSize, const Size(300, 300));
    expect(imageSizeInfo.displaySize, const Size(200, 100));

    // Make sure that we don't report an identical image size info if we
    // redraw in the next frame.
    tester.binding.scheduleForcedFrame();
    await tester.pump();

    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 150.0),
      image: image,
      debugImageLabel: 'test.png',
    );

    expect(count, 2);
    expect(imageSizeInfo, isNotNull);
    expect(imageSizeInfo.source, 'test.png');
    expect(imageSizeInfo.imageSize, const Size(300, 300));
    expect(imageSizeInfo.displaySize, const Size(200, 150));

    debugOnPaintImage = null;
  });

  testWidgets('Reports Image painting - no debug label', (WidgetTester tester) async {
    ImageSizeInfo imageSizeInfo;
    int count = 0;
    debugOnPaintImage = (ImageSizeInfo info) {
      count += 1;
      imageSizeInfo = info;
    };

    final TestImage image = TestImage(width: 300, height: 200);
    final TestCanvas canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
    );

    expect(count, 1);
    expect(imageSizeInfo, isNotNull);
    expect(imageSizeInfo.source, '<Unknown Image(300×200)>');
    expect(imageSizeInfo.imageSize, const Size(300, 200));
    expect(imageSizeInfo.displaySize, const Size(200, 100));

    debugOnPaintImage = null;
  });

  // See also the DecorationImage tests in: decoration_test.dart
}
