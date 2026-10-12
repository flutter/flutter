// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();

  test('clear removes registered typefaces before fonts are reloaded', () async {
    final ByteBuffer fontData = await httpFetchByteBuffer('/assets/fonts/ahem.ttf');
    final collection = SkwasmFontCollection();
    addTearDown(() {
      fontCollectionDispose(collection.handle);
      collection.defaultTextStyle.dispose();
      collection.registeredTypefaces.clear();
    });

    const fontFamily = 'TestFont';
    for (var cycle = 0; cycle < 3; cycle++) {
      for (var font = 0; font < 2; font++) {
        expect(
          await collection.loadFontFromBytes(fontData.asUint8List(), fontFamily: fontFamily),
          isTrue,
        );
      }
      expect(collection.registeredTypefaces.keys, <String>[fontFamily]);
      expect(collection.registeredTypefaces[fontFamily], hasLength(2));

      collection.clear();

      expect(collection.registeredTypefaces, isEmpty);
    }
  });
}
