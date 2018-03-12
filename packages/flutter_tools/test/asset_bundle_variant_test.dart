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

  group('AssetBundle asset variants', () {
    testUsingContext('main asset and variants', () async {
      // Setting flutterRoot here so that it picks up the MemoryFileSystem's
      // path separator.
      Cache.flutterRoot = getFlutterRoot();

      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(
'''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - a/b/c/foo
'''
      );
      fs.file('.packages')..createSync();

      final List<String> assets = <String>[
        'a/b/c/foo',
        'a/b/c/var1/foo',
        'a/b/c/var2/foo',
        'a/b/c/var3/foo',
      ];
      for (String asset in assets) {
        fs.file(asset)
          ..createSync(recursive: true)
          ..writeAsStringSync(asset);
      }

      AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');

      // The main asset file, /a/b/c/foo, and its variants exist.
      for (String asset in assets) {
        expect(bundle.entries.containsKey(asset), true);
        expect(utf8.decode(await bundle.entries[asset].contentsAsBytes()), asset);
      }

      fs.file('a/b/c/foo').deleteSync();
      bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');

      // Now the main asset file, /a/b/c/foo, does not exist. This is OK because
      // the /a/b/c/*/foo variants do exist.
      expect(bundle.entries.containsKey('a/b/c/foo'), false);
      for (String asset in assets.skip(1)) {
        expect(bundle.entries.containsKey(asset), true);
        expect(utf8.decode(await bundle.entries[asset].contentsAsBytes()), asset);
      }
    });

  });
}
