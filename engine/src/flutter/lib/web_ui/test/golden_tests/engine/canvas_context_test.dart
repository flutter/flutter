// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart' as engine;

import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

/// Tests context save/restore.
void testMain() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(engine.RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500)}) async {
    final engine.EngineCanvas engineCanvas = engine.BitmapCanvas(screenRect);

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      // TODO(yjbanov): 10% diff rate is excessive. Update goldens.
      await matchGoldenFile('$fileName.png', region: region, maxDiffRatePercent: 10);
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  // Regression test for https://github.com/flutter/flutter/issues/49429
  // Should clip with correct transform.
  test('Clips image with oval clip path', () async {
    final engine.RecordingCanvas rc =
        engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    final Paint paint = Paint()
      ..color = Color(0xFF00FF00)
      ..style = PaintingStyle.fill;
    rc.save();
    final Path ovalPath = Path();
    ovalPath.addOval(Rect.fromLTWH(100, 30, 200, 100));
    rc.clipPath(ovalPath);
    rc.translate(-500, -500);
    rc.save();
    rc.translate(500, 500);
    rc.drawPath(ovalPath, paint);
    // The line below was causing SaveClipStack to incorrectly set
    // transform before path painting.
    rc.translate(-1000, -1000);
    rc.save();
    rc.restore();
    rc.restore();
    rc.restore();
    // The rectangle should paint without clipping since we restored
    // context.
    rc.drawRect(Rect.fromLTWH(0, 0, 4, 200), paint);
    await _checkScreenshot(rc, 'context_save_restore_transform');
  });

  test('Should restore clip path', () async {
    final engine.RecordingCanvas rc =
        engine.RecordingCanvas(const Rect.fromLTRB(0, 0, 400, 300));
    final Paint goodPaint = Paint()
      ..color = Color(0x8000FF00)
      ..style = PaintingStyle.fill;
    final Paint badPaint = Paint()
      ..color = Color(0xFFFF0000)
      ..style = PaintingStyle.fill;
    rc.save();
    final Path ovalPath = Path();
    ovalPath.addOval(Rect.fromLTWH(100, 30, 200, 100));
    rc.clipPath(ovalPath);
    rc.translate(-500, -500);
    rc.save();
    rc.restore();
    // The rectangle should be clipped against oval.
    rc.drawRect(Rect.fromLTWH(0, 0, 300, 300), badPaint);
    rc.restore();
    // The rectangle should paint without clipping since we restored
    // context.
    rc.drawRect(Rect.fromLTWH(0, 0, 200, 200), goodPaint);
    await _checkScreenshot(rc, 'context_save_restore_clip');
  });
}
