// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';

import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  group('AssetBundle.build', () {
    // These tests do not use a memory file system because we want to ensure that
    // asset bundles work correctly on Windows and Posix systems.
    Directory tempDir;
    Directory oldCurrentDir;

    setUp(() async {
      tempDir = await fs.systemTempDirectory.createTemp('asset_bundle_tests');
      oldCurrentDir = fs.currentDirectory;
      fs.currentDirectory = tempDir;
    });

    tearDown(() {
      fs.currentDirectory = oldCurrentDir;
      try {
        tempDir?.deleteSync(recursive: true);
        tempDir = null;
      } on FileSystemException catch (e) {
        // Do nothing, windows sometimes has trouble deleting.
        print('Ignored exception during tearDown: $e');
      }
    });

    testUsingContext('nonempty', () async {
      final AssetBundle ab = AssetBundleFactory.instance.createBundle();
      expect(await ab.build(), 0);
      expect(ab.entries.length, greaterThan(0));
    });

    testUsingContext('empty pubspec', () async {
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('');

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      expect(bundle.entries.length, 1);
      const String expectedAssetManifest = '{}';
      expect(
        utf8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
        expectedAssetManifest,
      );
    });
  });

}
