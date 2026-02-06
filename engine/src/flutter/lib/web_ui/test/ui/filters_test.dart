// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  const region = ui.Rect.fromLTWH(0, 0, 128, 128);

  Future<void> drawTestImageWithPaint(ui.Paint paint) async {
    final ui.Codec codec = await renderer.instantiateImageCodecFromUrl(
      Uri(path: '/test_images/mandrill_128.png'),
    );
    expect(codec.frameCount, 1);

    final ui.FrameInfo info = await codec.getNextFrame();
    codec.dispose();
    final ui.Image image = info.image;
    expect(image.width, 128);
    expect(image.height, 128);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, region);
    canvas.drawImage(image, ui.Offset.zero, paint);

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
  }

  group('filters', () {
    test('blur filter', () async {
      await drawTestImageWithPaint(
        ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      );
      await matchGoldenFile('ui_filter_blur_imagefilter.png', region: region);
    });

    test('dilate filter', () async {
      await drawTestImageWithPaint(
        ui.Paint()..imageFilter = ui.ImageFilter.dilate(radiusX: 5.0, radiusY: 5.0),
      );
      await matchGoldenFile('ui_filter_dilate_imagefilter.png', region: region);
    });

    test('erode filter', () async {
      await drawTestImageWithPaint(
        ui.Paint()..imageFilter = ui.ImageFilter.erode(radiusX: 5.0, radiusY: 5.0),
      );
      await matchGoldenFile('ui_filter_erode_imagefilter.png', region: region);
    });

    test('matrix filter', () async {
      await drawTestImageWithPaint(
        ui.Paint()
          ..imageFilter = ui.ImageFilter.matrix(
            Matrix4.rotationZ(math.pi / 6).toFloat64(),
            filterQuality: ui.FilterQuality.high,
          ),
      );
      await matchGoldenFile('ui_filter_matrix_imagefilter.png', region: region);
    });

    test('resizing matrix filter', () async {
      await drawTestImageWithPaint(
        ui.Paint()
          ..imageFilter = ui.ImageFilter.matrix(
            Matrix4.diagonal3Values(0.5, 0.5, 1).toFloat64(),
            filterQuality: ui.FilterQuality.high,
          ),
      );
      await matchGoldenFile('ui_filter_matrix_imagefilter_scaled.png', region: region);
    });

    test('composed filters', () async {
      final filter = ui.ImageFilter.compose(
        outer: ui.ImageFilter.matrix(
          Matrix4.rotationZ(math.pi / 6).toFloat64(),
          filterQuality: ui.FilterQuality.high,
        ),
        inner: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      );
      await drawTestImageWithPaint(ui.Paint()..imageFilter = filter);
      await matchGoldenFile('ui_filter_composed_imagefilters.png', region: region);
    });

    test('compose with colorfilter', () async {
      final filter = ui.ImageFilter.compose(
        outer: const ui.ColorFilter.mode(ui.Color.fromRGBO(0, 0, 255, 128), ui.BlendMode.srcOver),
        inner: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      );
      await drawTestImageWithPaint(ui.Paint()..imageFilter = filter);
      await matchGoldenFile('ui_filter_composed_colorfilter.png', region: region);
    });

    test('color filter as image filter', () async {
      const colorFilter = ui.ColorFilter.mode(
        ui.Color.fromARGB(128, 0, 0, 255),
        ui.BlendMode.srcOver,
      );
      await drawTestImageWithPaint(ui.Paint()..imageFilter = colorFilter);
      await matchGoldenFile('ui_filter_colorfilter_as_imagefilter.png', region: region);
      expect(
        colorFilter.toString(),
        'ColorFilter.mode(${const ui.Color(0x800000ff)}, BlendMode.srcOver)',
      );
    });

    test('mode color filter', () async {
      const colorFilter = ui.ColorFilter.mode(
        ui.Color.fromARGB(128, 0, 0, 255),
        ui.BlendMode.srcOver,
      );
      await drawTestImageWithPaint(ui.Paint()..colorFilter = colorFilter);
      await matchGoldenFile('ui_filter_mode_colorfilter.png', region: region);
      expect(
        colorFilter.toString(),
        'ColorFilter.mode(${const ui.Color(0x800000ff)}, BlendMode.srcOver)',
      );
    });

    test('linearToSRGBGamma color filter', () async {
      const colorFilter = ui.ColorFilter.linearToSrgbGamma();
      await drawTestImageWithPaint(ui.Paint()..colorFilter = colorFilter);
      await matchGoldenFile('ui_filter_linear_to_srgb_colorfilter.png', region: region);
      expect(colorFilter.toString(), 'ColorFilter.linearToSrgbGamma()');
    });

    test('srgbToLinearGamma color filter', () async {
      const colorFilter = ui.ColorFilter.srgbToLinearGamma();
      await drawTestImageWithPaint(ui.Paint()..colorFilter = colorFilter);
      await matchGoldenFile('ui_filter_srgb_to_linear_colorfilter.png', region: region);
      expect(colorFilter.toString(), 'ColorFilter.srgbToLinearGamma()');
    });

    test('matrix color filter', () async {
      const sepia = ui.ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0, // row
        0.349, 0.686, 0.168, 0, 0, // row
        0.272, 0.534, 0.131, 0, 0, // row
        0, 0, 0, 1, 0, // row
      ]);
      await drawTestImageWithPaint(ui.Paint()..colorFilter = sepia);
      await matchGoldenFile('ui_filter_matrix_colorfilter.png', region: region);
      expect(sepia.toString(), startsWith('ColorFilter.matrix([0.393, 0.769, 0.189, '));
    });

    test('saturation color filter', () async {
      final colorFilter = ui.ColorFilter.saturation(0);
      await drawTestImageWithPaint(ui.Paint()..colorFilter = colorFilter);
      await matchGoldenFile('ui_filter_saturation_colorfilter.png', region: region);
      expect(colorFilter.toString(), startsWith('ColorFilter.matrix([0.2126, 0.7152, 0.0722'));
    });

    test('matrix color filter with 0..255 translation values', () async {
      const sepia = ui.ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 50.0, // row
        0.349, 0.686, 0.168, 0, 50.0, // row
        0.272, 0.534, 0.131, 0, 50.0, // row
        0, 0, 0, 1, 0, // row
      ]);
      await drawTestImageWithPaint(ui.Paint()..colorFilter = sepia);
      await matchGoldenFile('ui_filter_matrix_colorfilter_with_translation.png', region: region);
      expect(sepia.toString(), startsWith('ColorFilter.matrix([0.393, 0.769, 0.189, '));
    });

    test('invert colors', () async {
      await drawTestImageWithPaint(ui.Paint()..invertColors = true);
      await matchGoldenFile('ui_filter_invert_colors.png', region: region);
    });

    test('invert colors with color filter', () async {
      const sepia = ui.ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0, // row
        0.349, 0.686, 0.168, 0, 0, // row
        0.272, 0.534, 0.131, 0, 0, // row
        0, 0, 0, 1, 0, // row
      ]);

      await drawTestImageWithPaint(
        ui.Paint()
          ..invertColors = true
          ..colorFilter = sepia,
      );
      await matchGoldenFile('ui_filter_invert_colors_with_colorfilter.png', region: region);
    });

    test('mask filter', () async {
      const maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 25.0);
      await drawTestImageWithPaint(ui.Paint()..maskFilter = maskFilter);
      await matchGoldenFile('ui_filter_blur_maskfilter.png', region: region);
    });

    ui.Image makeCheckerBoard(int width, int height) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      const double left = 0;
      final double centerX = width * 0.5;
      final double right = width.toDouble();

      const double top = 0;
      final double centerY = height * 0.5;
      final double bottom = height.toDouble();

      canvas.drawRect(
        ui.Rect.fromLTRB(left, top, centerX, centerY),
        ui.Paint()..color = const ui.Color.fromARGB(255, 0, 255, 0),
      );
      canvas.drawRect(
        ui.Rect.fromLTRB(centerX, top, right, centerY),
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 255, 0),
      );
      canvas.drawRect(
        ui.Rect.fromLTRB(left, centerY, centerX, bottom),
        ui.Paint()..color = const ui.Color.fromARGB(255, 0, 0, 255),
      );
      canvas.drawRect(
        ui.Rect.fromLTRB(centerX, centerY, right, bottom),
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );

      final ui.Picture picture = recorder.endRecording();
      return picture.toImageSync(width, height);
    }

    Future<ui.Rect> renderingOpsWithTileMode(ui.TileMode? tileMode) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color.fromARGB(255, 224, 224, 224), ui.BlendMode.src);

      const zone = ui.Rect.fromLTWH(15, 15, 20, 20);
      final ui.Rect arena = zone.inflate(15);
      const ovalZone = ui.Rect.fromLTWH(20, 15, 10, 20);

      final gradient = ui.Gradient.linear(
        zone.topLeft,
        zone.bottomRight,
        <ui.Color>[
          const ui.Color.fromARGB(255, 0, 255, 0),
          const ui.Color.fromARGB(255, 0, 0, 255),
        ],
        <double>[0, 1],
      );
      final filter = ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0, tileMode: tileMode);
      final white = ui.Paint()..color = const ui.Color.fromARGB(255, 255, 255, 255);
      final grey = ui.Paint()..color = const ui.Color.fromARGB(255, 127, 127, 127);
      final unblurredFill = ui.Paint()..shader = gradient;
      final blurredFill = ui.Paint.from(unblurredFill)..imageFilter = filter;
      final unblurredStroke = ui.Paint.from(unblurredFill)
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..strokeWidth = 10;
      final blurredStroke = ui.Paint.from(unblurredStroke)..imageFilter = filter;
      final ui.Image image = makeCheckerBoard(20, 20);
      const imageBounds = ui.Rect.fromLTRB(0, 0, 20, 20);
      const imageCenter = ui.Rect.fromLTRB(5, 5, 9, 9);
      final points = <ui.Offset>[
        zone.topLeft,
        zone.topCenter,
        zone.topRight,
        zone.centerLeft,
        zone.center,
        zone.centerRight,
        zone.bottomLeft,
        zone.bottomCenter,
        zone.bottomRight,
      ];
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        <ui.Offset>[
          zone.topLeft,
          zone.bottomRight,
          zone.topRight,
          zone.topLeft,
          zone.bottomRight,
          zone.bottomLeft,
        ],
        colors: <ui.Color>[
          const ui.Color.fromARGB(255, 0, 255, 0),
          const ui.Color.fromARGB(255, 255, 0, 0),
          const ui.Color.fromARGB(255, 255, 255, 0),
          const ui.Color.fromARGB(255, 0, 255, 0),
          const ui.Color.fromARGB(255, 255, 0, 0),
          const ui.Color.fromARGB(255, 0, 0, 255),
        ],
      );
      final atlasXforms = <ui.RSTransform>[
        ui.RSTransform.fromComponents(
          rotation: 0.0,
          scale: 1.0,
          anchorX: 0,
          anchorY: 0,
          translateX: zone.topLeft.dx,
          translateY: zone.topLeft.dy,
        ),
        ui.RSTransform.fromComponents(
          rotation: math.pi / 2,
          scale: 1.0,
          anchorX: 0,
          anchorY: 0,
          translateX: zone.topRight.dx,
          translateY: zone.topRight.dy,
        ),
        ui.RSTransform.fromComponents(
          rotation: math.pi,
          scale: 1.0,
          anchorX: 0,
          anchorY: 0,
          translateX: zone.bottomRight.dx,
          translateY: zone.bottomRight.dy,
        ),
        ui.RSTransform.fromComponents(
          rotation: math.pi * 3 / 2,
          scale: 1.0,
          anchorX: 0,
          anchorY: 0,
          translateX: zone.bottomLeft.dx,
          translateY: zone.bottomLeft.dy,
        ),
        ui.RSTransform.fromComponents(
          rotation: math.pi / 4,
          scale: 1.0,
          anchorX: 4,
          anchorY: 4,
          translateX: zone.center.dx,
          translateY: zone.center.dy,
        ),
      ];
      const atlasRects = <ui.Rect>[
        ui.Rect.fromLTRB(6, 6, 14, 14),
        ui.Rect.fromLTRB(6, 6, 14, 14),
        ui.Rect.fromLTRB(6, 6, 14, 14),
        ui.Rect.fromLTRB(6, 6, 14, 14),
        ui.Rect.fromLTRB(6, 6, 14, 14),
      ];

      const double pad = 10;
      final double offset = arena.width + pad;
      const columns = 5;
      final pairArena = ui.Rect.fromLTRB(
        arena.left - 3,
        arena.top - 3,
        arena.right + 3,
        arena.bottom + offset + 3,
      );

      final List<void Function(ui.Canvas canvas, ui.Paint fill, ui.Paint stroke)> renderers = [
        (canvas, fill, stroke) {
          canvas.saveLayer(zone.inflate(5), fill);
          canvas.drawLine(zone.topLeft, zone.bottomRight, unblurredStroke);
          canvas.drawLine(zone.topRight, zone.bottomLeft, unblurredStroke);
          canvas.restore();
        },
        (canvas, fill, stroke) => canvas.drawLine(zone.topLeft, zone.bottomRight, stroke),
        (canvas, fill, stroke) => canvas.drawRect(zone, fill),
        (canvas, fill, stroke) => canvas.drawOval(ovalZone, fill),
        (canvas, fill, stroke) => canvas.drawCircle(zone.center, zone.width * 0.5, fill),
        (canvas, fill, stroke) => canvas.drawRRect(ui.RRect.fromRectXY(zone, 4.0, 4.0), fill),
        (canvas, fill, stroke) => canvas.drawDRRect(
          ui.RRect.fromRectXY(zone, 4.0, 4.0),
          ui.RRect.fromRectXY(zone.deflate(4), 4.0, 4.0),
          fill,
        ),
        (canvas, fill, stroke) => canvas.drawArc(zone, math.pi / 4, math.pi * 3 / 2, true, fill),
        (canvas, fill, stroke) => canvas.drawPath(
          ui.Path()
            ..moveTo(zone.left, zone.top)
            ..lineTo(zone.right, zone.top)
            ..lineTo(zone.left, zone.bottom)
            ..lineTo(zone.right, zone.bottom),
          stroke,
        ),
        (canvas, fill, stroke) => canvas.drawImage(image, zone.topLeft, fill),
        (canvas, fill, stroke) => canvas.drawImageRect(image, imageBounds, zone.inflate(2), fill),
        (canvas, fill, stroke) => canvas.drawImageNine(image, imageCenter, zone.inflate(2), fill),
        (canvas, fill, stroke) => canvas.drawPoints(ui.PointMode.points, points, stroke),
        (canvas, fill, stroke) => canvas.drawVertices(vertices, ui.BlendMode.dstOver, fill),
        (canvas, fill, stroke) =>
            canvas.drawAtlas(image, atlasXforms, atlasRects, null, null, null, fill),
      ];

      canvas.save();
      canvas.translate(pad, pad);
      var renderIndex = 0;
      var rows = 0;
      while (renderIndex < renderers.length) {
        rows += 2;
        canvas.save();
        for (var col = 0; col < columns && renderIndex < renderers.length; col++) {
          final void Function(ui.Canvas canvas, ui.Paint fill, ui.Paint stroke) renderer =
              renderers[renderIndex++];
          canvas.drawRect(pairArena, grey);
          canvas.drawRect(arena, white);
          renderer(canvas, unblurredFill, unblurredStroke);
          canvas.save();
          canvas.translate(0, offset);
          canvas.drawRect(arena, white);
          renderer(canvas, blurredFill, blurredStroke);
          canvas.restore();
          canvas.translate(offset, 0);
        }
        canvas.restore();
        canvas.translate(0, offset * 2);
      }
      canvas.restore();

      await drawPictureUsingCurrentRenderer(recorder.endRecording());
      return ui.Rect.fromLTWH(0, 0, offset * columns + pad, offset * rows + pad);
    }

    test('Rendering ops with ImageFilter blur with default tile mode', () async {
      final ui.Rect region = await renderingOpsWithTileMode(null);
      await matchGoldenFile(
        'ui_filter_blurred_rendering_with_default_tile_mode.png',
        region: region,
      );
    });

    test('Rendering ops with ImageFilter blur with clamp tile mode', () async {
      final ui.Rect region = await renderingOpsWithTileMode(ui.TileMode.clamp);
      await matchGoldenFile('ui_filter_blurred_rendering_with_clamp_tile_mode.png', region: region);
    });

    test('Rendering ops with ImageFilter blur with decal tile mode', () async {
      final ui.Rect region = await renderingOpsWithTileMode(ui.TileMode.decal);
      await matchGoldenFile('ui_filter_blurred_rendering_with_decal_tile_mode.png', region: region);
    });

    test('Rendering ops with ImageFilter blur with mirror tile mode', () async {
      final ui.Rect region = await renderingOpsWithTileMode(ui.TileMode.mirror);
      await matchGoldenFile(
        'ui_filter_blurred_rendering_with_mirror_tile_mode.png',
        region: region,
      );
    });

    test('Rendering ops with ImageFilter blur with repeated tile mode', () async {
      final ui.Rect region = await renderingOpsWithTileMode(ui.TileMode.repeated);
      await matchGoldenFile(
        'ui_filter_blurred_rendering_with_repeated_tile_mode.png',
        region: region,
      );
    });

    Future<ui.Rect> drawTestCirclesComparison(ui.ImageFilter filter) async {
      const region = ui.Rect.fromLTRB(0, 0, 500, 250);

      final builder = ui.SceneBuilder();
      builder.pushOffset(0, 0);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, region);

      canvas.drawCircle(
        const ui.Offset(75, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle1 = recorder.endRecording();
      builder.addPicture(ui.Offset.zero, redCircle1);

      builder.pushImageFilter(filter);

      // Draw another red circle and apply it to the scene.
      // This one will be affected by the image filter.
      final recorder2 = ui.PictureRecorder();
      final canvas2 = ui.Canvas(recorder2, region);
      canvas2.drawCircle(
        const ui.Offset(425, 125),
        50,
        ui.Paint()..color = const ui.Color.fromARGB(255, 255, 0, 0),
      );
      final ui.Picture redCircle2 = recorder2.endRecording();

      builder.addPicture(ui.Offset.zero, redCircle2);

      await renderScene(builder.build());

      return region;
    }

    test('does not throw for blur filter with sigmaX and sigmaY set to 0', () async {
      // Ignoring redundant arguments (the default sigma is 0) to make the
      // test clearer.
      final imageFilter = ui.ImageFilter.blur(
        // ignore: avoid_redundant_argument_values
        sigmaX: 0,
        // ignore: avoid_redundant_argument_values
        sigmaY: 0,
        tileMode: ui.TileMode.clamp,
      );
      expect(imageFilter, isNotNull);

      final ui.Rect region = await drawTestCirclesComparison(imageFilter);
      await matchGoldenFile('ui_zero_sigma_blur.png', region: region);
    });

    test('does not throw for dilate filter with both radiusX and radiusY set to 0', () async {
      // Ignoring redundant arguments (the default radius is 0) to make the
      // test clearer.
      final imageFilter = ui.ImageFilter.dilate(
        // ignore: avoid_redundant_argument_values
        radiusX: 0,
        // ignore: avoid_redundant_argument_values
        radiusY: 0,
      );
      expect(imageFilter, isNotNull);

      final ui.Rect region = await drawTestCirclesComparison(imageFilter);
      await matchGoldenFile('ui_filter_dilate_imagefilter_with_zeros.png', region: region);
    });

    test('does not throw for erode filter with both radiusX and radiusY set to 0', () async {
      // Ignoring redundant arguments (the default radius is 0) to make the
      // test clearer.
      final imageFilter = ui.ImageFilter.erode(
        // ignore: avoid_redundant_argument_values
        radiusX: 0,
        // ignore: avoid_redundant_argument_values
        radiusY: 0,
      );
      expect(imageFilter, isNotNull);

      final ui.Rect region = await drawTestCirclesComparison(imageFilter);
      await matchGoldenFile('ui_filter_erode_imagefilter_with_zeros.png', region: region);
    });

    test('does not throw for matrix filter with identity matrix', () async {
      final imageFilter = ui.ImageFilter.matrix(Matrix4.identity().toFloat64());
      expect(imageFilter, isNotNull);

      final ui.Rect region = await drawTestCirclesComparison(imageFilter);
      await matchGoldenFile(
        'ui_filter_matrix_imagefilter_with_identity_matrix.png',
        region: region,
      );
    });

    test('== operator', () {
      final filters1 = <ui.ImageFilter>[...createImageFilters(), ...createColorFilters()];
      final filters2 = <ui.ImageFilter>[...createImageFilters(), ...createColorFilters()];

      for (var index1 = 0; index1 < filters1.length; index1 += 1) {
        final ui.ImageFilter imageFilter1 = filters1[index1];
        expect(imageFilter1 == imageFilter1, isTrue);
        for (var index2 = 0; index2 < filters2.length; index2 += 1) {
          final ui.ImageFilter imageFilter2 = filters2[index2];
          expect(imageFilter1 == imageFilter2, imageFilter2 == imageFilter1);
          expect(
            imageFilter1 == imageFilter2,
            index1 == index2,
            reason:
                'filters1[$index1] != filters2[$index2]\n'
                'imageFilter1 = $imageFilter1\n'
                'imageFilter2 = $imageFilter2',
          );
        }
      }
    });
  }, skip: isWimp); // https://github.com/flutter/flutter/issues/175371

  group('MaskFilter', () {
    test('with 0 sigma can be set on a Paint', () {
      final paint = ui.Paint();
      const filter = ui.MaskFilter.blur(ui.BlurStyle.normal, 0);

      expect(() => paint.maskFilter = filter, isNot(throwsException));
    });
  });
}

