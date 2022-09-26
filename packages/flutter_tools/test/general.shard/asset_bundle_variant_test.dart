// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';

import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';

void main() {


  Future<Map<String, List<String>>> extractAssetManifestFromBundle(ManifestAssetBundle bundle) async {
    final String manifestJson = utf8.decode(await bundle.entries['AssetManifest.json']!.contentsAsBytes());
    final Map<String, dynamic> parsedJson = json.decode(manifestJson) as Map<String, dynamic>;
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest = <String, List<String>> {
      for (final String key in keys) key: List<String>.from(parsedJson[key] as List<dynamic>),
    };
    return parsedManifest;
  }

  group('AssetBundle asset variants', () {
    late final Platform platform;
    late final FileSystem fs;

    setUpAll(() {
      platform = FakePlatform();
      fs = MemoryFileSystem.test(
        style: io.Platform.isWindows
          ? FileSystemStyle.windows
          : FileSystemStyle.posix
      );
      Cache.flutterRoot = Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fs,
        userMessages: UserMessages()
      );

      fs.file('.packages').createSync();

      fs.file('pubspec.yaml').writeAsStringSync(
'''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - assets/
'''
      );
    });

    testWithoutContext('Only images in folders named with device pixel ratios (e.g. 2x, 3.0x) should be considered as variants of other images', () async {

      const String image = 'assets/image.jpg';
      const String image2xVariant = 'assets/2x/image.jpg';
      const String imageNonVariant = 'assets/notAVariant/image.jpg';

      final List<String> assets = <String>[
        image,
        image2xVariant,
        imageNonVariant
      ];

      for (final String asset in assets) {
        final File assetFile = fs.file(asset);
        await assetFile.create(recursive: true);
        await assetFile.writeAsString(asset);
      }

      final ManifestAssetBundle bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: platform,
      );

      await bundle.build(
        packagesPath: '.packages',
        assetDirPath: './build/flutter_assets',
        flutterProject:  FlutterProject.fromDirectoryTest(fs.currentDirectory),
      );

      final Map<String, List<String>> manifest = await extractAssetManifestFromBundle(bundle);
      final List<String> variantsForImage = manifest[image]!;

      expect(variantsForImage, contains(image2xVariant));
      expect(variantsForImage, isNot(contains(imageNonVariant)));
    });

    testWithoutContext('Asset directories are recursively searched for assets', () async {
      const String topLevelImage = 'assets/image.jpg';
      const String secondLevelImage = 'assets/folder/secondLevel.jpg';
      const String secondLevel2xVariant = 'assets/folder/2x/secondLevel.jpg';

      final List<String> assets = <String>[
        topLevelImage,
        secondLevelImage,
        secondLevel2xVariant
      ];

      for (final String asset in assets) {
        final File assetFile = fs.file(asset);
        await assetFile.create(recursive: true);
        await assetFile.writeAsString(asset);
      }

      final ManifestAssetBundle bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: platform,
      );

      await bundle.build(
        packagesPath: '.packages',
        assetDirPath: './build/flutter_assets',
        flutterProject:  FlutterProject.fromDirectoryTest(fs.currentDirectory),
      );

      final Map<String, List<String>> manifest = await extractAssetManifestFromBundle(bundle);
      expect(manifest, contains(secondLevelImage));
      expect(manifest, contains(topLevelImage));
      expect(manifest[secondLevelImage], hasLength(2));
      expect(manifest[secondLevelImage], contains(secondLevelImage));
      expect(manifest[secondLevelImage], contains(secondLevel2xVariant));
    });
  });
}
