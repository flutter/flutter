// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  final Image testImage = createSquareTestImage();

  test('Encode with default arguments', () async {
    ByteData data = await testImage.toByteData();
    List<int> expected = readFile('square-80.jpg');
    expect(new Uint8List.view(data.buffer), expected);
  });

  test('Encode JPEG', () async {
    ByteData data = await testImage.toByteData(
        format: new EncodingFormat.jpeg(quality: 80));
    List<int> expected = readFile('square-80.jpg');
    expect(new Uint8List.view(data.buffer), expected);
  });

  test('Encode PNG', () async {
    ByteData data =
        await testImage.toByteData(format: new EncodingFormat.png());
    List<int> expected = readFile('square.png');
    expect(new Uint8List.view(data.buffer), expected);
  });

  test('Encode WEBP', () async {
    ByteData data = await testImage.toByteData(
        format: new EncodingFormat.webp(quality: 80));
    List<int> expected = readFile('square-80.webp');
    expect(new Uint8List.view(data.buffer), expected);
  });
}

Image createSquareTestImage() {
  PictureRecorder recorder = new PictureRecorder();
  Canvas canvas = new Canvas(recorder, new Rect.fromLTWH(0.0, 0.0, 10.0, 10.0));

  Paint black = new Paint()
    ..strokeWidth = 1.0
    ..color = const Color.fromRGBO(0, 0, 0, 1.0);
  Paint green = new Paint()
    ..strokeWidth = 1.0
    ..color = const Color.fromRGBO(0, 255, 0, 1.0);

  canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, 10.0, 10.0), black);
  canvas.drawRect(new Rect.fromLTWH(2.0, 2.0, 6.0, 6.0), green);
  return recorder.endRecording().toImage(10, 10);
}

List<int> readFile(fileName) {
  final file = new File(path.join('flutter', 'testing', 'resources', fileName));
  return file.readAsBytesSync();
}
