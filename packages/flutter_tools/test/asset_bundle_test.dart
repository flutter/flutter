// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';

import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main()  {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  // Fixed asset bundle tests.
  group('AssetBundle.fixed', () {
    test('empty strings', () async {
      expect(new AssetBundle.fixed(null, null), isNotNull);
      expect(new AssetBundle.fixed('', ''), isNotNull);
      expect(new AssetBundle.fixed(null, null).entries, isEmpty);
    });
    test('does not need a rebuild', () async {
      expect(new AssetBundle.fixed(null, null).needsBuild(), isFalse);
    });
    test('empty string', () async {
      final AssetBundle ab = new AssetBundle.fixed('', '');
      expect(ab.entries, isEmpty);
    });
    test('single entry', () async {
      final AssetBundle ab = new AssetBundle.fixed('', 'apple.txt');
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 1);
      final String archivePath = ab.entries.keys.first;
      expect(archivePath, isNotNull);
      expect(archivePath, 'apple.txt');
    });
    test('two entries', () async {
      final AssetBundle ab = new AssetBundle.fixed('', 'apple.txt,packages/flutter_gallery_assets/shrine/products/heels.png');
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 2);
      final List<String> archivePaths = ab.entries.keys.toList()..sort();
      expect(archivePaths[0], 'apple.txt');
      expect(archivePaths[1], 'packages/flutter_gallery_assets/shrine/products/heels.png');
    });

    testUsingContext('file contents', () async {
      // Create a temporary directory and write a single file into it.
      final Directory tempDir = fs.systemTempDirectory.createTempSync();
      final String projectRoot = tempDir.path;
      final String assetPath = 'banana.txt';
      final String assetContents = 'banana';
      final File tempFile = fs.file(fs.path.join(projectRoot, assetPath));
      tempFile.parent.createSync(recursive: true);
      tempFile.writeAsBytesSync(UTF8.encode(assetContents));

      final AssetBundle ab = new AssetBundle.fixed(projectRoot, assetPath);
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 1);
      final String archivePath = ab.entries.keys.first;
      final DevFSContent content = ab.entries[archivePath];
      expect(archivePath, assetPath);
      expect(assetContents, UTF8.decode(await content.contentsAsBytes()));
    }, overrides: <Type, Generator>{
      FileSystem: () => const LocalFileSystem(),
    });
  });

  group('AssetBundle.build', () {
    test('nonempty', () async {
      final AssetBundle ab = new AssetBundle();
      expect(await ab.build(), 0);
      expect(ab.entries.length, greaterThan(0));
    });

    testUsingContext('empty pubspec', () async {
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('');

      final AssetBundle bundle = new AssetBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      expect(bundle.entries.length, 1);
      final String expectedAssetManifest = '{}';
      expect(
        UTF8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{FileSystem: () => new MemoryFileSystem(),});
  });

}
