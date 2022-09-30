// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

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

  group('AssetBundle asset variants (with POSIX-style paths)', () {
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

      final Map<String, List<String>> manifest = await extractAssetManifestFromBundle(bundle);

      expect(manifest, hasLength(2));
      expect(manifest[image], equals(<String>[image, image2xVariant]));
      expect(manifest[imageNonVariant], equals(<String>[imageNonVariant]));
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

      final Map<String, List<String>> manifest = await extractAssetManifestFromBundle(bundle);
      expect(manifest, hasLength(2));
      expect(manifest[topLevelImage], equals(<String>[topLevelImage]));
      expect(manifest[secondLevelImage], equals(<String>[secondLevelImage, secondLevel2xVariant]));
    });

    testWithoutContext('Assets with paths affected by URI-encoding are not URI-encoded', () async {
      const String image = 'assets/normalFolder/i have special_characters.jpg';
      const String imageVariant = 'assets/normalFolder/3x/i have special_characters.jpg';

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

      final Map<String, List<String>> manifest = await extractAssetManifestFromBundle(bundle);
      expect(manifest, hasLength(1));
      expect(manifest[image], equals(<String>[image, imageVariant]));
    });
  });


  group('AssetBundle asset variants (with Windows-style filepaths)', () {
    late final Platform platform;
    late final FileSystem fs;

    String withPosixPathSeparators(String path) {
      return path.replaceAll(r'\', '/');
    }

    setUpAll(() {
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
      const String foo = r'assets\foo.jpg';
      const String foo2xVariant = r'assets\2x\foo.jpg';
      const String bar = r'assets\somewhereElse\bar.jpg';
      const String bar2xVariant = r'assets\somewhereElse\2x\bar.jpg';

      final List<String> assets = <String>[
        foo,
        foo2xVariant,
        bar,
        bar2xVariant
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

      final Map<String, List<String>> manifest = await extractAssetManifestFromBundle(bundle);

      final List<String> expectedFooVariants = <String>[
        withPosixPathSeparators(foo),
        withPosixPathSeparators(foo2xVariant)
      ];
      final List<String>expectedBarVariants = <String>[
        withPosixPathSeparators(bar),
        withPosixPathSeparators(bar2xVariant)
      ];
      expect(manifest, hasLength(2));
      expect(manifest[withPosixPathSeparators(foo)], equals(expectedFooVariants));
      expect(manifest[withPosixPathSeparators(bar)], equals(expectedBarVariants));
    });
  });
}
