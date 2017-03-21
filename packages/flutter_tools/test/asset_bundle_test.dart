// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main()  {
  // Create a temporary directory and write a single file into it.
  final FileSystem fs = const LocalFileSystem();
  final Directory tempDir = fs.systemTempDirectory.createTempSync();
  final String projectRoot = tempDir.path;
  final String assetPath = 'banana.txt';
  final String assetContents = 'banana';
  final File tempFile = fs.file(fs.path.join(projectRoot, assetPath));
  tempFile.parent.createSync(recursive: true);
  tempFile.writeAsBytesSync(UTF8.encode(assetContents));

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
    test('file contents', () async {
      final AssetBundle ab = new AssetBundle.fixed(projectRoot, assetPath);
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 1);
      final String archivePath = ab.entries.keys.first;
      final DevFSContent content = ab.entries[archivePath];
      expect(archivePath, assetPath);
      expect(assetContents, UTF8.decode(await content.contentsAsBytes()));
    });
  });

  group('AssetBundle.build', () {
    test('nonempty', () async {
      final AssetBundle ab = new AssetBundle();
      expect(await ab.build(), 0);
      expect(ab.entries.length, greaterThan(0));
    });
    testUsingContext('strip leading parent', () async {
      final String dataPath = fs.path.join(
        getFlutterRoot(),
        'packages',
        'flutter_tools',
        'test',
        'data',
        'asset_bundle',
        'project_root',
      );

      final AssetBundle ab = new AssetBundle();
      expect(await ab.build(
        manifestPath: fs.path.join(dataPath, 'pubspec.yaml'),
        packagesPath: fs.path.join(dataPath, '.packages'),
      ), 0);
      expect(ab.entries.containsKey('asset_1.txt'), true);
      expect(ab.entries.containsKey('font_1.ttf'), true);
      expect(ab.entries.containsKey('../asset_1.txt'), false);
      expect(ab.entries.containsKey('../font_1.ttf'), false);
      final DevFSStringContent fontManifest = ab.entries['FontManifest.json'];
      expect(fontManifest.string.contains('../'), false);
    });
  });
  testUsingContext('non-existent files throws error', () async {
    final String dataPath = fs.path.join(
      getFlutterRoot(),
      'packages',
      'flutter_tools',
      'test',
      'data',
      'asset_bundle',
      'project_root',
    );

    final AssetBundle ab = new AssetBundle();
    expect(await ab.build(
      manifestPath: fs.path.join(dataPath, 'buggy_pubspec.yaml'),
      packagesPath: fs.path.join(dataPath, '.packages'),
    ), 1);
    expect(ab.entries.length, 0);
  });
}
