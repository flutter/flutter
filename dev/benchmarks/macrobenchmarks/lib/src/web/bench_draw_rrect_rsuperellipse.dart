// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'recorder.dart';

typedef _Draw = void Function(Canvas canvas, int key, Rect rect, Radius radius, Paint paint);

/// Repeatedly paints a grid of rounded rectangles or rounded superellipses.
///
/// Measures the performance of the `drawRSuperellipse` operation compared with `drawRRect`.
class BenchDrawRRectRSuperellipse extends SceneBuilderRecorder {
  /// A variant of the benchmark that draws rounded rectangles.
  ///
  /// This variant is used as a comparison benchmark for `drawRSuperellipse`.
  BenchDrawRRectRSuperellipse.drawRRect() : _draw = _drawRRect, super(name: drawRRectName);

  /// A variant of the benchmark that draws rounded superellipses.
  BenchDrawRRectRSuperellipse.drawRSuperellipse() : super(name: drawRSuperellipseName) {
    _draw = _drawRSuperellipse;
  }

  static const String drawRRectName = 'draw_rrect';
  static const String drawRSuperellipseName = 'draw_rsuperellipse';

  /// Number of rows in the grid.
  static const int kRows = 25;

  /// Number of columns in the grid.
  static const int kColumns = 40;

  late final _Draw _draw;

  static void _drawRRect(Canvas canvas, int key, Rect rect, Radius radius, Paint paint) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
  }

  static void _drawRSuperellipse(Canvas canvas, int key, Rect rect, Radius radius, Paint paint) {
    canvas.drawRSuperellipse(RSuperellipse.fromRectAndRadius(rect, radius), paint);
  }

  /// Counter used to offset the rendered rsuperellipse to make them wobble.
  ///
  /// The wobbling is there so a human could visually verify that the benchmark
  /// is correctly pumping frames.
  double wobbleCounter = 0;

  static final Paint _paint = Paint()..color = const Color.fromARGB(255, 255, 0, 0);

  @override
  void onDrawFrame(SceneBuilder sceneBuilder) {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final Size viewSize = view.physicalSize;

    final cellSize = Size(viewSize.width / kColumns, viewSize.height / kRows);
    final Size rectSize = cellSize * 0.8;
    final double maxRadius = rectSize.shortestSide / 2;

    for (var row = 0; row < kRows; row++) {
      canvas.save();
      for (var col = 0; col < kColumns; col++) {
        final double radius = maxRadius / kColumns * col;
        _draw(
          canvas,
          row * kColumns + col,
          Offset((wobbleCounter - 5).abs(), 0) & rectSize,
          Radius.circular(radius),
          _paint,
        );
        canvas.translate(cellSize.width, 0);
      }
      canvas.restore();
      canvas.translate(0, cellSize.height);
    }

    wobbleCounter += 1;
    wobbleCounter = wobbleCounter % 10;
    final Picture picture = pictureRecorder.endRecording();
    sceneBuilder.pushOffset(0.0, 0.0);
    sceneBuilder.addPicture(Offset.zero, picture);
    sceneBuilder.pop();
  }
}
