// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;
import 'package:vector_math/vector_math_64.dart';

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
    callback(Canvas(PictureRecorder(), Rect.zero));
  } catch (error) { } // ignore: empty_catches
}

Future<Image> toImage(CanvasCallback callback, int width, int height) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder, Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble()));
  callback(canvas);
  final Picture picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void testNoCrashes() {
  test('canvas APIs should not crash', () async {
    final Paint paint = Paint();
    const Rect rect = Rect.fromLTRB(double.nan, double.nan, double.nan, double.nan);
    final RRect rrect = RRect.fromRectAndCorners(rect);
    const Offset offset = Offset(double.nan, double.nan);
    final Path path = Path();
    const Color color = Color(0x00000000);
    final Paragraph paragraph = ParagraphBuilder(ParagraphStyle()).build();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    recorderCanvas.scale(1.0, 1.0);
    final Picture picture = recorder.endRecording();
    final Image image = await picture.toImage(1, 1);

    try { Canvas(PictureRecorder()); } catch (error) { } // ignore: empty_catches
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
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, false));
    testCanvas((Canvas canvas) => canvas.drawShadow(path, color, double.nan, true));
    testCanvas((Canvas canvas) => canvas.drawVertices(Vertices(VertexMode.triangles, <Offset>[]), BlendMode.screen, paint));
    testCanvas((Canvas canvas) => canvas.getSaveCount());
    testCanvas((Canvas canvas) => canvas.restore());
    testCanvas((Canvas canvas) => canvas.rotate(double.nan));
    testCanvas((Canvas canvas) => canvas.save());
    testCanvas((Canvas canvas) => canvas.saveLayer(rect, paint));
    testCanvas((Canvas canvas) => canvas.saveLayer(null, paint));
    testCanvas((Canvas canvas) => canvas.scale(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.skew(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.transform(Float64List(16)));
    testCanvas((Canvas canvas) => canvas.translate(double.nan, double.nan));
    testCanvas((Canvas canvas) => canvas.drawVertices(Vertices(VertexMode.triangles, <Offset>[],
                                                               indices: <int>[]), BlendMode.screen, paint));
    testCanvas((Canvas canvas) => canvas.drawVertices(Vertices(VertexMode.triangles, <Offset>[])..dispose(), BlendMode.screen, paint));

    // Regression test for https://github.com/flutter/flutter/issues/115143
    testCanvas((Canvas canvas) => canvas.drawPaint(Paint()..imageFilter = const ColorFilter.mode(Color(0x00000000), BlendMode.xor)));

    // Regression test for https://github.com/flutter/flutter/issues/120278
    testCanvas((Canvas canvas) => canvas.drawPaint(Paint()..imageFilter = ImageFilter.compose(
      outer: ImageFilter.matrix(Matrix4.identity().storage),
      inner: ImageFilter.blur())));
  });
}

/// @returns true When the images are reasonably similar.
/// @todo Make the search actually fuzzy to a certain degree.
Future<bool> fuzzyCompareImages(Image golden, Image img) async {
  if (golden.width != img.width || golden.height != img.height) {
    return false;
  }
  int getPixel(ByteData data, int x, int y) => data.getUint32((x + y * golden.width) * 4);
  final ByteData goldenData = (await golden.toByteData())!;
  final ByteData imgData = (await img.toByteData())!;
  for (int y = 0; y < golden.height; y++) {
    for (int x = 0; x < golden.width; x++) {
      if (getPixel(goldenData, x, y) != getPixel(imgData, x, y)) {
        return false;
      }
    }
  }
  return true;
}

Future<void> saveTestImage(Image image, String filename) async {
  final String imagesPath = path.join('flutter', 'testing', 'resources');
  final ByteData pngData = (await image.toByteData(format: ImageByteFormat.png))!;
  final String outPath = path.join(imagesPath, filename);
  File(outPath).writeAsBytesSync(pngData.buffer.asUint8List());
  print('wrote: $outPath');
}

