// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

ui.Image createTestImage(int width, int height, ui.Color color) {
  final ui.Paint paint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = color;
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas pictureCanvas = ui.Canvas(recorder);
  pictureCanvas.drawCircle(Offset.zero, 20.0, paint);
  final ui.Picture picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void main() {
  const ui.Color red = ui.Color.fromARGB(255, 255, 0, 0);
  const ui.Color green = ui.Color.fromARGB(255, 0, 255, 0);
  const ui.Color transparentRed = ui.Color.fromARGB(128, 255, 0, 0);

  group('succeeds', () {
    testWidgets('when images have the same content', (WidgetTester tester) async {
      await expectLater(
        createTestImage(100, 100, red),
        matchesReferenceImage(createTestImage(100, 100, red)),
      );
      await expectLater(
        createTestImage(100, 100, green),
        matchesReferenceImage(createTestImage(100, 100, green)),
      );

      await expectLater(
        createTestImage(100, 100, transparentRed),
        matchesReferenceImage(createTestImage(100, 100, transparentRed)),
      );
    });

    testWidgets('when images are identical', (WidgetTester tester) async {
      final ui.Image image = createTestImage(100, 100, red);
      await expectLater(image, matchesReferenceImage(image));
    });
  });

  group('fails', () {
    testWidgets('when image sizes do not match', (WidgetTester tester) async {
      expect(
        await matchesReferenceImage(createTestImage(50, 50, red)).matchAsync(createTestImage(100, 100, red)),
        equals('does not match as width or height do not match. [100×100] != [50×50]'),
      );
    });

    testWidgets('when image pixels do not match', (WidgetTester tester) async {
      expect(
        await matchesReferenceImage(createTestImage(100, 100, red)).matchAsync(createTestImage(100, 100, transparentRed)),
        equals('does not match on 57 pixels'),
      );
      expect(
        await matchesReferenceImage(createTestImage(100, 100, red)).matchAsync(createTestImage(100, 100, green)),
        equals('does not match on 57 pixels'),
      );
    });
  });
}
