// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';
import 'package:web_engine_tester/golden_tester.dart';
import 'package:test/test.dart';

/// Commit a recording canvas to a bitmap, and compare with the expected.
Future<void> canvasScreenshot(RecordingCanvas rc, String fileName,
    {ui.Rect region = const ui.Rect.fromLTWH(0, 0, 600, 800),
      double maxDiffRatePercent = 0.0, bool write: false}) async {
  final EngineCanvas engineCanvas = BitmapCanvas(region);

  rc.endRecording();
  rc.apply(engineCanvas, region);

  // Wrap in <flt-scene> so that our CSS selectors kick in.
  final html.Element sceneElement = html.Element.tag('flt-scene');
  try {
    sceneElement.append(engineCanvas.rootElement);
    html.document.body.append(sceneElement);
    await matchGoldenFile('$fileName.png',
        region: region, maxDiffRatePercent: maxDiffRatePercent, write: write);
  } finally {
    // The page is reused across tests, so remove the element after taking the
    // Scuba screenshot.
    sceneElement.remove();
  }
}

/// Configures the test to use bundled Roboto and Ahem fonts to avoid golden
/// screenshot differences due to differences in the preinstalled system fonts.
void setUpStableTestFonts() {
  setUp(() async {
    await ui.webOnlyInitializePlatform();
    ui.webOnlyFontCollection.debugRegisterTestFonts();
    await ui.webOnlyFontCollection.ensureFontsLoaded();
  });
}
