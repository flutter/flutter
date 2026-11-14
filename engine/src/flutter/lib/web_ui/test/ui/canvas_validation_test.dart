// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

typedef _CanvasCall = void Function(ui.Canvas canvas);

/// Matches an [ArgumentError] with the given [message].
Matcher _throwsArgumentError(String message) =>
    throwsA(isA<ArgumentError>().having((ArgumentError e) => e.message, 'message', message));

/// Matches an [AssertionError] with an optional [message].
///
/// Asserts such as `assert(!image.debugDisposed)` have no message, so
/// [message] is null for them.
Matcher _throwsAssertionError([String? message]) =>
    throwsA(isA<AssertionError>().having((AssertionError e) => e.message, 'message', message));

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  final paint = ui.Paint();
  late ui.Image atlas;
  late ui.Image disposedImage;
  late ui.Paragraph disposedParagraph;
  late ui.Vertices disposedVertices;
  late ui.Picture disposedPicture;

  setUpAll(() async {
    Future<ui.Image> createImage() => drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint());
    }).toImage(4, 4);

    atlas = await createImage();
    disposedImage = await createImage()
      ..dispose();
    disposedParagraph =
        (ui.ParagraphBuilder(
            ui.ParagraphStyle(fontFamily: 'Ahem', fontSize: 10),
          )..addText('A')).build()
          ..layout(const ui.ParagraphConstraints(width: 100))
          ..dispose();
    disposedVertices = ui.Vertices(ui.VertexMode.triangles, const <ui.Offset>[
      ui.Offset.zero,
      ui.Offset(10, 0),
      ui.Offset(0, 10),
    ])..dispose();
    disposedPicture = drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint());
    })..dispose();
  });

  tearDownAll(() {
    atlas.dispose();
  });

  /// Records [call] into a fresh canvas, expects it to throw [matcher], and
  /// checks that the recording can still be ended and disposed.
  void expectThrowsAndRecordingSurvives(_CanvasCall call, Matcher matcher) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    expect(() => call(canvas), matcher);
    recorder.endRecording().dispose();
  }

  group('ui.Canvas throws ArgumentError on invalid inputs', () {
    final cases = <(String, _CanvasCall, String)>[
      (
        'transform with 15 entries',
        (ui.Canvas canvas) => canvas.transform(Float64List(15)),
        '"matrix4" must have 16 entries.',
      ),
      (
        'transform with 17 entries',
        (ui.Canvas canvas) => canvas.transform(Float64List(17)),
        '"matrix4" must have 16 entries.',
      ),
      (
        'drawRawPoints with an odd number of values',
        (ui.Canvas canvas) => canvas.drawRawPoints(ui.PointMode.points, Float32List(5), paint),
        '"points" must have an even number of values.',
      ),
      (
        'drawAtlas with 2 transforms and 1 rect',
        (ui.Canvas canvas) => canvas.drawAtlas(
          atlas,
          <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0), ui.RSTransform(1, 0, 4, 0)],
          const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
          null,
          null,
          null,
          paint,
        ),
        '"transforms" and "rects" lengths must match.',
      ),
      (
        'drawAtlas with 2 colors for 1 sprite',
        (ui.Canvas canvas) => canvas.drawAtlas(
          atlas,
          <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
          const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
          const <ui.Color>[ui.Color(0xFFFF0000), ui.Color(0xFF00FF00)],
          ui.BlendMode.srcOver,
          null,
          paint,
        ),
        'If non-null, "colors" length must match that of "transforms" and "rects".',
      ),
      (
        'drawAtlas with non-empty colors for 0 sprites',
        (ui.Canvas canvas) => canvas.drawAtlas(
          atlas,
          const <ui.RSTransform>[],
          const <ui.Rect>[],
          const <ui.Color>[ui.Color(0xFFFF0000)],
          ui.BlendMode.srcOver,
          null,
          paint,
        ),
        'If non-null, "colors" length must match that of "transforms" and "rects".',
      ),
      (
        'drawRawAtlas with mismatched lengths',
        (ui.Canvas canvas) => canvas.drawRawAtlas(
          atlas,
          Float32List.fromList(<double>[1, 0, 0, 0, 1, 0, 4, 0]),
          Float32List.fromList(<double>[0, 0, 4, 4]),
          null,
          null,
          null,
          paint,
        ),
        '"rstTransforms" and "rects" lengths must match.',
      ),
      (
        'drawRawAtlas with a length that is not a multiple of four',
        (ui.Canvas canvas) => canvas.drawRawAtlas(
          atlas,
          Float32List.fromList(<double>[1, 0, 0, 0, 1, 0]),
          Float32List.fromList(<double>[0, 0, 4, 4, 0, 0]),
          null,
          null,
          null,
          paint,
        ),
        '"rstTransforms" and "rects" lengths must be a multiple of four.',
      ),
      (
        'drawRawAtlas with 2 colors for 1 sprite',
        (ui.Canvas canvas) => canvas.drawRawAtlas(
          atlas,
          Float32List.fromList(<double>[1, 0, 0, 0]),
          Float32List.fromList(<double>[0, 0, 4, 4]),
          Int32List.fromList(<int>[0xFFFF0000, 0xFF00FF00]),
          ui.BlendMode.srcOver,
          null,
          paint,
        ),
        'If non-null, "colors" length must be one fourth the length of "rstTransforms" and "rects".',
      ),
      (
        'drawRawAtlas with non-empty colors for 0 sprites',
        (ui.Canvas canvas) => canvas.drawRawAtlas(
          atlas,
          Float32List(0),
          Float32List(0),
          Int32List.fromList(<int>[0xFFFF0000]),
          ui.BlendMode.srcOver,
          null,
          paint,
        ),
        'If non-null, "colors" length must be one fourth the length of "rstTransforms" and "rects".',
      ),
    ];
    for (final (String name, _CanvasCall call, String message) in cases) {
      test(name, () {
        expectThrowsAndRecordingSurvives(call, _throwsArgumentError(message));
      });
    }
  });

  group('ui.Canvas asserts on invalid inputs', () {
    const nanRect = ui.Rect.fromLTRB(double.nan, 0, 10, 10);
    final cases = <(String, _CanvasCall, String?)>[
      (
        'drawRect with a NaN rect',
        (ui.Canvas canvas) => canvas.drawRect(nanRect, paint),
        'Rect argument contained a NaN value.',
      ),
      (
        'clipRRect with a NaN rrect',
        (ui.Canvas canvas) => canvas.clipRRect(
          ui.RRect.fromLTRBR(double.nan, 0, 10, 10, const ui.Radius.circular(2)),
        ),
        'RRect argument contained a NaN value.',
      ),
      (
        'drawCircle with a NaN center',
        (ui.Canvas canvas) => canvas.drawCircle(const ui.Offset(double.nan, 0), 1, paint),
        'Offset argument contained a NaN value.',
      ),
      (
        'drawArc with a NaN rect',
        (ui.Canvas canvas) => canvas.drawArc(nanRect, 0, 1, true, paint),
        'Rect argument contained a NaN value.',
      ),
      (
        'clipRSuperellipse with a NaN rsuperellipse',
        (ui.Canvas canvas) => canvas.clipRSuperellipse(
          ui.RSuperellipse.fromLTRBR(double.nan, 0, 10, 10, const ui.Radius.circular(2)),
        ),
        'RSuperellipse argument contained a NaN value.',
      ),
      (
        'drawPoints with a NaN point',
        (ui.Canvas canvas) => canvas.drawPoints(ui.PointMode.points, const <ui.Offset>[
          ui.Offset(double.nan, 0),
        ], paint),
        'Offset argument contained a NaN value.',
      ),
      (
        'drawImage with a disposed image',
        (ui.Canvas canvas) => canvas.drawImage(disposedImage, ui.Offset.zero, paint),
        null,
      ),
      (
        'drawParagraph with a disposed paragraph',
        (ui.Canvas canvas) => canvas.drawParagraph(disposedParagraph, ui.Offset.zero),
        null,
      ),
      (
        'drawVertices with disposed vertices',
        (ui.Canvas canvas) => canvas.drawVertices(disposedVertices, ui.BlendMode.src, paint),
        null,
      ),
      (
        'drawAtlas with a disposed atlas',
        (ui.Canvas canvas) => canvas.drawAtlas(
          disposedImage,
          <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
          const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
          null,
          null,
          null,
          paint,
        ),
        null,
      ),
      (
        'drawAtlas with a disposed atlas and 0 sprites',
        (ui.Canvas canvas) => canvas.drawAtlas(
          disposedImage,
          const <ui.RSTransform>[],
          const <ui.Rect>[],
          null,
          null,
          null,
          paint,
        ),
        null,
      ),
      (
        'drawRawAtlas with a disposed atlas',
        (ui.Canvas canvas) => canvas.drawRawAtlas(
          disposedImage,
          Float32List.fromList(<double>[1, 0, 0, 0]),
          Float32List.fromList(<double>[0, 0, 4, 4]),
          null,
          null,
          null,
          paint,
        ),
        null,
      ),
      (
        'drawRawAtlas with a disposed atlas and 0 sprites',
        (ui.Canvas canvas) => canvas.drawRawAtlas(
          disposedImage,
          Float32List(0),
          Float32List(0),
          null,
          null,
          null,
          paint,
        ),
        null,
      ),
      (
        'drawPicture with a disposed picture',
        (ui.Canvas canvas) => canvas.drawPicture(disposedPicture),
        null,
      ),
      (
        'drawAtlas with colors and a null blendMode',
        (ui.Canvas canvas) => canvas.drawAtlas(
          atlas,
          <ui.RSTransform>[ui.RSTransform(1, 0, 0, 0)],
          const <ui.Rect>[ui.Rect.fromLTRB(0, 0, 4, 4)],
          const <ui.Color>[ui.Color(0xFFFF0000)],
          null,
          null,
          paint,
        ),
        null,
      ),
    ];
    for (final (String name, _CanvasCall call, String? message) in cases) {
      test(name, () {
        expectThrowsAndRecordingSurvives(call, _throwsAssertionError(message));
      });
    }
  });
}
