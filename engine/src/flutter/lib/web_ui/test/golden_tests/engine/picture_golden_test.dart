// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/test.dart';
import 'package:web_engine_tester/golden_tester.dart';

void main() {
  group('Picture', () {
    test('toImage produces an image', () async {
      final EnginePictureRecorder recorder = ui.PictureRecorder();
      final RecordingCanvas canvas = recorder.beginRecording(ui.Rect.fromLTRB(0, 0, 200, 100));
      canvas.drawCircle(
        const ui.Offset(100, 50),
        40,
        ui.Paint()
          ..color = ui.Color.fromARGB(255, 255, 100, 100),
      );
      final ui.Picture picture = recorder.endRecording();
      final HtmlImage image = await picture.toImage(200, 100);
      expect(image, isNotNull);
      html.document.body
        ..style.margin = '0'
        ..append(image.imgElement);
      try {
        await matchGoldenFile(
          'picture_to_image.png',
          region: ui.Rect.fromLTRB(0, 0, 200, 100),
        );
      } finally {
        image.imgElement.remove();
      }
    });
  });
}
