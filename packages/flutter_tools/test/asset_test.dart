// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('Assets', () {
    final String dataPath = fs.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'test',
      'data',
      'asset_test',
    );

    setUpAll(() {
      Cache.disableLocking();
    });

    // This test intentionally does not use a memory file system to ensure
    // that AssetBundle with fonts also works on Windows.
    testUsingContext('app font uses local font file', () async {
      final AssetBundle asset = AssetBundleFactory.instance.createBundle();
      await asset.build(
        manifestPath : fs.path.join(dataPath, 'main', 'pubspec.yaml'),
        packagesPath: fs.path.join(dataPath, 'main', '.packages'),
        includeDefaultFonts: false,
      );

      expect(asset.entries.containsKey('FontManifest.json'), isTrue);
      expect(
        await getValueAsString('FontManifest.json', asset),
        '[{"family":"packages/font/test_font","fonts":[{"asset":"packages/font/test_font_file"}]}]',
      );
    });

  });
}

Future<String> getValueAsString(String key, AssetBundle asset) async {
  return String.fromCharCodes(await asset.entries[key].contentsAsBytes());
}
