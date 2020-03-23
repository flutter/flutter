// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:test/test.dart';

import 'package:web_engine_tester/golden_tester.dart';

/// Class that controls some details of how screenshotting is made.
///
/// (For Googlers: Not really related with internal Scuba anymore)
class EngineScubaTester {
  /// The size of the browser window used in this scuba test.
  final ui.Size viewportSize;

  EngineScubaTester(this.viewportSize);

  static Future<EngineScubaTester> initialize(
      {ui.Size viewportSize = const ui.Size(2400, 1800)}) async {
    assert(viewportSize != null);

    assert(() {
      if (viewportSize.width.ceil() != viewportSize.width ||
          viewportSize.height.ceil() != viewportSize.height) {
        throw Exception(
            'Scuba only supports integer screen sizes, but found: $viewportSize');
      }
      if (viewportSize.width < 472) {
        throw Exception('Scuba does not support screen width smaller than 472');
      }
      return true;
    }());

    return EngineScubaTester(viewportSize);
  }

  ui.Rect get viewportRegion =>
      ui.Rect.fromLTWH(0, 0, viewportSize.width, viewportSize.height);

  Future<void> diffScreenshot(
    String fileName, {
    ui.Rect region,
    double maxDiffRatePercent,
  }) async {
    await matchGoldenFile(
      '$fileName.png',
      region: region ?? viewportRegion,
      maxDiffRatePercent: maxDiffRatePercent,
    );
  }

  /// Prepares the DOM and inserts all the necessary nodes, then invokes scuba's
  /// screenshot diffing.
  ///
  /// It also cleans up the DOM after itself.
  Future<void> diffCanvasScreenshot(
    EngineCanvas canvas,
    String fileName, {
    ui.Rect region,
    double maxDiffRatePercent,
  }) async {
    // Wrap in <flt-scene> so that our CSS selectors kick in.
    final html.Element sceneElement = html.Element.tag('flt-scene');
    try {
      sceneElement.append(canvas.rootElement);
      html.document.body.append(sceneElement);
      String screenshotName = '${fileName}_${canvas.runtimeType}';
      if (WebExperiments.instance.useCanvasText) {
        screenshotName += '+canvas_measurement';
      }
      await diffScreenshot(
        screenshotName,
        region: region,
        maxDiffRatePercent: maxDiffRatePercent,
      );
    } finally {
      // The page is reused across tests, so remove the element after taking the
      // Scuba screenshot.
      sceneElement.remove();
    }
  }
}

typedef CanvasTest = FutureOr<void> Function(EngineCanvas canvas);

/// Runs the given test [body] with each type of canvas.
void testEachCanvas(String description, CanvasTest body,
    {double maxDiffRate, bool bSkipHoudini = false}) {
  const ui.Rect bounds = ui.Rect.fromLTWH(0, 0, 600, 800);
  test('$description (bitmap)', () {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      WebExperiments.instance.useCanvasText = false;
      return body(BitmapCanvas(bounds));
    } finally {
      WebExperiments.instance.useCanvasText = null;
      TextMeasurementService.clearCache();
    }
  });
  test('$description (bitmap + canvas measurement)', () async {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      WebExperiments.instance.useCanvasText = true;
      await body(BitmapCanvas(bounds));
    } finally {
      WebExperiments.instance.useCanvasText = null;
      TextMeasurementService.clearCache();
    }
  });
  test('$description (dom)', () {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      return body(DomCanvas());
    } finally {
      TextMeasurementService.clearCache();
    }
  });
  if (!bSkipHoudini) {
    test('$description (houdini)', () {
      try {
        TextMeasurementService.initialize(rulerCacheCapacity: 2);
        return body(HoudiniCanvas(bounds));
      } finally {
        TextMeasurementService.clearCache();
      }
    });
  }
}

final ui.TextStyle _defaultTextStyle = ui.TextStyle(
  color: const ui.Color(0xFF000000),
  fontFamily: 'Roboto',
  fontSize: 14,
);

ui.Paragraph paragraph(
  String text, {
  ui.ParagraphStyle paragraphStyle,
  ui.TextStyle textStyle,
  double maxWidth = double.infinity,
}) {
  final ui.ParagraphBuilder builder =
      ui.ParagraphBuilder(paragraphStyle ?? ui.ParagraphStyle());
  builder.pushStyle(textStyle ?? _defaultTextStyle);
  builder.addText(text);
  builder.pop();
  return builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
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
