// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'goldens.dart';
import 'impeller_enabled.dart';

typedef CanvasCallback = void Function(Canvas canvas);

void main() {
  test('Vertices checks', () {
    try {
      Vertices(VertexMode.triangles, const <Offset>[
        Offset.zero,
        Offset.zero,
        Offset.zero,
      ], indices: Uint16List.fromList(const <int>[0, 2, 5]));
      throw 'Vertices did not throw the expected error.';
    } on ArgumentError catch (e) {
      expect(
        '$e',
        'Invalid argument(s): "indices" values must be valid indices in the positions list (i.e. numbers in the range 0..2), but indices[2] is 5, which is too big.',
      );
    }
    Vertices(
      // This one does not throw.
      VertexMode.triangles,
      const <Offset>[Offset.zero],
    ).dispose();
    Vertices(
      // This one should not throw.
      VertexMode.triangles,
      const <Offset>[Offset.zero, Offset.zero, Offset.zero],
      indices: Uint16List.fromList(const <int>[
        0,
        2,
        1,
        2,
        0,
        1,
        2,
        0,
      ]), // Uint16List implements List<int> so this is ok.
    ).dispose();
  });

  test('Vertices.raw checks', () {
    expect(
      () {
        Vertices.raw(VertexMode.triangles, Float32List.fromList(const <double>[0.0]));
      },
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError e) => '$e',
          'message',
          'Invalid argument(s): "positions" must have an even number of entries (each coordinate is an x,y pair).',
        ),
      ),
    );

    Object? indicesError;
    try {
      Vertices.raw(
        VertexMode.triangles,
        Float32List.fromList(const <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
        indices: Uint16List.fromList(const <int>[0, 2, 5]),
      );
      throw 'Vertices.raw did not throw the expected error.';
    } on ArgumentError catch (e) {
      indicesError = e;
    }
    expect(
      '$indicesError',
      'Invalid argument(s): "indices" values must be valid indices in the positions list (i.e. numbers in the range 0..2), but indices[2] is 5, which is too big.',
    );

    Vertices.raw(
      // This one does not throw.
      VertexMode.triangles,
      Float32List.fromList(const <double>[0.0, 0.0]),
    ).dispose();
    Vertices.raw(
      // This one should not throw.
      VertexMode.triangles,
      Float32List.fromList(const <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
      indices: Uint16List.fromList(const <int>[0, 2, 1, 2, 0, 1, 2, 0]),
    ).dispose();
  });

  test('BackdropFilter with multiple clips', () async {
    // Regression test for https://github.com/flutter/flutter/issues/144211
    final sceneBuilder = SceneBuilder();

    final Picture redClippedPicture = _makePicture((Canvas canvas) {
      canvas.drawPaint(Paint()..color = const Color(0xFFFFFFFF));
      canvas.clipRect(const Rect.fromLTRB(10, 10, 200, 200));
      canvas.clipRect(const Rect.fromLTRB(11, 10, 300, 200));
      canvas.drawPaint(Paint()..color = const Color(0xFFFF0000));
    });
    sceneBuilder.addPicture(Offset.zero, redClippedPicture);

    final matrix = Float64List(16);
    sceneBuilder.pushBackdropFilter(ImageFilter.matrix(matrix));

    final Picture whitePicture = _makePicture((Canvas canvas) {
      canvas.drawPaint(Paint()..color = const Color(0xFFFFFFFF));
    });
    sceneBuilder.addPicture(Offset.zero, whitePicture);

    final Scene scene = sceneBuilder.build();
    final Image image = scene.toImageSync(20, 20);

    final ByteData data = (await image.toByteData())!;
    expect(data.buffer.asUint32List().length, 20 * 20);
    // If clipping went wrong as in the linked issue, there will be red pixels.
    for (final int color in data.buffer.asUint32List()) {
      expect(color, 0xFFFFFFFF);
    }

    scene.dispose();
    image.dispose();
    whitePicture.dispose();
    redClippedPicture.dispose();
  });

  test('BackdropFilter with ImageFilter.shader honors FilterQuality', () async {
    // Regression test for https://github.com/flutter/flutter/issues/188365.
    if (!impellerEnabled) {
      print('Skipped for Skia.');
      return;
    }

    // The helper draws a black/white striped backdrop and filters it with a
    // shader that samples the backdrop at a fractional texel coordinate. Because
    // the stripes are grayscale, checking a single color channel is enough to
    // tell whether the sample came from a source texel or was interpolated.
    final Image nearest = await _backdropShaderWithFilterQuality(FilterQuality.none);
    final Image linear = await _backdropShaderWithFilterQuality(FilterQuality.low);

    // Nearest-neighbor sampling should pick either black or white exactly.
    // Linear sampling should blend the adjacent black and white stripes.
    final int nearestSample = await _redAt(nearest, 0, 1);
    final int linearSample = await _redAt(linear, 0, 1);

    expect(nearestSample, anyOf(0, 255));
    expect(linearSample, allOf(greaterThan(0), lessThan(255)));

    nearest.dispose();
    linear.dispose();
  });

  test('BackdropFilter with Blur honors TileMode.decal', () async {
    final Image image = _backdropBlurWithTileMode(TileMode.decal);

    final ImageComparer comparer = await ImageComparer.create();
    await comparer.addGoldenImage(image, 'dart_ui_backdrop_filter_blur_decal_tile_mode.png');

    image.dispose();
  });

  test('BackdropFilter with Blur honors TileMode.clamp', () async {
    final Image image = _backdropBlurWithTileMode(TileMode.clamp);

    final ImageComparer comparer = await ImageComparer.create();
    await comparer.addGoldenImage(image, 'dart_ui_backdrop_filter_blur_clamp_tile_mode.png');

    image.dispose();
  });

  test('BackdropFilter with Blur honors TileMode.mirror', () async {
    final Image image = _backdropBlurWithTileMode(TileMode.mirror);

    final ImageComparer comparer = await ImageComparer.create();
    await comparer.addGoldenImage(image, 'dart_ui_backdrop_filter_blur_mirror_tile_mode.png');

    image.dispose();
  });

  test('BackdropFilter with Blur honors TileMode.repeated', () async {
    final Image image = _backdropBlurWithTileMode(TileMode.repeated);

    final ImageComparer comparer = await ImageComparer.create();
    await comparer.addGoldenImage(image, 'dart_ui_backdrop_filter_blur_repeated_tile_mode.png');

    image.dispose();
  });

  test('BackdropFilter with Blur default TileMode acts as TileMode.mirror', () async {
    final Image image = _backdropBlurWithTileMode(null);

    final ImageComparer comparer = await ImageComparer.create();
    // It would be nice to compare the output here to the "mirror" golden
    // image generated above, but this file name is where the results of
    // this test will be written and the comparison will be done independently
    // in a separate step. If we repeated the name of the "mirror" golden,
    // we would just overwrite the results of the mirror test above.
    await comparer.addGoldenImage(image, 'dart_ui_backdrop_filter_blur_default_tile_mode.png');

    image.dispose();
  });

  test('ImageFilter.matrix defaults to FilterQuality.medium', () {
    final Float64List data = Matrix4.identity().storage;
    expect(ImageFilter.matrix(data).toString(), 'ImageFilter.matrix($data, FilterQuality.medium)');
  });

  test('Picture.toImage generates mip maps', () async {
    // Draw a grid of red and blue squares. When averaged together via
    // mip maps, this should result in a purplish color. If there are no
    // mip maps, the original red and blue colors will be preserved regardless
    // of scale or number of pixels.
    late final Image image;
    {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      for (var i = 0; i < 20; i++) {
        for (var j = 0; j < 20; j++) {
          final color = (i + j).isEven ? const Color(0xFFFF0000) : const Color(0xFF0000FF);
          canvas.drawRect(Rect.fromLTWH(i * 5, j * 5, 5, 5), Paint()..color = color);
        }
      }
      final Picture picture = recorder.endRecording();
      image = await picture.toImage(100, 100);
    }

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.save();
    canvas.scale(0.25, 0.25);
    canvas.drawImage(image, Offset.zero, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    final Picture picture = recorder.endRecording();
    final Image resultImage = await picture.toImage(10, 10);
    final ByteData data = (await resultImage.toByteData())!;

    final Int32List colors = data.buffer.asInt32List();
    for (var i = 0; i < colors.length; i++) {
      expect(colors[i], isNot(const Color(0xFFFF0000)));
      expect(colors[i], isNot(const Color(0xFF0000FF)));
    }
  });
}

