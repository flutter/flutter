// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFontLoader extends FontLoader {
  TestFontLoader(super.family);

  @override
  Future<void> loadFont(Uint8List list, String family) async {
    fontAssets.add(list);
  }

  List<Uint8List> fontAssets = <Uint8List>[];
}

void main() {
  test('Font loader test', () async {
    final tfl = TestFontLoader('TestFamily');

    final expectedAssets = <Uint8List>[
      Uint8List.fromList(<int>[100]),
      Uint8List.fromList(<int>[10, 20, 30]),
      Uint8List.fromList(<int>[200]),
    ];

    for (final asset in expectedAssets) {
      tfl.addFont(Future<ByteData>.value(ByteData.view(asset.buffer)));
    }
    await tfl.load();

    expect(tfl.fontAssets, unorderedEquals(expectedAssets));
  });

  test('FontLoader loads fonts in order', () async {
    final tfl = TestFontLoader('TestFamily');

    final expectedAssets = <Uint8List>[
      Uint8List.fromList(<int>[1]),
      Uint8List.fromList(<int>[2]),
    ];
    final completer = Completer<void>();

    // Deliberately delay the load of the first font.
    tfl.addFont(() async {
      await completer.future;
      return ByteData.view(expectedAssets[0].buffer);
    }());
    tfl.addFont(Future<ByteData>.value(ByteData.view(expectedAssets[1].buffer)));

    final Future<void> fontLoadComplete = tfl.load();
    completer.complete();
    await fontLoadComplete;

    expect(tfl.fontAssets, equals(expectedAssets));
  });
}
