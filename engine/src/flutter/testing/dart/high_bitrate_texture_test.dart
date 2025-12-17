// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

import 'goldens.dart';
import 'impeller_enabled.dart';

void main() async {
  final ImageComparer comparer = await ImageComparer.create();

  test('decodeImageFromPixels with RGBA Float32', () async {
    const dimension = 1024;
    final Image image = await _createRGBA32FloatImage(dimension, dimension);
    final Image shaderImage = await _drawIntoImage(image);

    final ByteData data = (await shaderImage.toByteData())!;

    // Check top left is Red
    var offset = 0;
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

    await comparer.addGoldenImage(shaderImage, 'decode_image_from_pixels_rgba_float32.png');
    image.dispose();
  });

  test('decodeImageFromPixels with R Float32', () async {
    if (!impellerEnabled) {
      print('Skipped for Skia');
      return;
    }
    const dimension = 1024;
    final Image image = await _createR32FloatImage(dimension, dimension);
    final Image shaderImage = await _drawIntoImage(image);

    final ByteData data = (await shaderImage.toByteData())!;

    // Check top left is Red
    var offset = 0;
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

    image.dispose();
  });

  test('Picture.toImageSync with rgbaFloat32', () async {
    const dimension = 1024;
    final Image image = await _drawWithCircleShader(
      dimension,
      dimension,
      TargetPixelFormat.rgbaFloat32,
    );
    final Image shaderImage = await _drawWithShader(image);

    final ByteData data = (await shaderImage.toByteData())!;

    // Check top left is Black (outside circle, d > 0 -> vec3(0.0))
    var offset = 0;
    expect(data.getUint8(offset), 0, reason: 'Top left Red');
    expect(data.getUint8(offset + 1), 0, reason: 'Top left Green');
    expect(data.getUint8(offset + 2), 0, reason: 'Top left Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Top left Alpha');

    // Check center is White (inside circle, d <= 0 -> vec3(1.0))
    offset = ((dimension ~/ 2) * dimension + (dimension ~/ 2)) * 4;
    expect(data.getUint8(offset), 255, reason: 'Center Red');
    expect(data.getUint8(offset + 1), 255, reason: 'Center Green');
    expect(data.getUint8(offset + 2), 255, reason: 'Center Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Center Alpha');

    await comparer.addGoldenImage(shaderImage, 'picture_to_image_rgba_float32.png');
    image.dispose();
  });

  test('Picture.toImageSync with rFloat32', () async {
    if (!impellerEnabled) {
      print('Skipped for Skia');
      return;
    }
    const dimension = 1024;
    final Image image = await _drawWithCircleShader(
      dimension,
      dimension,
      TargetPixelFormat.rFloat32,
    );
    final Image shaderImage = await _drawWithShader(image);

    final ByteData data = (await shaderImage.toByteData())!;

    // Check top left is Black
    var offset = 0;
    expect(data.getUint8(offset), 0, reason: 'Top left Red');
    expect(data.getUint8(offset + 1), 0, reason: 'Top left Green');
    expect(data.getUint8(offset + 2), 0, reason: 'Top left Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Top left Alpha');

    // Check center is White
    offset = ((dimension ~/ 2) * dimension + (dimension ~/ 2)) * 4;
    expect(data.getUint8(offset), 255, reason: 'Center Red');
    expect(data.getUint8(offset + 1), 255, reason: 'Center Green');
    expect(data.getUint8(offset + 2), 255, reason: 'Center Blue');
    expect(data.getUint8(offset + 3), 255, reason: 'Center Alpha');

    image.dispose();
  });
}

Future<Image> _drawWithShader(Image image) async {
  final FragmentProgram program = await FragmentProgram.fromAsset('sdf.frag.iplr');
  final FragmentShader shader = program.fragmentShader();
  shader.setFloat(0, image.width.toDouble());
  shader.setFloat(1, image.height.toDouble());
  shader.setImageSampler(0, image);

  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Paint()..shader = shader,
  );
  final Picture picture = recorder.endRecording();
  return picture.toImageSync(image.width, image.height);
}

Future<Image> _drawWithCircleShader(int width, int height, TargetPixelFormat format) async {
  final FragmentProgram program = await FragmentProgram.fromAsset('circle_sdf.frag.iplr');
  final FragmentShader shader = program.fragmentShader();
  shader.setFloat(0, width.toDouble());
  shader.setFloat(1, height.toDouble());

  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..shader = shader,
  );
  final Picture picture = recorder.endRecording();
  return picture.toImageSync(width, height, targetFormat: format);
}

Future<Image> _drawIntoImage(Image image) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(image, Offset.zero, Paint());
  final Picture picture = recorder.endRecording();
  return picture.toImage(image.width, image.height);
}

/// Draws an ellipsis with radii half the dimensions in the rgbaFloat32 pixel
/// format.
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

/// Draws an ellipsis with radii half the dimensions in the rFloat32 pixel
/// format.
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
