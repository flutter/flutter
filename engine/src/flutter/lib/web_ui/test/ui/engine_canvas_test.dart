// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  test('ui.Canvas is an EngineCanvas', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    expect(canvas, isA<EngineCanvas>());
    recorder.endRecording().dispose();
  });

  test('ui.Canvas rejects a recorder that is already recording', () {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);

    expect(
      () => ui.Canvas(recorder),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError e) => e.message,
          'message',
          '"recorder" must not already be associated with another Canvas.',
        ),
      ),
    );
    recorder.endRecording().dispose();
  });

  test('drawAtlas with empty colors draws the same pixels as null colors', () async {
    const green = ui.Color(0xFF00FF00);
    final ui.Image atlas = await drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint()..color = green);
    }).toImage(4, 4);

    Future<Uint8List> drawAtlasPixels(List<ui.Color>? colors) async {
      final ui.Picture picture = drawPicture((ui.Canvas canvas) {
        canvas.drawAtlas(
          atlas,
          <ui.RSTransform>[ui.RSTransform(1, 0, 2, 2)],
          const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
          colors,
          null,
          null,
          ui.Paint(),
        );
      });
      final ui.Image image = await picture.toImage(8, 8);
      final ByteData bytes = (await image.toByteData())!;
      image.dispose();
      picture.dispose();
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    }

    final Uint8List withNullColors = await drawAtlasPixels(null);
    final Uint8List withEmptyColors = await drawAtlasPixels(<ui.Color>[]);
    atlas.dispose();

    // The sprite covers (2, 2)-(6, 6) and is opaque green; the corner is blank.
    int offsetOf(int x, int y) => (y * 8 + x) * 4;
    expect(withNullColors.sublist(offsetOf(3, 3), offsetOf(3, 3) + 4), <int>[0, 255, 0, 255]);
    expect(withNullColors.sublist(offsetOf(0, 0), offsetOf(0, 0) + 4), <int>[0, 0, 0, 0]);
    expect(withEmptyColors, withNullColors);
  });

  test('drawPicture retains the image sources of the drawn picture', () async {
    final ui.Image image = await _createImageWithSource();
    final ImageSource? source = (image as EngineImage).imageSource;
    expect(source, isNotNull);

    final ui.Picture inner = drawPicture((ui.Canvas canvas) {
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    });
    final ui.Picture outer = drawPicture((ui.Canvas canvas) {
      canvas.drawPicture(inner);
    });

    final PictureImageTracker? tracker = (outer as LayerPicture).imageTracker;
    expect(tracker, isNotNull);
    expect(tracker!.isEmpty, isFalse);

    // Only the outer picture keeps the source alive now.
    image.dispose();
    inner.dispose();
    expect(source!.debugIsClosed, isFalse);

    outer.dispose();
    expect(source.debugIsClosed, isTrue);
  });

  test('a rejected call leaves the recording untouched', () async {
    final ui.Image image = await _createImageWithSource();
    final ImageSource source = (image as EngineImage).imageSource!;
    final shader = ui.ImageShader(image, ui.TileMode.clamp, ui.TileMode.clamp, _identity);
    final shaderPaint = ui.Paint()..shader = shader;
    const nanRect = ui.Rect.fromLTRB(double.nan, 0, 4, 4);
    final nanRSuperellipse = ui.RSuperellipse.fromLTRBR(
      double.nan,
      0,
      10,
      10,
      const ui.Radius.circular(2),
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTRB(0, 0, 8, 8));
    canvas.save();
    canvas.translate(1, 2);
    final Float64List transformBefore = canvas.getTransform();

    final rejectedCalls = <String, void Function()>{
      'transform': () => canvas.transform(Float64List(15)),
      'saveLayer': () => canvas.saveLayer(nanRect, shaderPaint),
      'clipRSuperellipse': () => canvas.clipRSuperellipse(nanRSuperellipse),
      'drawRSuperellipse': () => canvas.drawRSuperellipse(nanRSuperellipse, shaderPaint),
      'drawImage': () => canvas.drawImage(image, const ui.Offset(double.nan, 0), shaderPaint),
      'drawImageRect': () =>
          canvas.drawImageRect(image, const ui.Rect.fromLTRB(0, 0, 4, 4), nanRect, shaderPaint),
      'drawAtlas': () => canvas.drawAtlas(
        image,
        <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
        const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4), ui.Rect.fromLTRB(0, 0, 4, 4)],
        null,
        null,
        null,
        shaderPaint,
      ),
      'drawRawAtlas': () => canvas.drawRawAtlas(
        image,
        Float32List.fromList(<double>[1, 0, 0, 0]),
        Float32List.fromList(<double>[0, 0, 4, 4]),
        Int32List(2),
        ui.BlendMode.srcOver,
        null,
        shaderPaint,
      ),
      'drawPoints': () => canvas.drawPoints(ui.PointMode.points, const <ui.Offset>[
        ui.Offset(1, 1),
        ui.Offset(double.nan, 0),
      ], shaderPaint),
    };
    for (final MapEntry<String, void Function()>(key: String name, value: void Function() call)
        in rejectedCalls.entries) {
      expect(
        call,
        throwsA(anyOf(isA<ArgumentError>(), isA<AssertionError>())),
        reason: '$name was given invalid arguments and should be rejected upfront.',
      );
      expect(
        canvas.getSaveCount(),
        2,
        reason:
            'Validation runs before backend calls, so a rejected $name call must not alter the save stack.',
      );
      expect(
        canvas.getTransform(),
        transformBefore,
        reason:
            'Validation runs before backend calls, so a rejected $name call must not alter the transform.',
      );
    }
    canvas.restore();
    final ui.Picture picture = recorder.endRecording();

    // Nothing that was rejected may keep the image alive.
    expect((picture as LayerPicture).imageTracker, isNull);
    shader.dispose();
    image.dispose();
    expect(source.debugIsClosed, isTrue);
    picture.dispose();
  });

  group('the picture retains the image of a paint shader drawn with', () {
    late ui.Image drawnImage;

    setUpAll(() async {
      drawnImage = await drawPicture((ui.Canvas canvas) {
        canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint());
      }).toImage(4, 4);
    });

    tearDownAll(() {
      drawnImage.dispose();
    });

    const rect = ui.Rect.fromLTRB(0, 0, 4, 4);
    final cases = <String, void Function(ui.Canvas canvas, ui.Paint paint)>{
      'drawLine': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawLine(ui.Offset.zero, const ui.Offset(4, 4), paint),
      'drawPaint': (ui.Canvas canvas, ui.Paint paint) => canvas.drawPaint(paint),
      'drawRRect': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawRRect(ui.RRect.fromRectXY(rect, 1, 1), paint),
      'drawRSuperellipse': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawRSuperellipse(ui.RSuperellipse.fromRectXY(rect, 1, 1), paint),
      'drawDRRect': (ui.Canvas canvas, ui.Paint paint) => canvas.drawDRRect(
        ui.RRect.fromRectXY(rect, 1, 1),
        ui.RRect.fromRectXY(rect.deflate(1), 1, 1),
        paint,
      ),
      'drawOval': (ui.Canvas canvas, ui.Paint paint) => canvas.drawOval(rect, paint),
      'drawCircle': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawCircle(const ui.Offset(2, 2), 2, paint),
      'drawArc': (ui.Canvas canvas, ui.Paint paint) => canvas.drawArc(rect, 0, 1, true, paint),
      'drawPath': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawPath(ui.Path()..addRect(rect), paint),
      'drawPoints': (ui.Canvas canvas, ui.Paint paint) => canvas.drawPoints(
        ui.PointMode.lines,
        const <ui.Offset>[ui.Offset.zero, ui.Offset(4, 4)],
        paint,
      ),
      'drawRawPoints': (ui.Canvas canvas, ui.Paint paint) => canvas.drawRawPoints(
        ui.PointMode.polygon,
        Float32List.fromList(<double>[0, 0, 4, 4]),
        paint,
      ),
      'drawVertices': (ui.Canvas canvas, ui.Paint paint) {
        final vertices = ui.Vertices(ui.VertexMode.triangles, const <ui.Offset>[
          ui.Offset.zero,
          ui.Offset(4, 0),
          ui.Offset(0, 4),
        ]);
        canvas.drawVertices(vertices, ui.BlendMode.srcOver, paint);
        vertices.dispose();
      },
      'saveLayer without bounds': (ui.Canvas canvas, ui.Paint paint) => canvas
        ..saveLayer(null, paint)
        ..restore(),
      'saveLayerWithFilter': (ui.Canvas canvas, ui.Paint paint) => (canvas as LayerCanvas)
        ..saveLayerWithFilter(rect, paint, ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1))
        ..restore(),
      'drawImage': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawImage(drawnImage, ui.Offset.zero, paint),
      'drawImageRect': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawImageRect(drawnImage, rect, rect, paint),
      'drawImageNine': (ui.Canvas canvas, ui.Paint paint) =>
          canvas.drawImageNine(drawnImage, rect.deflate(1), rect, paint),
      'drawAtlas': (ui.Canvas canvas, ui.Paint paint) => canvas.drawAtlas(
        drawnImage,
        <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
        const <ui.Rect>[rect],
        null,
        null,
        null,
        paint,
      ),
      'drawRawAtlas': (ui.Canvas canvas, ui.Paint paint) => canvas.drawRawAtlas(
        drawnImage,
        Float32List.fromList(<double>[1, 0, 0, 0]),
        Float32List.fromList(<double>[0, 0, 4, 4]),
        null,
        null,
        null,
        paint,
      ),
    };
    for (final MapEntry<String, void Function(ui.Canvas, ui.Paint)>(
          key: String name,
          value: void Function(ui.Canvas, ui.Paint) draw,
        )
        in cases.entries) {
      test(name, () async {
        // Only the shader's image has a source, so only the paint can retain it.
        expect((drawnImage as EngineImage).imageSource, isNull);
        final ui.Image shaderImage = await _createImageWithSource();
        final ImageSource source = (shaderImage as EngineImage).imageSource!;
        final shader = ui.ImageShader(shaderImage, ui.TileMode.clamp, ui.TileMode.clamp, _identity);

        final ui.Picture picture = drawPicture((ui.Canvas canvas) {
          draw(canvas, ui.Paint()..shader = shader);
        });
        shader.dispose();
        shaderImage.dispose();
        expect(source.debugIsClosed, isFalse);

        picture.dispose();
        expect(source.debugIsClosed, isTrue);
      });
    }
  });

  test('empty points and atlases draw nothing and leave the canvas usable', () async {
    const green = ui.Color(0xFF00FF00);
    final ui.Image atlas = await drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint()..color = green);
    }).toImage(4, 4);

    final ui.Picture picture = drawPicture((ui.Canvas canvas) {
      final paint = ui.Paint()
        ..color = const ui.Color(0xFFFF0000)
        ..strokeWidth = 4;
      for (final ui.PointMode mode in ui.PointMode.values) {
        canvas.drawPoints(mode, const <ui.Offset>[], paint);
        canvas.drawRawPoints(mode, Float32List(0), paint);
      }
      canvas.drawAtlas(
        atlas,
        const <ui.RSTransform>[],
        const <ui.Rect>[],
        const <ui.Color>[],
        null,
        null,
        paint,
      );
      canvas.drawRawAtlas(
        atlas,
        Float32List(0),
        Float32List(0),
        Int32List(0),
        ui.BlendMode.srcOver,
        null,
        paint,
      );
      expect(canvas.getSaveCount(), 1);
      canvas.drawRect(const ui.Rect.fromLTRB(4, 4, 8, 8), ui.Paint()..color = green);
    });
    final ui.Image image = await picture.toImage(8, 8);
    final ByteData bytes = (await image.toByteData())!;
    image.dispose();
    picture.dispose();
    atlas.dispose();

    int pixelAt(int x, int y) => bytes.getUint32((y * 8 + x) * 4);
    expect(pixelAt(0, 0), 0x00000000);
    expect(pixelAt(2, 2), 0x00000000);
    expect(pixelAt(6, 6), 0x00FF00FF);
  });

  test('empty points and atlases do not retain image sources', () async {
    final ui.Image image = await _createImageWithSource();
    final ImageSource source = (image as EngineImage).imageSource!;
    final shader = ui.ImageShader(image, ui.TileMode.clamp, ui.TileMode.clamp, _identity);
    final shaderPaint = ui.Paint()..shader = shader;

    final emptyCalls = <String, void Function(ui.Canvas)>{
      'drawPoints': (ui.Canvas canvas) =>
          canvas.drawPoints(ui.PointMode.points, const <ui.Offset>[], shaderPaint),
      'drawRawPoints': (ui.Canvas canvas) =>
          canvas.drawRawPoints(ui.PointMode.points, Float32List(0), shaderPaint),
      'drawAtlas': (ui.Canvas canvas) => canvas.drawAtlas(
        image,
        const <ui.RSTransform>[],
        const <ui.Rect>[],
        const <ui.Color>[],
        null,
        null,
        shaderPaint,
      ),
      'drawRawAtlas': (ui.Canvas canvas) => canvas.drawRawAtlas(
        image,
        Float32List(0),
        Float32List(0),
        Int32List(0),
        ui.BlendMode.srcOver,
        null,
        shaderPaint,
      ),
    };

    final pictures = <ui.Picture>[];
    for (final MapEntry<String, void Function(ui.Canvas)>(
          key: String name,
          value: void Function(ui.Canvas) call,
        )
        in emptyCalls.entries) {
      final ui.Picture picture = drawPicture(call);
      expect((picture as LayerPicture).imageTracker, isNull, reason: name);
      pictures.add(picture);
    }

    shader.dispose();
    image.dispose();
    expect(source.debugIsClosed, isTrue);
    for (final picture in pictures) {
      picture.dispose();
    }
  });

  test('calls that fail unwrapping or in the backend do not retain image sources', () async {
    final ui.Image sourceDonor = await _createImageWithSource();
    final ImageSource foreignSource = (sourceDonor as EngineImage).imageSource!;
    final foreignImage = EngineImage(ForeignBackendImage(), 4, 4, imageSource: foreignSource);
    sourceDonor.dispose();
    expect(foreignSource.debugIsClosed, isFalse);

    final ui.Image shaderImage = await _createImageWithSource();
    final ImageSource shaderSource = (shaderImage as EngineImage).imageSource!;
    final shader = ui.ImageShader(shaderImage, ui.TileMode.clamp, ui.TileMode.clamp, _identity);
    final shaderPaint = ui.Paint()..shader = shader;

    final ui.Image pictureImage = await _createImageWithSource();
    final ImageSource pictureSource = (pictureImage as EngineImage).imageSource!;
    final foreignPictureTracker = PictureImageTracker()..recordImage(pictureImage);
    pictureImage.dispose();
    expect(pictureSource.debugIsClosed, isFalse);
    final foreignPicture = _ForeignLayerPicture(foreignPictureTracker);

    const rect = ui.Rect.fromLTRB(0, 0, 4, 4);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTRB(0, 0, 8, 8));

    final failingCalls = <String, void Function()>{
      'drawImage': () => canvas.drawImage(foreignImage, ui.Offset.zero, shaderPaint),
      'drawImageRect': () => canvas.drawImageRect(foreignImage, rect, rect, shaderPaint),
      'drawImageNine': () => canvas.drawImageNine(foreignImage, rect.deflate(1), rect, shaderPaint),
      'drawAtlas': () => canvas.drawAtlas(
        foreignImage,
        <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
        const <ui.Rect>[rect],
        null,
        null,
        null,
        shaderPaint,
      ),
      'drawRawAtlas': () => canvas.drawRawAtlas(
        foreignImage,
        Float32List.fromList(<double>[1, 0, 0, 0]),
        Float32List.fromList(<double>[0, 0, 4, 4]),
        null,
        null,
        null,
        shaderPaint,
      ),
      'saveLayerWithFilter (unwrap throws)': () =>
          (canvas as LayerCanvas).saveLayerWithFilter(rect, shaderPaint, _ThrowingImageFilter()),
      'saveLayerWithFilter (backend throws)': () =>
          (canvas as LayerCanvas).saveLayerWithFilter(rect, shaderPaint, ForeignImageFilter()),
      'drawPath': () => canvas.drawPath(ForeignPath(), shaderPaint),
      'drawVertices': () =>
          canvas.drawVertices(ForeignVertices(), ui.BlendMode.srcOver, shaderPaint),
      'drawPicture': () => canvas.drawPicture(foreignPicture),
    };

    for (final MapEntry<String, void Function()>(key: String name, value: void Function() call)
        in failingCalls.entries) {
      expect(
        call,
        throwsA(anyOf(isA<ArgumentError>(), isA<StateError>(), isA<TypeError>())),
        reason: name,
      );
    }

    final superellipseTracker = PictureImageTracker();
    final throwingCanvas = EngineCanvas(ThrowingBackendCanvas(), tracker: superellipseTracker);
    expect(
      () => throwingCanvas.drawRSuperellipse(ui.RSuperellipse.fromRectXY(rect, 1, 1), shaderPaint),
      throwsStateError,
    );
    expect(superellipseTracker.isEmpty, isTrue);

    final ui.Picture picture = recorder.endRecording();
    expect((picture as LayerPicture).imageTracker, isNull);

    foreignImage.dispose();
    expect(foreignSource.debugIsClosed, isTrue);

    shader.dispose();
    shaderImage.dispose();
    expect(shaderSource.debugIsClosed, isTrue);

    foreignPictureTracker.releaseAll();
    expect(pictureSource.debugIsClosed, isTrue);

    picture.dispose();
  });
}

class _ThrowingImageFilter extends EngineImageFilter {
  @override
  BackendImageFilter getBackendFilter({required ui.TileMode defaultBlurTileMode}) {
    throw StateError('filter failed');
  }
}

class _ForeignLayerPicture implements LayerPicture {
  _ForeignLayerPicture(this.imageTracker);

  @override
  final PictureImageTracker? imageTracker;

  @override
  bool get debugDisposed => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final Float64List _identity = Float64List.fromList(<double>[
  1, 0, 0, 0, //
  0, 1, 0, 0, //
  0, 0, 1, 0, //
  0, 0, 0, 1, //
]);

/// Creates an image backed by an [ImageSource], which pictures retain.
Future<ui.Image> _createImageWithSource() async {
  final ui.Image image = renderer.createImageFromImageBitmap(
    await createImageBitmap(createBlankDomImageData(4, 4)),
  );
  expect((image as EngineImage).imageSource, isNotNull);
  return image;
}