List<ui.ColorFilter> createColorFilters() {
  // Creates new color filter instances on each invocation.
  return <ui.ColorFilter>[
    // ignore: prefer_const_constructors
    EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.srcOver),
    // ignore: prefer_const_constructors
    EngineColorFilter.mode(ui.Color(0x12345678), ui.BlendMode.dstOver),
    // ignore: prefer_const_constructors
    EngineColorFilter.mode(ui.Color(0x87654321), ui.BlendMode.dstOver),
    // ignore: prefer_const_constructors
    EngineColorFilter.matrix(<double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]),
    EngineColorFilter.matrix(
      Float32List.fromList(<double>[2, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0]),
    ),
    // ignore: prefer_const_constructors
    EngineColorFilter.linearToSrgbGamma(),
    // ignore: prefer_const_constructors
    EngineColorFilter.srgbToLinearGamma(),
    EngineColorFilter.saturation(0.5),
  ];
}

List<ui.ImageFilter> createImageFilters() {
  final filters = <ui.ImageFilter>[
    ui.ImageFilter.blur(sigmaX: 5, sigmaY: 6, tileMode: ui.TileMode.clamp),
    ui.ImageFilter.blur(sigmaX: 6, sigmaY: 5, tileMode: ui.TileMode.clamp),
    ui.ImageFilter.blur(sigmaX: 6, sigmaY: 5, tileMode: ui.TileMode.decal),
    ui.ImageFilter.dilate(radiusX: 5, radiusY: 6),
    ui.ImageFilter.erode(radiusX: 7, radiusY: 8),
  ];
  filters.add(ui.ImageFilter.compose(outer: filters[0], inner: filters[1]));
  filters.add(ui.ImageFilter.compose(outer: filters[1], inner: filters[3]));
  return filters;
}
