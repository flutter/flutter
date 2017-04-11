// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAssetBundle extends CachingAssetBundle {
  Map<String, int> loadCallCount = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    loadCallCount[key] = loadCallCount[key] ?? 0 + 1;
    if (key == 'one')
      return new ByteData(1)..setInt8(0, 49);
    throw new FlutterError('key not found');
  }
}

void main() {
  test('Caching asset bundle test', () async {
    final TestAssetBundle bundle = new TestAssetBundle();

    final ByteData assetData = await bundle.load('one');
    expect(assetData.getInt8(0), equals(49));

    expect(bundle.loadCallCount['one'], 1);

    final String assetString = await bundle.loadString('one');
    expect(assetString, equals('1'));

    expect(bundle.loadCallCount['one'], 1);

    FlutterError loadException;
    try {
      await bundle.loadString('foo');
    } catch (e) {
      loadException = e;
    }
    expect(loadException, isFlutterError);
  });
}
