// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../flutter_test_alternative.dart';

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

  test('Reports unnecessary memory usage', () {
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterErrorDetails lastErrorDetails;
    FlutterError.onError = (FlutterErrorDetails details) {
      expect(lastErrorDetails, null);
      lastErrorDetails = details;
    };
    debugImageOverheadAllowedInKilobytes = 0;

    final TestImage image = TestImage(width: 300, height: 300);
    final TestCanvas canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      imageTag: 'test.png',
    );
    expect(lastErrorDetails, isNotNull);
    expect(
      lastErrorDetails.exception,
      'The image test.png (300×300) exceeds its paint bounds (200×100), adding an overhead of 364kb.\n\n'
      'If this image is never displayed at its full resolution, consider using a ResizeImage ImageProvider or setting the cacheWidth/cacheHeight parameters on the Image widget.',
    );

    FlutterError.onError = oldHandler;
    debugImageOverheadAllowedInKilobytes = null;
  });

  test('Passes fair memory usage', () {
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterErrorDetails lastErrorDetails;
    FlutterError.onError = (FlutterErrorDetails details) {
      fail('Expected no FlutterError to be thrown.');
    };
    debugImageOverheadAllowedInKilobytes = 0;

    TestImage image = TestImage(width: 200, height: 100);
    TestCanvas canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      imageTag: 'test.png',
    );
    expect(lastErrorDetails, null);

    debugImageOverheadAllowedInKilobytes = 100;

    image = TestImage(width: 220, height: 110);
    canvas = TestCanvas();
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(50.0, 75.0, 200.0, 100.0),
      image: image,
      imageTag: 'test.png',
    );
    expect(lastErrorDetails, null);

    FlutterError.onError = oldHandler;
    debugImageOverheadAllowedInKilobytes = null;
  });
  // See also the DecorationImage tests in: decoration_test.dart
}
