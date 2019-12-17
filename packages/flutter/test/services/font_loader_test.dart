// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFontLoader extends FontLoader {
  TestFontLoader(String family) : super(family);

  @override
  Future<void> loadFont(Uint8List list, String family) async {
    fontAssets.add(list);
  }

  List<Uint8List> fontAssets = <Uint8List>[];
}

void main() {
  test('Font loader test', () async {
    final TestFontLoader tfl = TestFontLoader('TestFamily');

    final List<Uint8List> expectedAssets = <Uint8List>[
      Uint8List.fromList(<int>[100]),
      Uint8List.fromList(<int>[10, 20, 30]),
      Uint8List.fromList(<int>[200]),
    ];

    for (Uint8List asset in expectedAssets) {
      tfl.addFont(Future<ByteData>.value(ByteData.view(asset.buffer)));
    }
    await tfl.load();

    expect(tfl.fontAssets, unorderedEquals(expectedAssets));
  });

  test('Font loader notifies system channel to rebuild', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    bool notifiedRebuild = false;
    PaintingBinding.instance.systemFonts.addListener(() {
      notifiedRebuild = true;
    });
    final TestFontLoader tfl = TestFontLoader('TestFamily');

    final List<Uint8List> expectedAssets = <Uint8List>[
      Uint8List.fromList(<int>[100]),
      Uint8List.fromList(<int>[10, 20, 30]),
      Uint8List.fromList(<int>[200]),
    ];

    for (Uint8List asset in expectedAssets) {
      tfl.addFont(Future<ByteData>.value(ByteData.view(asset.buffer)));
    }
    expect(notifiedRebuild, false);
    await tfl.load();
    expect(notifiedRebuild, true);
  });
}
