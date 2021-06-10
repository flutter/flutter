// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';
import 'screenshot.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 500.0;
  const double screenHeight = 500.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  setUp(() async {
    debugEmulateFlutterTesterEnvironment = true;
    await webOnlyInitializePlatform();
    webOnlyFontCollection.debugRegisterTestFonts();
    await webOnlyFontCollection.ensureFontsLoaded();
  });

  test('Should blur rectangles based on sigma.', () async {
    final RecordingCanvas rc =
        RecordingCanvas(const Rect.fromLTRB(0, 0, 500, 500));
    for (int blurSigma = 1; blurSigma < 10; blurSigma += 2) {
      final SurfacePaint paint = SurfacePaint()
        ..color = Color(0xFF2fdfd2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma.toDouble());
      rc.drawRect(Rect.fromLTWH(15.0, 15.0 + blurSigma * 40, 200, 20), paint);
    }
    await canvasScreenshot(rc, 'dom_mask_filter_blur',
        region: screenRect,
        maxDiffRatePercent: 0.01);
  });
}
