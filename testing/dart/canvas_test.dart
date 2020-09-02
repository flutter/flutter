// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as dart_image;

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_util.dart';

typedef CanvasCallback = void Function(Canvas canvas);

Future<Image> createImage(int width, int height) {
  final Completer<Image> completer = Completer<Image>();
  decodeImageFromPixels(
    Uint8List.fromList(List<int>.generate(
      width * height * 4,
      (int pixel) => pixel % 255,
    )),
    width,
    height,
    PixelFormat.rgba8888,
    (Image image) {
      completer.complete(image);
    },
  );

  return completer.future;
}

void testCanvas(CanvasCallback callback) {
  try {
    callback(Canvas(PictureRecorder(), const Rect.fromLTRB(0.0, 0.0, 0.0, 0.0)));
  } catch (error) { } // ignore: empty_catches
}

void testNoCrashes() {
  test('canvas APIs should not crash', () async {
    final Paint paint = Paint();
    const Rect rect = Rect.fromLTRB(double.nan, double.nan, double.nan, double.nan);
    final RRect rrect = RRect.fromRectAndCorners(rect);
    const Offset offset = Offset(double.nan, double.nan);
    final Path path = Path();
    const Color color = Color(0);
    final Paragraph paragraph = ParagraphBuilder(ParagraphStyle()).build();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    recorderCanvas.scale(1.0, 1.0);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(1, 1);

    try { Canvas(null, null); } catch (error) { } // ignore: empty_catches
    try { Canvas(null, rect); } catch (error) { } // ignore: empty_catches
    try { Canvas(PictureRecorder(), null); } catch (error) { } // ignore: empty_catches
    try { Canvas(PictureRecorder(), rect); } catch (error) { } // ignore: empty_catches

    try {
      PictureRecorder()
        ..endRecording()
        ..endRecording()
        ..endRecording();
    } catch (error) { } // ignore: empty_catches

    testCanvas((Canvas canvas) => canvas.clipPath(path));
    testCanvas((Canvas canvas) => canvas.clipRect(rect));
    testCanvas((Canvas canvas) => canvas.clipRRect(rrect));
    testCanvas((Canvas canvas) => canvas.drawArc(rect, 0.0, 0.0, false, paint));
    testCanvas((Canvas canvas) => canvas.drawAtlas(image, <RSTransform>[], <Rect>[], <Color>[], BlendMode.src, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawCircle(offset, double.nan, paint));
    testCanvas((Canvas canvas) => canvas.drawColor(color, BlendMode.src));
    testCanvas((Canvas canvas) => canvas.drawDRRect(rrect, rrect, paint));
    testCanvas((Canvas canvas) => canvas.drawImage(image, offset, paint));
    testCanvas((Canvas canvas) => canvas.drawImageNine(image, rect, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawImageRect(image, rect, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawLine(offset, offset, paint));
    testCanvas((Canvas canvas) => canvas.drawOval(rect, paint));
    testCanvas((Canvas canvas) => canvas.drawPaint(paint));
    testCanvas((Canvas canvas) => canvas.drawParagraph(paragraph, offset));
    testCanvas((Canvas canvas) => canvas.drawPath(path, paint));
    testCanvas((Canvas canvas) => canvas.drawPicture(picture));
    testCanvas((Canvas canvas) => canvas.drawPoints(PointMode.points, <Offset>[], paint));
    testCanvas((Canvas canvas) => canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, rect, paint));
    testCanvas((Canvas canvas) => canvas.drawRawPoints(PointMode.points, Float32List(0), paint));
    testCanvas((Canvas canvas) => canvas.drawRect(rect, paint));
    testCanvas((Canvas canvas) => canvas.drawRRect(rrect, paint));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, null));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, false));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, true));
    testCanvas((Canvas canvas) => canvas.drawVertices(Vertices(VertexMode.triangles, <Offset>[]), null, paint));
    testCanvas((Canvas canvas) => canvas.getSaveCount());
    testCanvas((Canvas canvas) => canvas.restore());
    testCanvas((Canvas canvas) => canvas.rotate(double.nan));
    testCanvas((Canvas canvas) => canvas.save());
    testCanvas((Canvas canvas) => canvas.saveLayer(rect, paint));
    testCanvas((Canvas canvas) => canvas.saveLayer(null, null));
    testCanvas((Canvas canvas) => canvas.scale(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.skew(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.transform(null));
    testCanvas((Canvas canvas) => canvas.translate(double.nan, double.nan));
  });
}

/// @returns true When the images are resonably similar.
/// @todo Make the search actually fuzzy to a certain degree.
Future<bool> fuzzyCompareImages(Image golden, Image img) async {
  if (golden.width != img.width || golden.height != img.height) {
    return false;
  }
  int getPixel(ByteData data, int x, int y) => data.getUint32((x + y * golden.width) * 4);
  final ByteData goldenData = await golden.toByteData();
  final ByteData imgData = await img.toByteData();
  for (int y = 0; y < golden.height; y++) {
    for (int x = 0; x < golden.width; x++) {
      if (getPixel(goldenData, x, y) != getPixel(imgData, x, y)) {
        return false;
      }
    }
  }
  return true;
}

