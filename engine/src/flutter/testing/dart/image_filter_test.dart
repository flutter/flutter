// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

const Color red = Color(0xFFAA0000);
const Color green = Color(0xFF00AA00);

const int greenCenterBlurred = 0x1C001300;
const int greenSideBlurred = 0x15000E00;
const int greenCornerBlurred = 0x10000A00;

const int greenCenterScaled = 0xFF00AA00;
const int greenSideScaled = 0x80005500;
const int greenCornerScaled = 0x40002B00;

const List<double> grayscaleColorMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
];

const List<double> identityColorMatrix = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

const List<double> constValueColorMatrix = <double>[
  0, 0, 0, 0, 2,
  0, 0, 0, 0, 2,
  0, 0, 0, 0, 2,
  0, 0, 0, 0, 255,
];

const List<double> halvesBrightnessColorMatrix = <double>[
  0.5, 0,   0,   0, 0,
  0,   0.5, 0,   0, 0,
  0,   0,   0.5, 0, 0,
  0,   0,   0,   1, 0,
];

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

  Future<Uint32List> getBytesForColorPaint(Paint paint, {int width = 1, int height = 1}) async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    recorderCanvas.drawPaint(paint);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(width, height);
    final ByteData bytes = await image.toByteData();

    expect(bytes.lengthInBytes, width * height * 4);
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

  List<ColorFilter> colorFilters() {
    // Create new color filter instances on each invocation.
    return <ColorFilter> [                        // ignore: prefer_const_constructors
      ColorFilter.mode(null, null),               // ignore: prefer_const_constructors
      ColorFilter.mode(green, BlendMode.color),   // ignore: prefer_const_constructors
      ColorFilter.mode(red, BlendMode.color),     // ignore: prefer_const_constructors
      ColorFilter.mode(red, BlendMode.screen),    // ignore: prefer_const_constructors
      ColorFilter.matrix(null),                   // ignore: prefer_const_constructors
      ColorFilter.matrix(grayscaleColorMatrix),   // ignore: prefer_const_constructors
      ColorFilter.linearToSrgbGamma(),            // ignore: prefer_const_constructors
      ColorFilter.srgbToLinearGamma(),            // ignore: prefer_const_constructors
    ];
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
      ...colorFilters(),
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

  List<ImageFilter> composed(List<ImageFilter> a, List<ImageFilter> b) {
    return <ImageFilter>[for (final ImageFilter x in a) for (final ImageFilter y in b) ImageFilter.compose(outer: x, inner: y)];
  }

  test('ImageFilter - equals', () async {
    final List<ImageFilter> A = makeList();
    final List<ImageFilter> B = makeList();
    checkEquality(A, A);
    checkEquality(A, B);
    checkEquality(B, B);
    checkEquality(composed(A, A), composed(A, A));
    checkEquality(composed(A, B), composed(B, A));
    checkEquality(composed(B, B), composed(B, B));
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

  test('ImageFilter - matrix: copies the list', () async {
    final Float64List matrix = Float64List.fromList(<double>[
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
    ]);

    final ImageFilter filter = ImageFilter.matrix(matrix);
    final String originalDescription = filter.toString();

    // Modify the matrix.
    matrix[0] = 12345;
    expect(filter.toString(), contains('[1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]'));
    expect(filter.toString(), originalDescription);
  });

  test('ImageFilter - null color filters do not throw', () {
    dynamic error;
    final Paint paint = Paint();
    try {
      paint
        ..color = green
        ..imageFilter = const ColorFilter.mode(null, null);
    } catch (e) {
      error = e;
    }

    expect(error, isNull);
  });

  test('ImageFilter - from color filters', () async {
    final Paint paint = Paint()
      ..color = green
      ..imageFilter = const ColorFilter.matrix(constValueColorMatrix);

    final Uint32List bytes = await getBytesForColorPaint(paint);
    expect(bytes[0], 0xFF020202);
  });

  test('ImageFilter - null filter composition', () async {
    const ImageFilter nullFilter = ColorFilter.mode(null, null);
    const ImageFilter identityFilter = ColorFilter.matrix(identityColorMatrix);

    // Verify that null filter == identity.
    Future<void> verifyAgainst(ImageFilter filter) async {
      final ImageFilter comp0 = ImageFilter.compose(outer: filter, inner: identityFilter);
      final ImageFilter comp1 = ImageFilter.compose(outer: filter, inner: nullFilter);
      final ImageFilter comp2 = ImageFilter.compose(outer: nullFilter, inner: filter);
      final Paint paint = Paint()..color = green;

      paint.imageFilter = comp0;
      final Uint32List bytes = await getBytesForColorPaint(paint);

      paint.imageFilter = comp1;
      expect(bytes, equals(await getBytesForColorPaint(paint)));

      paint.imageFilter = comp2;
      expect(bytes, equals(await getBytesForColorPaint(paint)));
    }

    makeList().forEach(verifyAgainst);
  });

  test('ImageFilter - color filter composition', () async {
    final ImageFilter compOrder1 = ImageFilter.compose(
      outer: const ColorFilter.matrix(halvesBrightnessColorMatrix),
      inner: const ColorFilter.matrix(constValueColorMatrix),
    );

    final ImageFilter compOrder2 = ImageFilter.compose(
      outer: const ColorFilter.matrix(constValueColorMatrix),
      inner: const ColorFilter.matrix(halvesBrightnessColorMatrix),
    );

    final Paint paint = Paint()
      ..color = green
      ..imageFilter = compOrder1;

    Uint32List bytes = await getBytesForColorPaint(paint);
    expect(bytes[0], 0xFF010101);

    paint
      ..color = green
      ..imageFilter = compOrder2;
    bytes = await getBytesForColorPaint(paint);
    expect(bytes[0], 0xFF020202);
  });

  test('Composite ImageFilter toString', () {
    expect(
      ImageFilter.compose(outer: makeBlur(20.0, 20.0), inner: makeBlur(10.0, 10.0)).toString(),
      contains('blur(10.0, 10.0) -> blur(20.0, 20.0)'),
    );

    // Produces a flat list of filters
    expect(
      ImageFilter.compose(
        outer: ImageFilter.compose(outer: makeBlur(30.0, 30.0), inner: makeBlur(20.0, 20.0)),
        inner: ImageFilter.compose(
          outer: const ColorFilter.mode(null, null),
          inner: makeScale(10.0, 10.0),
        ),
      ).toString(),
      contains(
        'matrix([10.0, 0.0, 0.0, 0.0, 0.0, 10.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, -0.0, -0.0, 0.0, 1.0], FilterQuality.low) -> '
        'ColorFilter.mode(null, null) -> '
        'blur(20.0, 20.0) -> '
        'blur(30.0, 30.0)'
      ),
    );
  });
}
