// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('Renders image from encoded bytes in CPU-only mode', () async {
    debugOverrideJsConfiguration(JsFlutterConfiguration(canvasKitForceCpuOnly: true));

    // A 1x1 yellow PNG image.
    const kBase64Png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
    final Uint8List bytes = base64.decode(kBase64Png);

    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 10, 10));

    // Draw the image scaled up so we can see it
    canvas.drawImageRect(
      image,
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      const ui.Rect.fromLTWH(0, 0, 10, 10),
      ui.Paint(),
    );

    await drawPictureUsingCurrentRenderer(recorder.endRecording());

    await matchGoldenFile('image_cpu_only.png', region: const ui.Rect.fromLTWH(0, 0, 10, 10));

    debugOverrideJsConfiguration(null); // Reset configuration
  });

  test('Renders image from URL in CPU-only mode', () async {
    debugOverrideJsConfiguration(JsFlutterConfiguration(canvasKitForceCpuOnly: true));

    final Uri uri = Uri.base.resolve('/test/ui/image/sample_image1.png');
    final ui.Codec codec = await ui_web.createImageCodecFromUrl(uri);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 100, 100));

    // Draw the image
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    await drawPictureUsingCurrentRenderer(recorder.endRecording());

    await matchGoldenFile('image_cpu_only_url.png', region: const ui.Rect.fromLTWH(0, 0, 100, 100));

    debugOverrideJsConfiguration(null); // Reset configuration
  });
}
