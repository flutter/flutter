// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:convert';
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
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/56702
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
        skip: (browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit));

    test('loads Blehm font from buffer', () async {
      expect(_containsFontFamily('Blehm'), false);

      final html.HttpRequest response = await html.HttpRequest.request(
          _testFontUrl,
          responseType: 'arraybuffer');
      await ui.loadFontFromList(Uint8List.view(response.response),
          fontFamily: 'Blehm');

      expect(_containsFontFamily('Blehm'), true);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/56702
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
        skip: (browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit));

    test('loading font should clear measurement caches', () async {
      final ui.ParagraphStyle style = ui.ParagraphStyle();
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(style);
      final ui.ParagraphConstraints constraints =
          ui.ParagraphConstraints(width: 30.0);
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
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/56702
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
        skip: (browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit));

    test('loading font should send font change message', () async {
      final ui.PlatformMessageCallback oldHandler = ui.window.onPlatformMessage;
      String actualName;
      String message;
      window.onPlatformMessage = (String name, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        actualName = name;
        final buffer = data.buffer;
        final Uint8List list =
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        message = utf8.decode(list);
      };
      final html.HttpRequest response = await html.HttpRequest.request(
          _testFontUrl,
          responseType: 'arraybuffer');
      await ui.loadFontFromList(Uint8List.view(response.response),
          fontFamily: 'Blehm');
      final Completer<void> completer = Completer();
      html.window.requestAnimationFrame( (_) { completer.complete(true); } );
      await(completer.future);
      window.onPlatformMessage = oldHandler;
      expect(actualName, 'flutter/system');
      expect(message, '{"type":"fontsChange"}');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/56702
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
        skip: (browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit));
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