/// @returns true When the images are resonably similar.
Future<bool> fuzzyGoldenImageCompare(
    Image image, String goldenImageName) async {
  final String imagesPath = path.join('flutter', 'testing', 'resources');
  final File file = File(path.join(imagesPath, goldenImageName));

  bool areEqual = false;

  if (file.existsSync()) {
    final Uint8List goldenData = await file.readAsBytes();

    final Codec codec = await instantiateImageCodec(goldenData);
    final FrameInfo frame = await codec.getNextFrame();
    expect(frame.image.height, equals(image.width));
    expect(frame.image.width, equals(image.height));

    areEqual = await fuzzyCompareImages(frame.image, image);
  }

  if (!areEqual) {
    final ByteData pngData = await image.toByteData();
    final ByteBuffer buffer = pngData.buffer;
    final dart_image.Image png = dart_image.Image.fromBytes(
        image.width, image.height, buffer.asUint8List());
    final String outPath = path.join(imagesPath, 'found_' + goldenImageName);
    File(outPath)..writeAsBytesSync(dart_image.encodePng(png));
    print('wrote: ' + outPath);
  }
  return areEqual;
}

void main() {
  testNoCrashes();

  test('Simple .toImage', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Path circlePath = Path()
      ..addOval(
          Rect.fromCircle(center: const Offset(40.0, 40.0), radius: 20.0));
    final Paint paint = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    canvas.drawPath(circlePath, paint);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(100, 100);
    expect(image.width, equals(100));
    expect(image.height, equals(100));

    final bool areEqual =
        await fuzzyGoldenImageCompare(image, 'canvas_test_toImage.png');
    expect(areEqual, true);
  });

  Gradient makeGradient() {
    return Gradient.linear(
      Offset.zero,
      const Offset(100, 100),
      const <Color>[Color(0xFF4C4D52), Color(0xFF202124)],
    );
  }

  test('Simple gradient', () async {
    Paint.enableDithering = false;
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..shader = makeGradient();
    canvas.drawPaint(paint);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(100, 100);
    expect(image.width, equals(100));
    expect(image.height, equals(100));

    final bool areEqual =
        await fuzzyGoldenImageCompare(image, 'canvas_test_gradient.png');
    expect(areEqual, true);
  }, skip: !Platform.isLinux); // https://github.com/flutter/flutter/issues/53784

  test('Simple dithered gradient', () async {
    Paint.enableDithering = true;
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..shader = makeGradient();
    canvas.drawPaint(paint);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(100, 100);
    expect(image.width, equals(100));
    expect(image.height, equals(100));

    final bool areEqual =
        await fuzzyGoldenImageCompare(image, 'canvas_test_dithered_gradient.png');
    expect(areEqual, true);
  }, skip: !Platform.isLinux); // https://github.com/flutter/flutter/issues/53784

  test('Null values allowed for drawAtlas methods', () async {
    final Image image = await createImage(100, 100);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect rect = Rect.fromLTWH(0, 0, 100, 100);
    final RSTransform transform = RSTransform(1, 0, 0, 0);
    const Color color = Color(0);
    final Paint paint = Paint();
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, null, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[], null, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], null, null, rect, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, rect, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, null, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), null, null, rect, paint);

    expectAssertion(() => canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, rect, null));
    expectAssertion(() => canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], null, rect, paint));
    expectAssertion(() => canvas.drawAtlas(image, <RSTransform>[transform], null, <Color>[color], BlendMode.src, rect, paint));
    expectAssertion(() => canvas.drawAtlas(image, null, <Rect>[rect], <Color>[color], BlendMode.src, rect, paint));
    expectAssertion(() => canvas.drawAtlas(null, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, rect, paint));
  });

  test('Data lengths must match for drawAtlas methods', () async {
    final Image image = await createImage(100, 100);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect rect = Rect.fromLTWH(0, 0, 100, 100);
    final RSTransform transform = RSTransform(1, 0, 0, 0);
    const Color color = Color(0);
    final Paint paint = Paint();
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform, transform], <Rect>[rect, rect], <Color>[color, color], BlendMode.src, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[], null, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], null, null, rect, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, rect, paint);
    canvas.drawRawAtlas(image, Float32List(4), Float32List(4), Int32List(1), BlendMode.src, rect, paint);
    canvas.drawRawAtlas(image, Float32List(4), Float32List(4), null, null, rect, paint);

    expectArgumentError(() => canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[], <Color>[color], BlendMode.src, rect, paint));
    expectArgumentError(() => canvas.drawAtlas(image, <RSTransform>[], <Rect>[rect], <Color>[color], BlendMode.src, rect, paint));
    expectArgumentError(() => canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color, color], BlendMode.src, rect, paint));
    expectArgumentError(() => canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect, rect], <Color>[color], BlendMode.src, rect, paint));
    expectArgumentError(() => canvas.drawAtlas(image, <RSTransform>[transform, transform], <Rect>[rect], <Color>[color], BlendMode.src, rect, paint));
    expectArgumentError(() => canvas.drawRawAtlas(image, Float32List(3), Float32List(3), null, null, rect, paint));
    expectArgumentError(() => canvas.drawRawAtlas(image, Float32List(4), Float32List(0), null, null, rect, paint));
    expectArgumentError(() => canvas.drawRawAtlas(image, Float32List(0), Float32List(4), null, null, rect, paint));
    expectArgumentError(() => canvas.drawRawAtlas(image, Float32List(4), Float32List(4), Int32List(2), BlendMode.src, rect, paint));
  });
}
