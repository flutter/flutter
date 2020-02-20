// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

const Color red = Color(0xFFAA0000);
const Color green = Color(0xFF00AA00);

const int greenRedColorBlend = 0xFF3131DB;
const int greenRedColorBlendInverted = 0xFFCECE24;
const int greenGreyscaled = 0xFF7A7A7A;
const int greenInvertedGreyscaled = 0xFF858585;

const int greenLinearToSrgbGamma = 0xFF00D500;
const int greenLinearToSrgbGammaInverted = 0xFFFF2AFF;

const int greenSrgbToLinearGamma = 0xFF006700;
const int greenSrgbToLinearGammaInverted = 0xFFFF98FF;

const List<double> greyscaleColorMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0,      0,      0,      1, 0, //
];

void main() {
  Future<Uint32List> getBytesForPaint(Paint paint, {int width = 1, int height = 1}) async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    recorderCanvas.drawPaint(paint);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(width, height);
    final ByteData bytes = await image.toByteData();

    expect(bytes.lengthInBytes, width * height * 4);
    return bytes.buffer.asUint32List();
  }

  test('ColorFilter - nulls', () async {
    final Paint paint = Paint()..colorFilter = const ColorFilter.mode(null, null);
    expect(paint.colorFilter, null);

    paint.colorFilter = const ColorFilter.matrix(null);
    expect(paint.colorFilter, null);
  });

  test('ColorFilter - mode', () async {
    final Paint paint = Paint()
      ..color = green
      ..colorFilter = const ColorFilter.mode(red, BlendMode.color);

    Uint32List bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenRedColorBlend);

    paint.invertColors = true;
    bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenRedColorBlendInverted);
  });

  test('ColorFilter - matrix', () async {
    final Paint paint = Paint()
      ..color = green
      ..colorFilter = const ColorFilter.matrix(greyscaleColorMatrix);

    Uint32List bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenGreyscaled);

    paint.invertColors = true;
    bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenInvertedGreyscaled);
  });

  test('ColorFilter - linearToSrgbGamma', () async {
    final Paint paint = Paint()
      ..color = green
      ..colorFilter = const ColorFilter.linearToSrgbGamma();

    Uint32List bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenLinearToSrgbGamma);

    paint.invertColors = true;
    bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenLinearToSrgbGammaInverted);
  });

  test('ColorFilter - srgbToLinearGamma', () async {
    final Paint paint = Paint()
      ..color = green
      ..colorFilter = const ColorFilter.srgbToLinearGamma();

    Uint32List bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenSrgbToLinearGamma);

    paint.invertColors = true;
    bytes = await getBytesForPaint(paint);
    expect(bytes[0], greenSrgbToLinearGammaInverted);
  });

}
