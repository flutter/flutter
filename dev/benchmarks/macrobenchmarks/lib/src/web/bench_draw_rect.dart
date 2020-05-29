// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'recorder.dart';

/// Repeatedly paints a grid of rectangles.
///
/// Measures the performance of the `drawRect` operation.
class BenchDrawRect extends SceneBuilderRecorder {
  BenchDrawRect() : super(name: benchmarkName);

  static const String benchmarkName = 'draw_rect';

  /// Number of rows in the grid.
  static const int kRows = 25;

  /// Number of columns in the grid.
  static const int kColumns = 40;

  /// Counter used to offset the rendered rects to make them wobble.
  ///
  /// The wobbling is there so a human could visually verify that the benchmark
  /// is correctly pumping frames.
  double wobbleCounter = 0;

  @override
  void onDrawFrame(SceneBuilder sceneBuilder) {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = const Color.fromARGB(255, 255, 0, 0);
    final Size windowSize = window.physicalSize;

    final Size cellSize = Size(
      windowSize.width / kColumns,
      windowSize.height / kRows,
    );
    final Size rectSize = cellSize * 0.8;

    for (int row = 0; row < kRows; row++) {
      canvas.save();
      for (int col = 0; col < kColumns; col++) {
        canvas.drawRect(
          Offset((wobbleCounter - 5).abs(), 0) & rectSize,
          paint,
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
