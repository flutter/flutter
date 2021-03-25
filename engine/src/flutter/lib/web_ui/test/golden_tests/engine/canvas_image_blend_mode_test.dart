// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' hide TextStyle;
import 'package:ui/src/engine.dart';

import 'package:web_engine_tester/golden_tester.dart';

import 'testimage.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  const double screenWidth = 600.0;
  const double screenHeight = 800.0;
  const Rect screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);

  // Commit a recording canvas to a bitmap, and compare with the expected
  Future<void> _checkScreenshot(RecordingCanvas rc, String fileName,
      {Rect region = const Rect.fromLTWH(0, 0, 500, 500),
        double maxDiffRatePercent = 0.0}) async {
    final EngineCanvas engineCanvas = BitmapCanvas(screenRect,
        RenderStrategy());

    rc.endRecording();
    rc.apply(engineCanvas, screenRect);

    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(engineCanvas.rootElement);
      html.document.body.append(sceneElement);
      await matchGoldenFile('$fileName.png', region: region, maxDiffRatePercent: maxDiffRatePercent);
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

  const Color red = Color(0xFFFF0000);
  const Color green = Color(0xFF00FF00);
  const Color blue = Color(0xFF2196F3);
  const Color white = Color(0xFFFFFFFF);
  const Color grey = Color(0xFF808080);
  const Color black = Color(0xFF000000);

  List<List<BlendMode>> modes = [[BlendMode.clear, BlendMode.src, BlendMode.dst,
    BlendMode.srcOver, BlendMode.dstOver, BlendMode.srcIn, BlendMode.dstIn, BlendMode.srcOut],
    [BlendMode.dstOut, BlendMode.srcATop, BlendMode.dstATop, BlendMode.xor,
    BlendMode.plus, BlendMode.modulate, BlendMode.screen, BlendMode.overlay],
    [BlendMode.darken, BlendMode.lighten, BlendMode.colorDodge, BlendMode.hardLight,
    BlendMode.softLight, BlendMode.difference, BlendMode.exclusion, BlendMode.multiply],
    [BlendMode.hue, BlendMode.saturation, BlendMode.color,
    BlendMode.luminosity]];

  for (int blendGroup = 0; blendGroup < 4; ++blendGroup) {
    test('Draw image with Group$blendGroup blend modes', () async {
      final RecordingCanvas rc = RecordingCanvas(
          const Rect.fromLTRB(0, 0, 400, 400));
      rc.save();
      List<BlendMode> blendModes = modes[blendGroup];
      for (int row = 0; row < blendModes.length; row++) {
        // draw white background for first 4, black for next 4 blends.
        double top = row * 50.0;
        rc.drawRect(Rect.fromLTWH(0, top, 200, 50), Paint()
          ..color = white);
        rc.drawRect(Rect.fromLTWH(200, top, 200, 50), Paint()
          ..color = grey);
        BlendMode blendMode = blendModes[row];
        rc.drawImage(createFlutterLogoTestImage(), Offset(0, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(red, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(50, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(green, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(100, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(blue, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(150, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(black, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(200, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(red, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(250, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(green, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(300, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(blue, blendMode));
        rc.drawImage(createFlutterLogoTestImage(), Offset(350, top),
            Paint()
              ..colorFilter = EngineColorFilter.mode(black, blendMode));
      }
      rc.restore();
      await _checkScreenshot(rc, 'canvas_image_blend_group$blendGroup',
          maxDiffRatePercent: 8.0);
    },
        skip: browserEngine == BrowserEngine.webkit &&
            operatingSystem == OperatingSystem.iOs);
  }

  // Regression test for https://github.com/flutter/flutter/issues/56971
  test('Draws image and paragraph at same vertical position', () async {
    final RecordingCanvas rc = RecordingCanvas(
        const Rect.fromLTRB(0, 0, 400, 400));
    rc.save();
    rc.drawRect(Rect.fromLTWH(0, 50, 200, 50), Paint()
      ..color = white);
    rc.drawImage(createFlutterLogoTestImage(), Offset(0, 50),
        Paint()
          ..colorFilter = EngineColorFilter.mode(red, BlendMode.srcIn));

    final Paragraph paragraph = createTestParagraph();
    const double textLeft = 80.0;
    const double textTop = 50.0;
    const double widthConstraint = 300.0;
    paragraph.layout(const ParagraphConstraints(width: widthConstraint));
    rc.drawParagraph(paragraph, const Offset(textLeft, textTop));

    rc.restore();
    await _checkScreenshot(rc, 'canvas_image_blend_and_text',
        maxDiffRatePercent: 8.0);
  });
}

Paragraph createTestParagraph() {
  final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
    fontFamily: 'Ahem',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  ));
  builder.addText('FOO');
  return builder.build();
}
