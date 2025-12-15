// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

import 'goldens.dart';
import 'impeller_enabled.dart';

void main() async {
  final ImageComparer comparer = await ImageComparer.create();

  test('FragmentShader draws RGBA Float32 texture', () async {
    const int dimension = 1024;
    final Image image = await _createRGBA32FloatImage(dimension, dimension);
    final Image shaderImage = await _drawIntoImage(image);

    final ByteData data = (await shaderImage.toByteData())!;

    // Check top left is Red
    int offset = 0;
    expect(data.getUint8(offset), 255, reason: 'Top left Red');
    expect(data.getUint8(offset + 1), 0, reason: 'Top left Green');
    expect(data.getUint8(offset + 2), 0, reason: 'Top left Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Top left Alpha');

    // Check center is Black
    offset = ((dimension ~/ 2) * dimension + (dimension ~/ 2)) * 4;
    expect(data.getUint8(offset), 0, reason: 'Center Red');
    expect(data.getUint8(offset + 1), 0, reason: 'Center Green');
    expect(data.getUint8(offset + 2), 0, reason: 'Center Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Center Alpha');

    await comparer.addGoldenImage(shaderImage, 'fragment_shader_rgba_float32.png');
    image.dispose();
  });

  test('FragmentShader draws R Float32 texture', () async {
    if (!impellerEnabled) {
      print('Skipped for Skia');
      return;
    }
    const int dimension = 1024;
    final Image image = await _createR32FloatImage(dimension, dimension);
    final Image shaderImage = await _drawIntoImage(image);

    final ByteData data = (await shaderImage.toByteData())!;

    // Check top left is Red
    int offset = 0;
    expect(data.getUint8(offset), 255, reason: 'Top left Red');
    expect(data.getUint8(offset + 1), 0, reason: 'Top left Green');
    expect(data.getUint8(offset + 2), 0, reason: 'Top left Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Top left Alpha');

    // Check center is Black
    offset = ((dimension ~/ 2) * dimension + (dimension ~/ 2)) * 4;
    expect(data.getUint8(offset), 0, reason: 'Center Red');
    expect(data.getUint8(offset + 1), 0, reason: 'Center Green');
    expect(data.getUint8(offset + 2), 0, reason: 'Center Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Center Alpha');

    await comparer.addGoldenImage(shaderImage, 'fragment_shader_r_float32.png');
    image.dispose();
  });
}

Future<Image> _drawIntoImage(Image image) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(image, Offset.zero, Paint());
  final Picture picture = recorder.endRecording();
  return picture.toImage(image.width, image.height);
}

Future<Image> _createRGBA32FloatImage(int width, int height) async {
  final double radius = width / 4.0;
  final floats = List<double>.filled(width * height * 4, 0.0);
  for (var i = 0; i < height; ++i) {
    for (var j = 0; j < width; ++j) {
      double x = j.toDouble();
      double y = i.toDouble();
      x -= width / 2.0;
      y -= height / 2.0;
      final double length = math.sqrt(x * x + y * y);
      final int idx = i * width * 4 + j * 4;
      floats[idx + 0] = length - radius;
      floats[idx + 1] = 0.0;
      floats[idx + 2] = 0.0;
      floats[idx + 3] = 1.0;
    }
  }
  final floatList = Float32List.fromList(floats);
  final intList = Uint8List.view(floatList.buffer);
  final completer = Completer<Image>();
  decodeImageFromPixels(
    intList,
    width,
    height,
    PixelFormat.rgbaFloat32,
    targetFormat: TargetPixelFormat.rgbaFloat32,
    (Image image) {
      completer.complete(image);
    },
  );
  return completer.future;
}

Future<Image> _createR32FloatImage(int width, int height) async {
  final double radius = width / 4.0;
  final floats = List<double>.filled(width * height, 0.0);
  for (var i = 0; i < height; ++i) {
    for (var j = 0; j < width; ++j) {
      double x = j.toDouble();
      double y = i.toDouble();
      x -= width / 2.0;
      y -= height / 2.0;
      final double length = math.sqrt(x * x + y * y);
      final int idx = i * width + j;
      floats[idx] = length - radius;
    }
  }
  final floatList = Float32List.fromList(floats);
  final intList = Uint8List.view(floatList.buffer);
  final completer = Completer<Image>();
  decodeImageFromPixels(
    intList,
    width,
    height,
    PixelFormat.rFloat32,
    targetFormat: TargetPixelFormat.rFloat32,
    (Image image) {
      completer.complete(image);
    },
  );
  return completer.future;
}
