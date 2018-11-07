// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const int _kWidth = 10;
const int _kRadius = 2;

const Color _kBlack = const Color.fromRGBO(0, 0, 0, 1.0);
const Color _kGreen = const Color.fromRGBO(0, 255, 0, 1.0);

void main() {
  group('Image.toByteData', () {
    group('RGBA format', () {
      test('works with simple image', () async {
        ByteData data = await Square4x4Image.image.toByteData();
        expect(new Uint8List.view(data.buffer), Square4x4Image.bytes);
      });

      test('converts grayscale images', () async {
        Image image = await GrayscaleImage.load();
        ByteData data = await image.toByteData();
        Uint8List bytes = data.buffer.asUint8List();
        expect(bytes, hasLength(16));
        expect(bytes, GrayscaleImage.bytesAsRgba);
      });
    });

    group('Unmodified format', () {
      test('works with simple image', () async {
        Image image = Square4x4Image.image;
        ByteData data = await image.toByteData(format: ImageByteFormat.rawUnmodified);
        expect(new Uint8List.view(data.buffer), Square4x4Image.bytes);
      });

      test('works with grayscale images', () async {
        Image image = await GrayscaleImage.load();
        ByteData data = await image.toByteData(format: ImageByteFormat.rawUnmodified);
        Uint8List bytes = data.buffer.asUint8List();
        expect(bytes, hasLength(4));
        expect(bytes, GrayscaleImage.bytesUnmodified);
      });
    });

    group('PNG format', () {
      test('works with simple image', () async {
        Image image = Square4x4Image.image;
        ByteData data = await image.toByteData(format: ImageByteFormat.png);
        List<int> expected = await readFile('square.png');
        expect(new Uint8List.view(data.buffer), expected);
      });
    });
  });
}

class Square4x4Image {
  static Image get image {
    double width = _kWidth.toDouble();
    double radius = _kRadius.toDouble();
    double innerWidth = (_kWidth - 2 * _kRadius).toDouble();

    PictureRecorder recorder = new PictureRecorder();
    Canvas canvas =
        new Canvas(recorder, new Rect.fromLTWH(0.0, 0.0, width, width));

    Paint black = new Paint()
      ..strokeWidth = 1.0
      ..color = _kBlack;
    Paint green = new Paint()
      ..strokeWidth = 1.0
      ..color = _kGreen;

    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, width, width), black);
    canvas.drawRect(
        new Rect.fromLTWH(radius, radius, innerWidth, innerWidth), green);
    return recorder.endRecording().toImage(_kWidth, _kWidth);
  }

  static List<int> get bytes {
    int bytesPerChannel = 4;
    List<int> result = new List<int>(_kWidth * _kWidth * bytesPerChannel);

    fillWithColor(Color color, int min, int max) {
      for (int i = min; i < max; i++) {
        for (int j = min; j < max; j++) {
          int offset = i * bytesPerChannel + j * _kWidth * bytesPerChannel;
          result[offset] = color.red;
          result[offset + 1] = color.green;
          result[offset + 2] = color.blue;
          result[offset + 3] = color.alpha;
        }
      }
    }

    fillWithColor(_kBlack, 0, _kWidth);
    fillWithColor(_kGreen, _kRadius, _kWidth - _kRadius);

    return result;
  }
}

class GrayscaleImage {
  static Future<Image> load() async {
    Uint8List bytes = await readFile('4x4.png');
    Completer<Image> completer = new Completer<Image>();
    decodeImageFromList(bytes, (Image image) => completer.complete(image));
    return await completer.future;
  }

  static List<int> get bytesAsRgba {
    return <int>[
      255, 255, 255, 255,
      127, 127, 127, 255,
      127, 127, 127, 255,
      0, 0, 0, 255,
    ];
  }

  static List<int> get bytesUnmodified => <int>[255, 127, 127, 0];
}

Future<Uint8List> readFile(fileName) async {
  final file = new File(path.join('flutter', 'testing', 'resources', fileName));
  return await file.readAsBytes();
}