Picture _makePicture(CanvasCallback callback) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  callback(canvas);
  return recorder.endRecording();
}

Image _backdropBlurWithTileMode(TileMode? tileMode) {
  const double rectSize = 10;
  const count = 50;
  const double imgSize = rectSize * count;

  final Picture blueGreenGridPicture = _makePicture((Canvas canvas) {
    const white = Color(0xFFFFFFFF);
    const purple = Color(0xFFFF00FF);
    const blue = Color(0xFF0000FF);
    const green = Color(0xFF00FF00);
    const yellow = Color(0xFFFFFF00);
    const red = Color(0xFFFF0000);
    canvas.drawColor(white, BlendMode.src);
    for (var i = 0; i < count; i++) {
      for (var j = 0; j < count; j++) {
        final rectOdd = (i + j) & 1 == 0;
        final fg = (i < count / 2)
            ? ((j < count / 2) ? green : blue)
            : ((j < count / 2) ? yellow : red);
        canvas.drawRect(
          Rect.fromLTWH(i * rectSize, j * rectSize, rectSize, rectSize),
          Paint()..color = rectOdd ? fg : white,
        );
      }
    }
    canvas.drawRect(const Rect.fromLTWH(0, 0, imgSize, 1), Paint()..color = purple);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, imgSize), Paint()..color = purple);
    canvas.drawRect(const Rect.fromLTWH(0, imgSize - 1, imgSize, 1), Paint()..color = purple);
    canvas.drawRect(const Rect.fromLTWH(imgSize - 1, 0, 1, imgSize), Paint()..color = purple);
  });

  final sceneBuilder = SceneBuilder();
  sceneBuilder.addPicture(Offset.zero, blueGreenGridPicture);
  sceneBuilder.pushBackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20, tileMode: tileMode));

  final Scene scene = sceneBuilder.build();
  final Image image = scene.toImageSync(imgSize.round(), imgSize.round());

  scene.dispose();
  blueGreenGridPicture.dispose();

  return image;
}

