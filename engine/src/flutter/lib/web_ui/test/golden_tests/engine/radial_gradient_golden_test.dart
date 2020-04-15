// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

void main() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500),
      bool write = false}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect);
    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: region, write: write);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // golden screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  Future<void> _testGradient(String fileName, Shader shader,
      {Rect paintRect = const Rect.fromLTRB(50, 50, 300, 300),
      Rect shaderRect = const Rect.fromLTRB(50, 50, 300, 300)}) async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    final Paint paint = Paint()..shader = shader;
    final Path path = Path();
    path.addRect(paintRect);
    rc.drawPath(path, paint);
    await _checkScreenshot(rc, fileName);
  }

  test('Should draw centered radial gradient.', () async {
    Rect shaderRect = const Rect.fromLTRB(50, 50, 300, 300);
    await _testGradient(
        'radial_gradient_centered',
        Gradient.radial(
            Offset((shaderRect.left + shaderRect.right) / 2,
                (shaderRect.top + shaderRect.bottom) / 2),
            shaderRect.width / 2,
            [
              const Color.fromARGB(255, 0, 0, 0),
              const Color.fromARGB(255, 0, 0, 255)
            ]),
        shaderRect: shaderRect);
  });

  test('Should draw right bottom centered radial gradient.', () async {
    Rect shaderRect = const Rect.fromLTRB(50, 50, 300, 300);
    await _testGradient(
        'radial_gradient_right_bottom',
        Gradient.radial(
            Offset(shaderRect.right, shaderRect.bottom), shaderRect.width / 2, [
          const Color.fromARGB(255, 0, 0, 0),
          const Color.fromARGB(255, 0, 0, 255)
        ]),
        shaderRect: shaderRect);
  });

  test('Should draw with radial gradient with TileMode.clamp.', () async {
    Rect shaderRect = const Rect.fromLTRB(50, 50, 100, 100);
    await _testGradient(
        'radial_gradient_tilemode_clamp',
        Gradient.radial(
            Offset((shaderRect.left + shaderRect.right) / 2,
                (shaderRect.top + shaderRect.bottom) / 2),
            shaderRect.width / 2,
            [
              const Color.fromARGB(255, 0, 0, 0),
              const Color.fromARGB(255, 0, 0, 255)
            ],
            <double>[0.0, 1.0],
            TileMode.clamp),
        shaderRect: shaderRect);
  });
}