/// @returns true When the images are reasonably similar.
Future<bool> fuzzyGoldenImageCompare(
    Image image, String goldenImageName) async {
  final String imagesPath = path.join('flutter', 'testing', 'resources');
  final File file = File(path.join(imagesPath, goldenImageName));

  bool areEqual = false;

  if (file.existsSync()) {
    final Uint8List goldenData = await file.readAsBytes();

    final Codec codec = await instantiateImageCodec(goldenData);
    final FrameInfo frame = await codec.getNextFrame();
    expect(frame.image.height, equals(image.height));
    expect(frame.image.width, equals(image.width));

    areEqual = await fuzzyCompareImages(frame.image, image);
  }

  if (!areEqual) {
    saveTestImage(image, 'found_$goldenImageName');
  }
  return areEqual;
}

void main() {
  testNoCrashes();

  test('Simple .toImage', () async {
    final Image image = await toImage((Canvas canvas) {
      final Path circlePath = Path()
        ..addOval(
            Rect.fromCircle(center: const Offset(40.0, 40.0), radius: 20.0));
      final Paint paint = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.fill;
      canvas.drawPath(circlePath, paint);
    }, 100, 100);
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
    final Image image = await toImage((Canvas canvas) {
      final Paint paint = Paint()..shader = makeGradient();
      canvas.drawPaint(paint);
    }, 100, 100);
    expect(image.width, equals(100));
    expect(image.height, equals(100));

    final bool areEqual =
        await fuzzyGoldenImageCompare(image, 'canvas_test_gradient.png');
    expect(areEqual, true);
  }, skip: !Platform.isLinux); // https://github.com/flutter/flutter/issues/53784

  test('Simple dithered gradient', () async {
    Paint.enableDithering = true;
    final Image image = await toImage((Canvas canvas) {
      final Paint paint = Paint()..shader = makeGradient();
      canvas.drawPaint(paint);
    }, 100, 100);
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
    const Color color = Color(0x00000000);
    final Paint paint = Paint();
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], BlendMode.src, null, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[], null, rect, paint);
    canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], null, null, rect, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, rect, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), Int32List(0), BlendMode.src, null, paint);
    canvas.drawRawAtlas(image, Float32List(0), Float32List(0), null, null, rect, paint);

    expectAssertion(() => canvas.drawAtlas(image, <RSTransform>[transform], <Rect>[rect], <Color>[color], null, rect, paint));
  });

  test('Data lengths must match for drawAtlas methods', () async {
    final Image image = await createImage(100, 100);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect rect = Rect.fromLTWH(0, 0, 100, 100);
    final RSTransform transform = RSTransform(1, 0, 0, 0);
    const Color color = Color(0x00000000);
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

  test('Canvas preserves perspective data in Matrix4', () async {
    const double rotateAroundX = pi / 6;  // 30 degrees
    const double rotateAroundY = pi / 9;  // 20 degrees
    const int width = 150;
    const int height = 150;
    const Color black = Color.fromARGB(255, 0, 0, 0);
    const Color green = Color.fromARGB(255, 0, 255, 0);
    void paint(Canvas canvas, CanvasCallback rotate) {
      canvas.translate(width * 0.5, height * 0.5);
      rotate(canvas);
      const double width3 = width / 3.0;
      const double width5 = width / 5.0;
      const double width10 = width / 10.0;
      canvas.drawRect(const Rect.fromLTRB(-width3, -width3, width3, width3), Paint()..color = green);
      canvas.drawRect(const Rect.fromLTRB(-width5, -width5, -width10, width5), Paint()..color = black);
      canvas.drawRect(const Rect.fromLTRB(-width5, -width5, width5, -width10), Paint()..color = black);
    }

    final Image incrementalMatrixImage = await toImage((Canvas canvas) {
      paint(canvas, (Canvas canvas) {
        final Matrix4 matrix = Matrix4.identity();
        matrix.setEntry(3, 2, 0.001);
        canvas.transform(matrix.storage);
        matrix.setRotationX(rotateAroundX);
        canvas.transform(matrix.storage);
        matrix.setRotationY(rotateAroundY);
        canvas.transform(matrix.storage);
      });
    }, width, height);
    final Image combinedMatrixImage = await toImage((Canvas canvas) {
      paint(canvas, (Canvas canvas) {
        final Matrix4 matrix = Matrix4.identity();
        matrix.setEntry(3, 2, 0.001);
        matrix.rotateX(rotateAroundX);
        matrix.rotateY(rotateAroundY);
        canvas.transform(matrix.storage);
      });
    }, width, height);

    final bool areEqual = await fuzzyCompareImages(incrementalMatrixImage, combinedMatrixImage);

    if (!areEqual) {
      saveTestImage(incrementalMatrixImage, 'incremental_3D_transform_test_image.png');
      saveTestImage(combinedMatrixImage, 'combined_3D_transform_test_image.png');
    }
    expect(areEqual, true);
  });

  test('Path effects from Paragraphs do not affect further rendering', () async {
    void drawText(Canvas canvas, String content, Offset offset,
        {TextDecorationStyle style = TextDecorationStyle.solid}) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle());
      builder.pushStyle(TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: const Color(0xFF0000FF),
        fontSize: 10,
        color: const Color(0xFF000000),
        decorationStyle: style,
      ));
      builder.addText(content);
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 100));
      canvas.drawParagraph(paragraph, offset);
    }

    final Image image = await toImage((Canvas canvas) {
      canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.srcOver);
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      drawText(canvas, 'Hello World', const Offset(20, 10));
      canvas.drawCircle(const Offset(150, 25), 15, paint..color = const Color(0xFF00FF00));
      drawText(canvas, 'Regular text', const Offset(20, 60));
      canvas.drawCircle(const Offset(150, 75), 15, paint..color = const Color(0xFFFFFF00));
      drawText(canvas, 'Dotted text', const Offset(20, 110), style: TextDecorationStyle.dotted);
      canvas.drawCircle(const Offset(150, 125), 15, paint..color = const Color(0xFFFF0000));
      drawText(canvas, 'Dashed text', const Offset(20, 160), style: TextDecorationStyle.dashed);
      canvas.drawCircle(const Offset(150, 175), 15, paint..color = const Color(0xFFFF0000));
      drawText(canvas, 'Wavy text', const Offset(20, 210), style: TextDecorationStyle.wavy);
      canvas.drawCircle(const Offset(150, 225), 15, paint..color = const Color(0xFFFF0000));
    }, 200, 250);
    expect(image.width, equals(200));
    expect(image.height, equals(250));

    final bool areEqual =
        await fuzzyGoldenImageCompare(image, 'dotted_path_effect_mixed_with_stroked_geometry.png');
    expect(areEqual, true);
  }, skip: !Platform.isLinux); // https://github.com/flutter/flutter/issues/53784

  test('Gradients with matrices in Paragraphs render correctly', () async {
    final Image image = await toImage((Canvas canvas) {
      final Paint p = Paint();
      final Float64List transform = Float64List.fromList(<double>[
        86.80000129342079,
        0.0,
        0.0,
        0.0,
        0.0,
        94.5,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        60.0,
        224.310302734375,
        0.0,
        1.0
      ]);
      p.shader = Gradient.radial(
          const Offset(2.5, 0.33),
          0.8,
          <Color>[
            const Color(0xffff0000),
            const Color(0xff00ff00),
            const Color(0xff0000ff),
            const Color(0xffff00ff)
          ],
          <double>[0.0, 0.3, 0.7, 0.9],
          TileMode.mirror,
          transform,
          const Offset(2.55, 0.4));
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle());
      builder.pushStyle(TextStyle(
        foreground: p,
        fontSize: 200,
      ));
      builder.addText('Woodstock!');
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 1000));
      canvas.drawParagraph(paragraph, const Offset(10, 150));
    }, 600, 400);
    expect(image.width, equals(600));
    expect(image.height, equals(400));

    final bool areEqual =
    await fuzzyGoldenImageCompare(image, 'text_with_gradient_with_matrix.png');
    expect(areEqual, true);
  }, skip: !Platform.isLinux); // https://github.com/flutter/flutter/issues/53784

  test('toImageSync - too big', () async {
    PictureRecorder recorder = PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.drawPaint(Paint()..color = const Color(0xFF123456));
    final Picture picture = recorder.endRecording();
    final Image image = picture.toImageSync(300000, 4000000);
    picture.dispose();

    expect(image.width, 300000);
    expect(image.height, 4000000);

    recorder = PictureRecorder();
    canvas = Canvas(recorder);

    // On a slower CI machine, the raster thread may get behind the UI thread
    // here. However, once the image is in an error state it will immediately
    // throw on subsequent attempts.
    bool caughtException = false;
    for (int iterations = 0; iterations < 1000; iterations += 1) {
      try {
        canvas.drawImage(image, Offset.zero, Paint());
      } on PictureRasterizationException catch (e) {
        caughtException = true;
        expect(
          e.message,
          contains('unable to create bitmap render target at specified size ${image.width}x${image.height}'),
        );
        break;
      }
      // Let the event loop turn.
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(caughtException, true);
    expect(
      () => canvas.drawImageRect(image, Rect.zero, Rect.zero, Paint()),
      throwsException,
    );
    expect(
      () => canvas.drawImageNine(image, Rect.zero, Rect.zero, Paint()),
      throwsException,
    );
    expect(
      () => canvas.drawAtlas(image, <RSTransform>[], <Rect>[], null, null, null, Paint()),
      throwsException,
    );
  });

  test('toImageSync - succeeds', () async {
    PictureRecorder recorder = PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.drawPaint(Paint()..color = const Color(0xFF123456));
    final Picture picture = recorder.endRecording();
    final Image image = picture.toImageSync(30, 40);
    picture.dispose();

    expect(image.width, 30);
    expect(image.height, 40);

    recorder = PictureRecorder();
    canvas = Canvas(recorder);
    expect(
      () => canvas.drawImage(image, Offset.zero, Paint()),
      returnsNormally,
    );
    expect(
      () => canvas.drawImageRect(image, Rect.zero, Rect.zero, Paint()),
      returnsNormally,
    );
    expect(
      () => canvas.drawImageNine(image, Rect.zero, Rect.zero, Paint()),
      returnsNormally,
    );
    expect(
      () => canvas.drawAtlas(image, <RSTransform>[], <Rect>[], null, null, null, Paint()),
      returnsNormally,
    );
  });

  test('toImageSync - toByteData', () async {
    const Color color = Color(0xFF123456);
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawPaint(Paint()..color = color);
    final Picture picture = recorder.endRecording();
    final Image image = picture.toImageSync(6, 8);
    picture.dispose();

    expect(image.width, 6);
    expect(image.height, 8);

    final ByteData? data = await image.toByteData();

    expect(data, isNotNull);
    expect(data!.lengthInBytes, 6 * 8 * 4);
    expect(data.buffer.asUint8List()[0], 0x12);
    expect(data.buffer.asUint8List()[1], 0x34);
    expect(data.buffer.asUint8List()[2], 0x56);
    expect(data.buffer.asUint8List()[3], 0xFF);
  });

  test('toImage and toImageSync have identical contents', () async {
    // Note: on linux this stil seems to be different.
    // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/108835
    if (Platform.isLinux) {
      return;
    }

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(20, 20, 100, 100),
      Paint()..color = const Color(0xA0FF6D00),
    );
    final Picture picture = recorder.endRecording();
    final Image toImageImage = await picture.toImage(200, 200);
    final Image toImageSyncImage = picture.toImageSync(200, 200);

    // To trigger observable difference in alpha, draw image
    // on a second canvas.
    Future<ByteData> drawOnCanvas(Image image) async {
      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawPaint(Paint()..color = const Color(0x4FFFFFFF));
      canvas.drawImage(image, Offset.zero, Paint());
      final Image resultImage = await recorder.endRecording().toImage(200, 200);
      return (await resultImage.toByteData())!;
    }

    final ByteData dataSync = await drawOnCanvas(toImageImage);
    final ByteData data = await drawOnCanvas(toImageSyncImage);
    expect(data, listEquals(dataSync));
  });

  test('Canvas.drawParagraph throws when Paragraph.layout was not called', () async {
    // Regression test for https://github.com/flutter/flutter/issues/97172
    bool assertsEnabled = false;
    assert(() {
      assertsEnabled = true;
      return true;
    }());

    Object? error;
    try {
      await toImage((Canvas canvas) {
        final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle());
        builder.addText('Woodstock!');
        final Paragraph woodstock = builder.build();
        canvas.drawParagraph(woodstock, const Offset(0, 50));
      }, 100, 100);
    } catch (e) {
      error = e;
    }
    if (assertsEnabled) {
      expect(error, isNotNull);
    } else {
      expect(error, isNull);
    }
  });

  Future<Image> drawText(String text) {
    return toImage((Canvas canvas) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'RobotoSerif',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: 15.0,
      ));
      builder.pushStyle(TextStyle(color: const Color(0xFF0000FF)));
      builder.addText(text);

      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 20 * 5.0));

      canvas.drawParagraph(paragraph, Offset.zero);
    }, 100, 100);
  }

  test('Canvas.drawParagraph renders tab as space instead of tofu', () async {
    // Skia renders a tofu if the font does not have a glyph for a character.
    // However, Flutter opts-in to a Skia feature to render tabs as a single space.
    // See: https://github.com/flutter/flutter/issues/79153
    final File file = File(path.join('flutter', 'testing', 'resources', 'RobotoSlab-VariableFont_wght.ttf'));
    final Uint8List fontData = await file.readAsBytes();
    await loadFontFromList(fontData, fontFamily: 'RobotoSerif');

    // The backspace character, \b, does not have a corresponding glyph and is rendered as a tofu.
    final Image tabImage = await drawText('>\t<');
    final Image spaceImage = await drawText('> <');
    final Image tofuImage = await drawText('>\b<');

    // The tab's image should be identical to the space's image but not the tofu's image.
    final bool tabToSpaceComparison = await fuzzyCompareImages(tabImage, spaceImage);
    final bool tabToTofuComparison = await fuzzyCompareImages(tabImage, tofuImage);

    expect(tabToSpaceComparison, isTrue);
    expect(tabToTofuComparison, isFalse);
  });

  Matcher closeToTransform(Float64List expected) => (dynamic v) {
    Expect.type<Float64List>(v);
    final Float64List value = v as Float64List;
    expect(expected.length, equals(16));
    expect(value.length, equals(16));
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final double vActual = value[r*4 + c];
        final double vExpected = expected[r*4 + c];
        if ((vActual - vExpected).abs() > 1e-10) {
          Expect.fail('matrix mismatch at $r, $c, $vActual not close to $vExpected');
        }
      }
    }
  };

  Matcher notCloseToTransform(Float64List expected) => (dynamic v) {
    Expect.type<Float64List>(v);
    final Float64List value = v as Float64List;
    expect(expected.length, equals(16));
    expect(value.length, equals(16));
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final double vActual = value[r*4 + c];
        final double vExpected = expected[r*4 + c];
        if ((vActual - vExpected).abs() > 1e-10) {
          return;
        }
      }
    }
    Expect.fail('$value is too close to $expected');
  };

  test('Canvas.translate affects canvas.getTransform', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.translate(12, 14.5);
    final Float64List matrix = Matrix4.translationValues(12, 14.5, 0).storage;
    final Float64List curMatrix = canvas.getTransform();
    expect(curMatrix, closeToTransform(matrix));
    canvas.translate(10, 10);
    final Float64List newCurMatrix = canvas.getTransform();
    expect(newCurMatrix, notCloseToTransform(matrix));
    expect(curMatrix, closeToTransform(matrix));
  });

  test('Canvas.scale affects canvas.getTransform', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(12, 14.5);
    final Float64List matrix = Matrix4.diagonal3Values(12, 14.5, 1).storage;
    final Float64List curMatrix = canvas.getTransform();
    expect(curMatrix, closeToTransform(matrix));
    canvas.scale(10, 10);
    final Float64List newCurMatrix = canvas.getTransform();
    expect(newCurMatrix, notCloseToTransform(matrix));
    expect(curMatrix, closeToTransform(matrix));
  });

  test('Canvas.rotate affects canvas.getTransform', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.rotate(pi);
    final Float64List matrix = Matrix4.rotationZ(pi).storage;
    final Float64List curMatrix = canvas.getTransform();
    expect(curMatrix, closeToTransform(matrix));
    canvas.rotate(pi / 2);
    final Float64List newCurMatrix = canvas.getTransform();
    expect(newCurMatrix, notCloseToTransform(matrix));
    expect(curMatrix, closeToTransform(matrix));
  });

  test('Canvas.skew affects canvas.getTransform', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.skew(12, 14.5);
    final Float64List matrix = (Matrix4.identity()..setEntry(0, 1, 12)..setEntry(1, 0, 14.5)).storage;
    final Float64List curMatrix = canvas.getTransform();
    expect(curMatrix, closeToTransform(matrix));
    canvas.skew(10, 10);
    final Float64List newCurMatrix = canvas.getTransform();
    expect(newCurMatrix, notCloseToTransform(matrix));
    expect(curMatrix, closeToTransform(matrix));
  });

  test('Canvas.transform affects canvas.getTransform', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Float64List matrix = (Matrix4.identity()..translate(12.0, 14.5)..scale(12.0, 14.5)).storage;
    canvas.transform(matrix);
    final Float64List curMatrix = canvas.getTransform();
    expect(curMatrix, closeToTransform(matrix));
    canvas.translate(10, 10);
    final Float64List newCurMatrix = canvas.getTransform();
    expect(newCurMatrix, notCloseToTransform(matrix));
    expect(curMatrix, closeToTransform(matrix));
  });

  Matcher closeToRect(Rect expected) => (dynamic v) {
    Expect.type<Rect>(v);
    final Rect value = v as Rect;
    expect(value.left,   closeTo(expected.left,   1e-6));
    expect(value.top,    closeTo(expected.top,    1e-6));
    expect(value.right,  closeTo(expected.right,  1e-6));
    expect(value.bottom, closeTo(expected.bottom, 1e-6));
  };

  Matcher notCloseToRect(Rect expected) => (dynamic v) {
    Expect.type<Rect>(v);
    final Rect value = v as Rect;
    if ((value.left - expected.left).abs() > 1e-6 ||
        (value.top - expected.top).abs() > 1e-6 ||
        (value.right - expected.right).abs() > 1e-6 ||
        (value.bottom - expected.bottom).abs() > 1e-6) {
      return;
    }
    Expect.fail('$value is too close to $expected');
  };

  test('Canvas.clipRect(doAA=true) affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    const Rect clipExpandedBounds = Rect.fromLTRB(10, 11, 21, 26);
    canvas.clipRect(clipBounds);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipExpandedBounds));
    expect(initialDestinationBounds, closeToRect(clipExpandedBounds));

    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15));
    // Both clip bounds have changed
    expect(canvas.getLocalClipBounds(), notCloseToRect(clipExpandedBounds));
    expect(canvas.getDestinationClipBounds(), notCloseToRect(clipExpandedBounds));
    // Previous return values have not changed
    expect(initialLocalBounds, closeToRect(clipExpandedBounds));
    expect(initialDestinationBounds, closeToRect(clipExpandedBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);

    canvas.save();
    canvas.scale(2, 2);
    const Rect scaledExpandedBounds = Rect.fromLTRB(5, 5.5, 10.5, 13);
    expect(canvas.getLocalClipBounds(), closeToRect(scaledExpandedBounds));
    // Destination bounds are unaffected by transform
    expect(canvas.getDestinationClipBounds(), closeToRect(clipExpandedBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('Canvas.clipRect(doAA=false) affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    canvas.clipRect(clipBounds, doAntiAlias: false);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));

    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15));
    // Both clip bounds have changed
    expect(canvas.getLocalClipBounds(), notCloseToRect(clipBounds));
    expect(canvas.getDestinationClipBounds(), notCloseToRect(clipBounds));
    // Previous return values have not changed
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);

    canvas.save();
    canvas.scale(2, 2);
    const Rect scaledClipBounds = Rect.fromLTRB(5.1, 5.65, 10.2, 12.85);
    expect(canvas.getLocalClipBounds(), closeToRect(scaledClipBounds));
    // Destination bounds are unaffected by transform
    expect(canvas.getDestinationClipBounds(), closeToRect(clipBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('Canvas.clipRect with matrix affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds1 = Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    const Rect clipBounds2 = Rect.fromLTRB(10.0, 10.0, 20.0, 20.0);

    canvas.save();
    canvas.clipRect(clipBounds1, doAntiAlias: false);
    canvas.translate(0, 10.0);
    canvas.clipRect(clipBounds1, doAntiAlias: false);
    expect(canvas.getDestinationClipBounds().isEmpty, isTrue);
    canvas.restore();

    canvas.save();
    canvas.clipRect(clipBounds1, doAntiAlias: false);
    canvas.translate(-10.0, -10.0);
    canvas.clipRect(clipBounds2, doAntiAlias: false);
    expect(canvas.getDestinationClipBounds(), clipBounds1);
    canvas.restore();
  });

  test('Canvas.clipRRect(doAA=true) affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    const Rect clipExpandedBounds = Rect.fromLTRB(10, 11, 21, 26);
    final RRect clip = RRect.fromRectAndRadius(clipBounds, const Radius.circular(3));
    canvas.clipRRect(clip);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipExpandedBounds));
    expect(initialDestinationBounds, closeToRect(clipExpandedBounds));

    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15));
    // Both clip bounds have changed
    expect(canvas.getLocalClipBounds(), notCloseToRect(clipExpandedBounds));
    expect(canvas.getDestinationClipBounds(), notCloseToRect(clipExpandedBounds));
    // Previous return values have not changed
    expect(initialLocalBounds, closeToRect(clipExpandedBounds));
    expect(initialDestinationBounds, closeToRect(clipExpandedBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);

    canvas.save();
    canvas.scale(2, 2);
    const Rect scaledExpandedBounds = Rect.fromLTRB(5, 5.5, 10.5, 13);
    expect(canvas.getLocalClipBounds(), closeToRect(scaledExpandedBounds));
    // Destination bounds are unaffected by transform
    expect(canvas.getDestinationClipBounds(), closeToRect(clipExpandedBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('Canvas.clipRRect(doAA=false) affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    final RRect clip = RRect.fromRectAndRadius(clipBounds, const Radius.circular(3));
    canvas.clipRRect(clip, doAntiAlias: false);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));

    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15), doAntiAlias: false);
    // Both clip bounds have changed
    expect(canvas.getLocalClipBounds(), notCloseToRect(clipBounds));
    expect(canvas.getDestinationClipBounds(), notCloseToRect(clipBounds));
    // Previous return values have not changed
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);

    canvas.save();
    canvas.scale(2, 2);
    const Rect scaledClipBounds = Rect.fromLTRB(5.1, 5.65, 10.2, 12.85);
    expect(canvas.getLocalClipBounds(), closeToRect(scaledClipBounds));
    // Destination bounds are unaffected by transform
    expect(canvas.getDestinationClipBounds(), closeToRect(clipBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('Canvas.clipRRect with matrix affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds1 = Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    const Rect clipBounds2 = Rect.fromLTRB(10.0, 10.0, 20.0, 20.0);
    final RRect clip1 = RRect.fromRectAndRadius(clipBounds1, const Radius.circular(3));
    final RRect clip2 = RRect.fromRectAndRadius(clipBounds2, const Radius.circular(3));

    canvas.save();
    canvas.clipRRect(clip1, doAntiAlias: false);
    canvas.translate(0, 10.0);
    canvas.clipRRect(clip1, doAntiAlias: false);
    expect(canvas.getDestinationClipBounds().isEmpty, isTrue);
    canvas.restore();

    canvas.save();
    canvas.clipRRect(clip1, doAntiAlias: false);
    canvas.translate(-10.0, -10.0);
    canvas.clipRRect(clip2, doAntiAlias: false);
    expect(canvas.getDestinationClipBounds(), clipBounds1);
    canvas.restore();
  });

  test('Canvas.clipPath(doAA=true) affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    const Rect clipExpandedBounds = Rect.fromLTRB(10, 11, 21, 26);
    final Path clip = Path()..addRect(clipBounds)..addOval(clipBounds);
    canvas.clipPath(clip);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipExpandedBounds));
    expect(initialDestinationBounds, closeToRect(clipExpandedBounds));

    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15));
    // Both clip bounds have changed
    expect(canvas.getLocalClipBounds(), notCloseToRect(clipExpandedBounds));
    expect(canvas.getDestinationClipBounds(), notCloseToRect(clipExpandedBounds));
    // Previous return values have not changed
    expect(initialLocalBounds, closeToRect(clipExpandedBounds));
    expect(initialDestinationBounds, closeToRect(clipExpandedBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);

    canvas.save();
    canvas.scale(2, 2);
    const Rect scaledExpandedBounds = Rect.fromLTRB(5, 5.5, 10.5, 13);
    expect(canvas.getLocalClipBounds(), closeToRect(scaledExpandedBounds));
    // Destination bounds are unaffected by transform
    expect(canvas.getDestinationClipBounds(), closeToRect(clipExpandedBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('Canvas.clipPath(doAA=false) affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    final Path clip = Path()..addRect(clipBounds)..addOval(clipBounds);
    canvas.clipPath(clip, doAntiAlias: false);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));

    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15), doAntiAlias: false);
    // Both clip bounds have changed
    expect(canvas.getLocalClipBounds(), notCloseToRect(clipBounds));
    expect(canvas.getDestinationClipBounds(), notCloseToRect(clipBounds));
    // Previous return values have not changed
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);

    canvas.save();
    canvas.scale(2, 2);
    const Rect scaledClipBounds = Rect.fromLTRB(5.1, 5.65, 10.2, 12.85);
    expect(canvas.getLocalClipBounds(), closeToRect(scaledClipBounds));
    // Destination bounds are unaffected by transform
    expect(canvas.getDestinationClipBounds(), closeToRect(clipBounds));
    canvas.restore();

    // save/restore returned the values to their original values
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('Canvas.clipPath with matrix affects canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds1 = Rect.fromLTRB(0.0, 0.0, 10.0, 10.0);
    const Rect clipBounds2 = Rect.fromLTRB(10.0, 10.0, 20.0, 20.0);
    final Path clip1 = Path()..addRect(clipBounds1)..addOval(clipBounds1);
    final Path clip2 = Path()..addRect(clipBounds2)..addOval(clipBounds2);

    canvas.save();
    canvas.clipPath(clip1, doAntiAlias: false);
    canvas.translate(0, 10.0);
    canvas.clipPath(clip1, doAntiAlias: false);
    expect(canvas.getDestinationClipBounds().isEmpty, isTrue);
    canvas.restore();

    canvas.save();
    canvas.clipPath(clip1, doAntiAlias: false);
    canvas.translate(-10.0, -10.0);
    canvas.clipPath(clip2, doAntiAlias: false);
    expect(canvas.getDestinationClipBounds(), clipBounds1);
    canvas.restore();
  });

  test('Canvas.clipRect(diff) does not affect canvas.getClipBounds', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const Rect clipBounds = Rect.fromLTRB(10.2, 11.3, 20.4, 25.7);
    canvas.clipRect(clipBounds, doAntiAlias: false);

    // Save initial return values for testing restored values
    final Rect initialLocalBounds = canvas.getLocalClipBounds();
    final Rect initialDestinationBounds = canvas.getDestinationClipBounds();
    expect(initialLocalBounds, closeToRect(clipBounds));
    expect(initialDestinationBounds, closeToRect(clipBounds));

    canvas.clipRect(const Rect.fromLTRB(0, 0, 15, 15), clipOp: ClipOp.difference, doAntiAlias: false);
    expect(canvas.getLocalClipBounds(), initialLocalBounds);
    expect(canvas.getDestinationClipBounds(), initialDestinationBounds);
  });

  test('RestoreToCount can work', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.save();
    canvas.save();
    canvas.save();
    canvas.save();
    canvas.save();
    expect(canvas.getSaveCount(), equals(6));
    canvas.restoreToCount(2);
    expect(canvas.getSaveCount(), equals(2));
    canvas.restore();
    expect(canvas.getSaveCount(), equals(1));
  });

  test('RestoreToCount count less than 1, the stack should be reset', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.save();
    canvas.save();
    canvas.save();
    canvas.save();
    canvas.save();
    expect(canvas.getSaveCount(), equals(6));
    canvas.restoreToCount(0);
    expect(canvas.getSaveCount(), equals(1));
  });

  test('RestoreToCount count greater than current [getSaveCount], nothing would happend', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.save();
    canvas.save();
    canvas.save();
    canvas.save();
    canvas.save();
    expect(canvas.getSaveCount(), equals(6));
    canvas.restoreToCount(canvas.getSaveCount() + 1);
    expect(canvas.getSaveCount(), equals(6));
  });
}

Matcher listEquals(ByteData expected) => (dynamic v) {
  Expect.type<ByteData>(v);
  final ByteData value = v as ByteData;
  expect(value.lengthInBytes, expected.lengthInBytes);
  for (int i = 0; i < value.lengthInBytes; i++) {
    expect(value.getUint8(i), expected.getUint8(i));
  }
};
