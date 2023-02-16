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

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  await initializeTestFlutterViewEmbedder();
  group('loadFontFromList', () {
    const String testFontUrl = '/assets/fonts/ahem.ttf';

    tearDown(() {
      domDocument.fonts!.clear();
    });

    test('surfaces error from invalid font buffer', () async {
      await expectLater(
          ui.loadFontFromList(Uint8List(0), fontFamily: 'test-font'),
          throwsA(const TypeMatcher<Exception>()));
    },
        // TODO(hterkelsen): https://github.com/flutter/flutter/issues/56702
        skip: browserEngine == BrowserEngine.webkit);

    test('loads Blehm font from buffer', () async {
      expect(_containsFontFamily('Blehm'), isFalse);

      final ByteBuffer response = await httpFetchByteBuffer(testFontUrl);
      await ui.loadFontFromList(response.asUint8List(), fontFamily: 'Blehm');

      expect(_containsFontFamily('Blehm'), isTrue);
    },
        // TODO(hterkelsen): https://github.com/flutter/flutter/issues/56702
        skip: browserEngine == BrowserEngine.webkit);

    test('loading font should clear measurement caches', () async {
      final EngineParagraphStyle style = EngineParagraphStyle();
      const ui.ParagraphConstraints constraints =
          ui.ParagraphConstraints(width: 30.0);

      final CanvasParagraphBuilder canvasBuilder = CanvasParagraphBuilder(style);
      canvasBuilder.addText('test');
      // Triggers the measuring and verifies the ruler cache has been populated.
      canvasBuilder.build().layout(constraints);
      expect(Spanometer.rulers.length, 1);

      // Now, loads a new font using loadFontFromList. This should clear the
      // cache
      final ByteBuffer response = await httpFetchByteBuffer(testFontUrl);
      await ui.loadFontFromList(response.asUint8List(), fontFamily: 'Blehm');

      // Verifies the font is loaded, and the cache is cleaned.
      expect(_containsFontFamily('Blehm'), isTrue);
      expect(Spanometer.rulers.length, 0);
    },
        // TODO(hterkelsen): https://github.com/flutter/flutter/issues/56702
        skip: browserEngine == BrowserEngine.webkit);

    test('loading font should send font change message', () async {
      final ui.PlatformMessageCallback? oldHandler = ui.window.onPlatformMessage;
      String? actualName;
      String? message;
      window.onPlatformMessage = (String name, ByteData? data,
          ui.PlatformMessageResponseCallback? callback) {
        actualName = name;
        final ByteBuffer buffer = data!.buffer;
        final Uint8List list =
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        message = utf8.decode(list);
      };
      final ByteBuffer response = await httpFetchByteBuffer(testFontUrl);
      await ui.loadFontFromList(response.asUint8List(), fontFamily: 'Blehm');
      final Completer<void> completer = Completer<void>();
      domWindow.requestAnimationFrame(allowInterop((_) { completer.complete();}) );
      await completer.future;
      window.onPlatformMessage = oldHandler;
      expect(actualName, 'flutter/system');
      expect(message, '{"type":"fontsChange"}');
    },
        // TODO(hterkelsen): https://github.com/flutter/flutter/issues/56702
        skip: browserEngine == BrowserEngine.webkit);
  });
}

bool _containsFontFamily(String family) {
  bool found = false;
  domDocument.fonts!.forEach(allowInterop((DomFontFace fontFace,
      DomFontFace fontFaceAgain, DomFontFaceSet fontFaceSet) {
    if (fontFace.family == family) {
      found = true;
    }
  }));
  return found;
}
