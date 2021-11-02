// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Assets', () {
    final String dataPath = globals.fs.path.join(
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
      final String manifestPath =
          globals.fs.path.join(dataPath, 'main', 'pubspec.yaml');
      final String packagesPath =
          globals.fs.path.join(dataPath, 'main', '.packages');
      await asset.build(
        manifestPath: manifestPath,
        packagesPath: packagesPath,
      );

      expect(asset.entries.containsKey('FontManifest.json'), isTrue);
      expect(
        await getValueAsString('FontManifest.json', asset),
        '[{"family":"packages/font/test_font","fonts":[{"asset":"packages/font/test_font_file"}]}]',
      );
      expect(asset.wasBuiltOnce(), true);
      expect(
        asset.inputFiles.map((File f) {
          return f.path;
        }),
        <String>[
          packagesPath,
          globals.fs.path.join(dataPath, 'font', 'pubspec.yaml'),
          manifestPath,
          globals.fs.path.join(dataPath, 'font', 'test_font_file'),
        ],
      );
    });

    testUsingContext('handles empty pubspec with .packages', () async {
      final String dataPath = globals.fs.path.join(
        getFlutterRoot(),
        'packages',
        'flutter_tools',
        'test',
        'data',
        'fuchsia_test',
      );
      final AssetBundle asset = AssetBundleFactory.instance.createBundle();
      await asset.build(
        manifestPath: globals.fs.path
            .join(dataPath, 'main', 'pubspec.yaml'), // file doesn't exist
        packagesPath: globals.fs.path.join(dataPath, 'main', '.packages'),
      );
      expect(asset.wasBuiltOnce(), true);
      expect(
        asset.inputFiles.map((File f) {
          return f.path;
        }),
        <String>[],
      );
    });
  });
}

Future<String> getValueAsString(String key, AssetBundle asset) async {
  return String.fromCharCodes(await asset.entries[key].contentsAsBytes());
}