Future<Image> _backdropShaderWithFilterQuality(FilterQuality filterQuality) async {
  const int width = 16;
  const int height = 4;
  double heightAsDouble = height.toDouble();
  const double stripeWidth = 1.0;

  final FragmentProgram program = await FragmentProgram.fromAsset(
    'filter_shader_fractional_texel.frag.iplr',
  );
  final FragmentShader shader = program.fragmentShader();

  final Picture stripePicture = _makePicture((Canvas canvas) {
    for (int x = 0; x < width; x++) {
      canvas.drawRect(
        Rect.fromLTWH(x * stripeWidth, 0, stripeWidth, heightAsDouble),
        Paint()..color = x.isEven ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      );
    }
  });

  final Picture transparentPicture = _makePicture((Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), heightAsDouble),
      Paint()..color = const Color(0x00000000),
    );
  });

  final sceneBuilder = SceneBuilder();
  sceneBuilder.addPicture(Offset.zero, stripePicture);
  sceneBuilder.pushBackdropFilter(ImageFilter.shader(shader, filterQuality: filterQuality));
  sceneBuilder.addPicture(Offset.zero, transparentPicture);
  sceneBuilder.pop();

  final Scene scene = sceneBuilder.build();
  final Image image = scene.toImageSync(width, height);

  scene.dispose();
  stripePicture.dispose();
  transparentPicture.dispose();
  shader.dispose();

  return image;
}

Future<int> _redAt(Image image, int x, int y) async {
  final ByteData data = (await image.toByteData())!;
  return data.getUint8((y * image.width + x) * 4);
}
