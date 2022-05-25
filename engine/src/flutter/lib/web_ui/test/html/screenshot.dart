// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:web_engine_tester/golden_tester.dart';

/// Commit a recording canvas to a bitmap, and compare with the expected.
Future<void> canvasScreenshot(RecordingCanvas rc, String fileName,
    {ui.Rect region = const ui.Rect.fromLTWH(0, 0, 600, 800),
      double maxDiffRatePercent = 0.0, bool setupPerspective = false,
      bool write = false}) async {
  final EngineCanvas engineCanvas = BitmapCanvas(region,
      RenderStrategy());

  rc.endRecording();
  rc.apply(engineCanvas, region);

  // Wrap in <flt-scene> so that our CSS selectors kick in.
  final DomElement sceneElement = createDomElement('flt-scene');
  if (isIosSafari) {
    // Shrink to fit on the iPhone screen.
    sceneElement.style.position = 'absolute';
    sceneElement.style.transformOrigin = '0 0 0';
    sceneElement.style.transform = 'scale(0.3)';
  }
  try {
    if (setupPerspective) {
      // iFrame disables perspective, set it explicitly for test.
      engineCanvas.rootElement.style.perspective = '400px';
      for (final DomElement element in engineCanvas.rootElement.querySelectorAll('div')) {
        element.style.perspective = '400px';
      }
    }
    sceneElement.append(engineCanvas.rootElement);
    domDocument.body!.append(sceneElement);
    await matchGoldenFile('$fileName.png',
        region: region, maxDiffRatePercent: maxDiffRatePercent, write: write);
  } finally {
    // The page is reused across tests, so remove the element after taking the
    // Scuba screenshot.
    sceneElement.remove();
  }
}

Future<void> sceneScreenshot(SurfaceSceneBuilder sceneBuilder, String fileName,
    {ui.Rect region = const ui.Rect.fromLTWH(0, 0, 600, 800),
    double maxDiffRatePercent = 0.0, bool write = false}) async {
  DomElement? sceneElement;
  try {
    sceneElement = sceneBuilder
        .build()
        .webOnlyRootElement;
    domDocument.body!.append(sceneElement!);
    await matchGoldenFile('$fileName.png',
        region: region, maxDiffRatePercent: maxDiffRatePercent, write: write);
  } finally {
    // The page is reused across tests, so remove the element after taking the
    // Scuba screenshot.
    sceneElement?.remove();
  }
}


/// Configures the test to use bundled Roboto and Ahem fonts to avoid golden
/// screenshot differences due to differences in the preinstalled system fonts.
void setUpStableTestFonts() {
  setUpAll(() async {
    await ui.webOnlyInitializePlatform();
    fontCollection.debugRegisterTestFonts();
    await fontCollection.ensureFontsLoaded();
  });
}
