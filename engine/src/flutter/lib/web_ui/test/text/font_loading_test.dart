// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

Future<void> main() async {
  await ui.webOnlyInitializeTestDomRenderer();
  group('loadFontFromList', () {
    const String _testFontUrl = 'packages/ui/assets/ahem.ttf';

    tearDown(() {
      html.document.fonts.clear();
    });

    test('surfaces error from invalid font buffer', () async {
      await expectLater(
          ui.loadFontFromList(Uint8List(0), fontFamily: 'test-font'),
          throwsA(TypeMatcher<Exception>()));
    });

    test('loads Blehm font from buffer', () async {
      expect(_containsFontFamily('Blehm'), false);

      final html.HttpRequest response = await html.HttpRequest.request(
          _testFontUrl,
          responseType: 'arraybuffer');
      await ui.loadFontFromList(Uint8List.view(response.response),
          fontFamily: 'Blehm');

      expect(_containsFontFamily('Blehm'), true);
    });

    test('loads font should clear measurement caches', () async {
      final ui.ParagraphStyle style = ui.ParagraphStyle();
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(style);
      final ui.ParagraphConstraints constraints = ui.ParagraphConstraints(width: 30.0);
      builder.addText('test');
      final ui.Paragraph paragraph = builder.build();
      // Triggers the measuring and verifies the result has been cached.
      paragraph.layout(constraints);
      expect(TextMeasurementService.rulerManager.rulers.length, 1);

      // Now, loads a new font using loadFontFromList. This should clear the
      // cache
      final html.HttpRequest response = await html.HttpRequest.request(
        _testFontUrl,
        responseType: 'arraybuffer');
      await ui.loadFontFromList(Uint8List.view(response.response),
        fontFamily: 'Blehm');

      // Verifies the font is loaded, and the cache is cleaned.
      expect(_containsFontFamily('Blehm'), true);
      expect(TextMeasurementService.rulerManager.rulers.length, 0);
    });
  });
}

bool _containsFontFamily(String family) {
  bool found = false;
  html.document.fonts.forEach((html.FontFace fontFace,
      html.FontFace fontFaceAgain, html.FontFaceSet fontFaceSet) {
    if (fontFace.family == family) {
      found = true;
    }
  });
  return found;
}
