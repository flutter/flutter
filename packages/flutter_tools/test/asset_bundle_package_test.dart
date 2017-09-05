// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';

import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  void writePubspecFile(String path, String name, {List<String> assets}) {
    String assetsSection;
    if (assets == null) {
      assetsSection = '';
    } else {
      final StringBuffer buffer = new StringBuffer();
      buffer.write('''
flutter:
     assets:
''');

      for (String asset in assets) {
        buffer.write('''
       - $asset
''');
      }
      assetsSection = buffer.toString();
    }

    fs.file(path)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: $name
dependencies:
  flutter:
    sdk: flutter
$assetsSection
''');
  }

  void establishFlutterRoot() {
    // Setting flutterRoot here so that it picks up the MemoryFileSystem's
    // path separator.
    Cache.flutterRoot = getFlutterRoot();
  }

  void writePackagesFile(String packages) {
    fs.file(".packages")
      ..createSync()
      ..writeAsStringSync(packages);
  }

  Future<Null> buildAndVerifyAssets(
    List<String> assets,
    List<String> packages,
    String expectedAssetManifest,
  ) async {
    final AssetBundle bundle = new AssetBundle();
    await bundle.build(manifestPath: 'pubspec.yaml');

    for (String packageName in packages) {
      for (String asset in assets) {
        final String entryKey = 'packages/$packageName/$asset';
        expect(bundle.entries.containsKey(entryKey), true);
        expect(
          UTF8.decode(await bundle.entries[entryKey].contentsAsBytes()),
          asset,
        );
      }
    }

    expect(
      UTF8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
      expectedAssetManifest,
    );
  }

  void writeAssets(String path, List<String> assets) {
    for (String asset in assets) {
      fs.file('$path$asset')
        ..createSync(recursive: true)
        ..writeAsStringSync(asset);
    }
  }

  group('AssetBundle assets from package', () {
    testUsingContext('One package with no assets', () async {
      establishFlutterRoot();

      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile('p/p/pubspec.yaml', 'test_package');

      final AssetBundle bundle = new AssetBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      expect(bundle.entries.length, 2); // LICENSE, AssetManifest
    }, overrides: <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
    });

    testUsingContext('One package with one asset', () async {
      establishFlutterRoot();

      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assets = <String>['a/foo'];
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assets,
      );

      writeAssets('p/p/', assets);

      final String expectedAssetManifest = '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo"]}';
      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
    });

    testUsingContext('One package with asset variants', () async {
      establishFlutterRoot();

      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: <String>['a/foo'],
      );

      final List<String> assets = <String>['a/foo', 'a/v/foo'];
      writeAssets('p/p/', assets);

      final String expectedManifest = '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo","packages/test_package/a/v/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
    });

    testUsingContext('One package with two assets', () async {
      establishFlutterRoot();

      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assets = <String>['a/foo', 'a/bar'];
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assets,
      );

      writeAssets('p/p/', assets);
      final String expectedAssetManifest =
          '{"packages/test_package/a/foo":["packages/test_package/a/foo"],'
          '"packages/test_package/a/bar":["packages/test_package/a/bar"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
    });

    testUsingContext('Two packages with assets', () async {
      establishFlutterRoot();

      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/\ntest_package2:p2/p/lib/');
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: <String>['a/foo'],
      );
      writePubspecFile(
        'p2/p/pubspec.yaml',
        'test_package2',
        assets: <String>['a/foo'],
      );

      final List<String> assets = <String>['a/foo', 'a/v/foo'];
      writeAssets('p/p/', assets);
      writeAssets('p2/p/', assets);

      final String expectedAssetManifest =
          '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo","packages/test_package/a/v/foo"],'
          '"packages/test_package2/a/foo":'
          '["packages/test_package2/a/foo","packages/test_package2/a/v/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package', 'test_package2'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => new MemoryFileSystem(),
    });
  });
}
