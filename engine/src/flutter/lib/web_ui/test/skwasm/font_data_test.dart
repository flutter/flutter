// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
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

  for (final isJsBacked in <bool>[false, true]) {
    for (final offset in <int>[0, 13]) {
      test('loads a ${isJsBacked ? 'JavaScript-backed' : 'Dart-allocated'} font view '
          'at offset $offset without modifying its backing buffer', () async {
        final Uint8List fontData = (await httpFetchByteBuffer('/assets/fonts/ahem.ttf'))
            .asUint8List();
        final int length = offset + fontData.length + 17;
        final Uint8List backing = isJsBacked
            ? JSUint8Array.withLength(length).toDart
            : Uint8List(length);
        backing.fillRange(0, backing.length, 0xa5);
        backing.setRange(offset, offset + fontData.length, fontData);
        final originalBytes = List<int>.of(backing);
        final fontView = Uint8List.sublistView(backing, offset, offset + fontData.length);

        final collection = SkwasmFontCollection();
        addTearDown(() {
          fontCollectionDispose(collection.handle);
          collection.defaultTextStyle.dispose();
          collection.registeredTypefaces.clear();
        });

        expect(await collection.loadFontFromBytes(fontView, fontFamily: 'TestFont'), isTrue);
        expect(backing, orderedEquals(originalBytes));
      });
    }
  }
}
