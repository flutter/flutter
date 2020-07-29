// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const int _kWidth = 10;
const int _kRadius = 2;

const Color _kBlack = Color.fromRGBO(0, 0, 0, 1.0);
const Color _kGreen = Color.fromRGBO(0, 255, 0, 1.0);

void main() {
  group('Image.toByteData', () {
    group('RGBA format', () {
      test('works with simple image', () async {
        final Image image = await Square4x4Image.image;
        final ByteData data = await image.toByteData();
        expect(Uint8List.view(data.buffer), Square4x4Image.bytes);
      });

      test('converts grayscale images', () async {
        final Image image = await GrayscaleImage.load();
        final ByteData data = await image.toByteData();
        final Uint8List bytes = data.buffer.asUint8List();
        expect(bytes, hasLength(16));
        expect(bytes, GrayscaleImage.bytesAsRgba);
      });
    });

    group('Unmodified format', () {
      test('works with simple image', () async {
        final Image image = await Square4x4Image.image;
        final ByteData data = await image.toByteData(format: ImageByteFormat.rawUnmodified);
        expect(Uint8List.view(data.buffer), Square4x4Image.bytes);
      });

      test('works with grayscale images', () async {
        final Image image = await GrayscaleImage.load();
        final ByteData data = await image.toByteData(format: ImageByteFormat.rawUnmodified);
        final Uint8List bytes = data.buffer.asUint8List();
        expect(bytes, hasLength(4));
        expect(bytes, GrayscaleImage.bytesUnmodified);
      });
    });

    group('PNG format', () {
      test('works with simple image', () async {
        final Image image = await Square4x4Image.image;
        final ByteData data = await image.toByteData(format: ImageByteFormat.png);
        final List<int> expected = await readFile('square.png');
        expect(Uint8List.view(data.buffer), expected);
      });
    });
  });
}

class Square4x4Image {
  Square4x4Image._();

  static Future<Image> get image async {
    final double width = _kWidth.toDouble();
    final double radius = _kRadius.toDouble();
    final double innerWidth = (_kWidth - 2 * _kRadius).toDouble();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas =
        Canvas(recorder, Rect.fromLTWH(0.0, 0.0, width, width));

    final Paint black = Paint()
      ..strokeWidth = 1.0
      ..color = _kBlack;
    final Paint green = Paint()
      ..strokeWidth = 1.0
      ..color = _kGreen;

    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, width, width), black);
    canvas.drawRect(
        Rect.fromLTWH(radius, radius, innerWidth, innerWidth), green);
    return await recorder.endRecording().toImage(_kWidth, _kWidth);
  }

  static List<int> get bytes {
    const int bytesPerChannel = 4;
    final List<int> result = List<int>(_kWidth * _kWidth * bytesPerChannel);

    void fillWithColor(Color color, int min, int max) {
      for (int i = min; i < max; i++) {
        for (int j = min; j < max; j++) {
          final int offset = i * bytesPerChannel + j * _kWidth * bytesPerChannel;
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
  GrayscaleImage._();

  static Future<Image> load() async {
    final Uint8List bytes = await readFile('2x2.png');
    final Completer<Image> completer = Completer<Image>();
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

Future<Uint8List> readFile(String fileName) async {
  final File file = File(path.join('flutter', 'testing', 'resources', fileName));
  return await file.readAsBytes();
}
