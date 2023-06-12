// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dwds/dwds.dart';
import 'package:test/test.dart';

import '../fixtures/context.dart';

void main() {
  final context = TestContext();
  ProxyServerAssetReader assetReader;
  setUpAll(() async {
    await context.setUp();
    assetReader = context.testServer.assetReader as ProxyServerAssetReader;
  });

  group('ProxyServerAssetReader', () {
    test('returns null if the dart path does not exist', () async {
      final result = await assetReader.dartSourceContents('some/path/foo.dart');
      expect(result, isNull);
    });

    test('can read dart sources', () async {
      final result =
          await assetReader.dartSourceContents('hello_world/main.dart');
      expect(result, isNotNull);
    });

    test('can read source maps', () async {
      final result = await assetReader
          .dartSourceContents('hello_world/main.unsound.ddc.js.map');
      expect(result, isNotNull);
    });

    test('returns null if the source map path does not exist', () async {
      final result = await assetReader
          .dartSourceContents('hello_world/foo.unsound.ddc.js.map');
      expect(result, isNull);
    });
  });
}
