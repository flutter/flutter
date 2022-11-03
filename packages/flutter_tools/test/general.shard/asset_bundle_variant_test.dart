// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';

import 'package:flutter_tools/src/project.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

import '../src/common.dart';

void main() {

  Future<String> extractAssetManifestFromBundleAsJson(ManifestAssetBundle bundle) async {
    final List<int> manifestBytes = await bundle.entries['AssetManifest.bin']!.contentsAsBytes();
    return json.encode(const StandardMessageCodec().decodeMessage(
      ByteData.sublistView(Uint8List.fromList(manifestBytes))
    ));
  }

  group('AssetBundle asset variants (with Unix-style paths)', () {
    late Platform platform;
    late FileSystem fs;

    setUp(() {
      platform = FakePlatform();
      fs = MemoryFileSystem.test();
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
        assetFile.createSync(recursive: true);
        assetFile.writeAsStringSync(asset);
      }

      final ManifestAssetBundle bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: platform,
      );

      await bundle.build(
        packagesPath: '.packages',
        flutterProject:  FlutterProject.fromDirectoryTest(fs.currentDirectory),
      );

      const String expectedManifest = '{"$image":[{"asset":"$image2xVariant","dpr":2.0}],'
        '"$imageNonVariant":[]}';

      final String manifest = await extractAssetManifestFromBundleAsJson(bundle);
      expect(manifest, equals(expectedManifest));
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
        assetFile.createSync(recursive: true);
        assetFile.writeAsStringSync(asset);
      }

      final ManifestAssetBundle bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: platform,
      );

      await bundle.build(
        packagesPath: '.packages',
        flutterProject:  FlutterProject.fromDirectoryTest(fs.currentDirectory),
      );

      const String expectedManifest = '{'
        '"$secondLevelImage":[{"asset":"$secondLevel2xVariant","dpr":2.0}],'
        '"$topLevelImage":[]'
      '}';

      final String manifest = await extractAssetManifestFromBundleAsJson(bundle);
      expect(manifest, equals(expectedManifest));
    });

    testWithoutContext('Asset paths should never be URI-encoded', () async {
      const String image = 'assets/normalFolder/i have URI-reserved_characters.jpg';
      const String imageVariant = 'assets/normalFolder/3x/i have URI-reserved_characters.jpg';

      final List<String> assets = <String>[
        image,
        imageVariant
      ];

      for (final String asset in assets) {
        final File assetFile = fs.file(asset);
        assetFile.createSync(recursive: true);
        assetFile.writeAsStringSync(asset);
      }

      final ManifestAssetBundle bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: platform,
      );

      await bundle.build(
        packagesPath: '.packages',
        flutterProject:  FlutterProject.fromDirectoryTest(fs.currentDirectory),
      );

      const String expectedManifest = '{"$image":[{"asset":"$imageVariant","dpr":3.0}]}';

      final String manifest = await extractAssetManifestFromBundleAsJson(bundle);
      expect(manifest, equals(expectedManifest));
    });
  });


  group('AssetBundle asset variants (with Windows-style filepaths)', () {
    late final Platform platform;
    late final FileSystem fs;

    setUp(() {
      platform = FakePlatform(operatingSystem: 'windows');
      fs = MemoryFileSystem.test(style: FileSystemStyle.windows);
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

    testWithoutContext('Variant detection works with windows-style filepaths', () async {
      const List<String> assets = <String>[
        r'assets\foo.jpg',
        r'assets\2x\foo.jpg',
        r'assets\somewhereElse\bar.jpg',
        r'assets\somewhereElse\2x\bar.jpg',
      ];

      for (final String asset in assets) {
        final File assetFile = fs.file(asset);
        assetFile.createSync(recursive: true);
        assetFile.writeAsStringSync(asset);
      }

      final ManifestAssetBundle bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: platform,
      );

      await bundle.build(
        packagesPath: '.packages',
        flutterProject:  FlutterProject.fromDirectoryTest(fs.currentDirectory),
      );

      const String expectedManifest = '{"assets/foo.jpg":[{"asset":"assets/2x/foo.jpg","dpr":2.0}],'
      '"assets/somewhereElse/bar.jpg":[{"asset":"assets/somewhereElse/2x/bar.jpg","dpr":2.0}]}';

      final String manifest = await extractAssetManifestFromBundleAsJson(bundle);
      expect(manifest, equals(expectedManifest));
    });
  });
}
