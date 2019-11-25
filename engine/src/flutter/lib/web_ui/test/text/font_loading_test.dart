// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

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
