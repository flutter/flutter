// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

const Color green = Color(0xFF00AA00);

const int greenCenterBlurred = 0x1C001300;
const int greenSideBlurred = 0x15000E00;
const int greenCornerBlurred = 0x10000A00;

const int greenCenterScaled = 0xFF00AA00;
const int greenSideScaled = 0x80005500;
const int greenCornerScaled = 0x40002B00;

void main() {
  Future<Uint32List> getBytesForPaint(Paint paint, {int width = 3, int height = 3}) async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    recorderCanvas.drawRect(const Rect.fromLTRB(1.0, 1.0, 2.0, 2.0), paint);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(width, height);
    final ByteData bytes = await image.toByteData();

    expect(bytes.lengthInBytes, equals(width * height * 4));
    return bytes.buffer.asUint32List();
  }

  ImageFilter makeBlur(double sigmaX, double sigmaY) =>
    ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);

  ImageFilter makeScale(double scX, double scY,
                        [double trX = 0.0, double trY = 0.0,
                         FilterQuality quality = FilterQuality.low]) {
    trX *= 1.0 - scX;
    trY *= 1.0 - scY;
    return ImageFilter.matrix(Float64List.fromList(<double>[
      scX, 0.0, 0.0, 0.0,
      0.0, scY, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      trX, trY, 0.0, 1.0,
    ]), filterQuality: quality);
  }

  List<ImageFilter> makeList() {
    return <ImageFilter>[
      makeBlur(10.0, 10.0),
      makeBlur(10.0, 20.0),
      makeBlur(20.0, 20.0),
      makeScale(10.0, 10.0),
      makeScale(10.0, 20.0),
      makeScale(20.0, 10.0),
      makeScale(10.0, 10.0, 1.0, 1.0),
      makeScale(10.0, 10.0, 0.0, 0.0, FilterQuality.medium),
      makeScale(10.0, 10.0, 0.0, 0.0, FilterQuality.high),
      makeScale(10.0, 10.0, 0.0, 0.0, FilterQuality.none),
    ];
  }

  void checkEquality(List<ImageFilter> a, List<ImageFilter> b) {
    for (int i = 0; i < a.length; i++) {
      for(int j = 0; j < a.length; j++) {
        if (i == j) {
          expect(a[i], equals(b[j]));
          expect(a[i].hashCode, equals(b[j].hashCode));
          expect(a[i].toString(), equals(b[j].toString()));
        } else {
          expect(a[i], isNot(b[j]));
          // No expectations on hashCode if objects are not equal
          expect(a[i].toString(), isNot(b[j].toString()));
        }
      }
    }
  }

  test('ImageFilter - equals', () async {
    final List<ImageFilter> A = makeList();
    final List<ImageFilter> B = makeList();
    checkEquality(A, A);
    checkEquality(A, B);
    checkEquality(B, B);
  });

  test('ImageFilter - nulls', () async {
    final Paint paint = Paint()..imageFilter = ImageFilter.blur(sigmaX: null, sigmaY: null);
    expect(paint.imageFilter, equals(ImageFilter.blur()));

    expect(() => ImageFilter.matrix(null), throwsNoSuchMethodError);
  });

  void checkBytes(Uint32List bytes, int center, int side, int corner) {
    expect(bytes[0], equals(corner));
    expect(bytes[1], equals(side));
    expect(bytes[2], equals(corner));

    expect(bytes[3], equals(side));
    expect(bytes[4], equals(center));
    expect(bytes[5], equals(side));

    expect(bytes[6], equals(corner));
    expect(bytes[7], equals(side));
    expect(bytes[8], equals(corner));
  }

  test('ImageFilter - blur', () async {
    final Paint paint = Paint()
      ..color = green
      ..imageFilter = makeBlur(1.0, 1.0);

    final Uint32List bytes = await getBytesForPaint(paint);
    checkBytes(bytes, greenCenterBlurred, greenSideBlurred, greenCornerBlurred);
  });

  test('ImageFilter - matrix', () async {
    final Paint paint = Paint()
      ..color = green
      ..imageFilter = makeScale(2.0, 2.0, 1.5, 1.5);

    final Uint32List bytes = await getBytesForPaint(paint);
    checkBytes(bytes, greenCenterScaled, greenSideScaled, greenCornerScaled);
  });
}
