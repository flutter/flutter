// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('scene.pushImageFilter with a non-invertible matrix does not crash', () async {
    final sceneBuilder = ui.SceneBuilder();
    // A matrix of all zeros is non-invertible.
    final Float64List nonInvertibleMatrix = Matrix4.zero().toFloat64();
    final filter = ui.ImageFilter.matrix(nonInvertibleMatrix);

    sceneBuilder.pushImageFilter(filter);
    sceneBuilder.addPicture(
      ui.Offset.zero,
      drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 100, 100),
          ui.Paint()..color = const ui.Color(0xFF00FF00),
        );
      }),
    );
    sceneBuilder.pop();

    final ui.Scene scene = sceneBuilder.build();
    await renderScene(scene);
    // If we reached here without crashing, the test passed.
  });

  test('Paint with a non-invertible matrix ImageFilter does not crash', () async {
    final Float64List nonInvertibleMatrix = Matrix4.zero().toFloat64();
    final filter = ui.ImageFilter.matrix(nonInvertibleMatrix);

    final paint = ui.Paint()..imageFilter = filter;
    final ui.Picture picture = drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 100), paint);
    });

    final sceneBuilder = ui.SceneBuilder();
    sceneBuilder.addPicture(ui.Offset.zero, picture);
    final ui.Scene scene = sceneBuilder.build();
    await renderScene(scene);

    picture.dispose();
    // If we reached here without crashing, the test passed.
  });

  test('scene.pushImageFilter with a zero-scale matrix does not crash', () async {
    final sceneBuilder = ui.SceneBuilder();
    // A matrix with zero scale is non-invertible.
    final matrix = Matrix4.identity()..scale(0.0, 0.0, 1.0);
    final filter = ui.ImageFilter.matrix(matrix.toFloat64());

    sceneBuilder.pushImageFilter(filter);
    sceneBuilder.addPicture(
      ui.Offset.zero,
      drawPicture((ui.Canvas canvas) {
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 100, 100),
          ui.Paint()..color = const ui.Color(0xFF00FF00),
        );
      }),
    );
    sceneBuilder.pop();

    final ui.Scene scene = sceneBuilder.build();
    await renderScene(scene);
  });

  test('Paint with a zero-scale matrix ImageFilter does not crash', () async {
    final matrix = Matrix4.identity()..scale(0.0, 0.0, 1.0);
    final filter = ui.ImageFilter.matrix(matrix.toFloat64());

    final paint = ui.Paint()..imageFilter = filter;
    final ui.Picture picture = drawPicture((ui.Canvas canvas) {
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 100), paint);
    });

    final sceneBuilder = ui.SceneBuilder();
    sceneBuilder.addPicture(ui.Offset.zero, picture);
    final ui.Scene scene = sceneBuilder.build();
    await renderScene(scene);

    picture.dispose();
  });
}
