// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

void main() {
  String fixPath(String path) {
    // The in-memory file system is strict about slashes on Windows being the
    // correct way so until https://github.com/google/file.dart/issues/112 is
    // fixed we fix them here.
    // TODO(dantup): Remove this function once the above issue is fixed and
    // rolls into Flutter.
    return path?.replaceAll('/', globals.fs.path.separator);
  }
  void writePubspecFile(String path, String name, { List<String> assets }) {
    String assetsSection;
    if (assets == null) {
      assetsSection = '';
    } else {
      final StringBuffer buffer = StringBuffer();
      buffer.write('''
flutter:
     assets:
''');

      for (final String asset in assets) {
        buffer.write('''
       - $asset
''');
      }
      assetsSection = buffer.toString();
    }

    globals.fs.file(fixPath(path))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: $name
dependencies:
  flutter:
    sdk: flutter
$assetsSection
''');
  }

  void writePackagesFile(String packages) {
    globals.fs.file('.packages')
      ..createSync()
      ..writeAsStringSync(packages);
  }

  Future<void> buildAndVerifyAssets(
    List<String> assets,
    List<String> packages,
    String expectedAssetManifest, {
    bool expectExists = true,
  }) async {
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    await bundle.build(manifestPath: 'pubspec.yaml', packagesPath: '.packages');

    for (final String packageName in packages) {
      for (final String asset in assets) {
        final String entryKey = Uri.encodeFull('packages/$packageName/$asset');
        expect(bundle.entries.containsKey(entryKey), expectExists,
          reason: 'Cannot find key on bundle: $entryKey');
        if (expectExists) {
          expect(
            utf8.decode(await bundle.entries[entryKey].contentsAsBytes()),
            asset,
          );
        }
      }
    }

    if (expectExists) {
      expect(
        utf8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
        expectedAssetManifest,
      );
    }
  }

  void writeAssets(String path, List<String> assets) {
    for (final String asset in assets) {
      final String fullPath = fixPath(globals.fs.path.join(path, asset));

      globals.fs.file(fullPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(asset);
    }
  }

  FileSystem testFileSystem;

  setUp(() async {
    testFileSystem = MemoryFileSystem(
      style: globals.platform.isWindows
        ? FileSystemStyle.windows
        : FileSystemStyle.posix,
    );
    testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync('flutter_asset_bundle_test.');
  });

  group('AssetBundle assets from packages', () {
    testUsingContext('No assets are bundled when the package has no assets', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile('p/p/pubspec.yaml', 'test_package');

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml', packagesPath: '.packages');
      expect(bundle.entries.length, 3); // LICENSE, AssetManifest, FontManifest
      const String expectedAssetManifest = '{}';
      expect(
        utf8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
        expectedAssetManifest,
      );
      expect(
        utf8.decode(await bundle.entries['FontManifest.json'].contentsAsBytes()),
        '[]',
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('No assets are bundled when the package has an asset that is not listed', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile('p/p/pubspec.yaml', 'test_package');

      final List<String> assets = <String>['a/foo'];
      writeAssets('p/p/', assets);

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml', packagesPath: '.packages');
      expect(bundle.entries.length, 3); // LICENSE, AssetManifest, FontManifest
      const String expectedAssetManifest = '{}';
      expect(
        utf8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
        expectedAssetManifest,
      );
      expect(
        utf8.decode(await bundle.entries['FontManifest.json'].contentsAsBytes()),
        '[]',
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('One asset is bundled when the package has and lists one '
      'asset its pubspec', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assets = <String>['a/foo'];
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assets,
      );

      writeAssets('p/p/', assets);

      const String expectedAssetManifest = '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo"]}';
      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('One asset is bundled when the package has one asset, '
      "listed in the app's pubspec", () async {
      final List<String> assetEntries = <String>['packages/test_package/a/foo'];
      writePubspecFile(
        'pubspec.yaml',
        'test',
        assets: assetEntries,
      );
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile('p/p/pubspec.yaml', 'test_package');

      final List<String> assets = <String>['a/foo'];
      writeAssets('p/p/lib/', assets);

      const String expectedAssetManifest = '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo"]}';
      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('One asset and its variant are bundled when the package '
      'has an asset and a variant, and lists the asset in its pubspec', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: <String>['a/foo'],
      );

      final List<String> assets = <String>['a/foo', 'a/v/foo'];
      writeAssets('p/p/', assets);

      const String expectedManifest = '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo","packages/test_package/a/v/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('One asset and its variant are bundled when the package '
      'has an asset and a variant, and the app lists the asset in its pubspec', () async {
      writePubspecFile(
        'pubspec.yaml',
        'test',
        assets: <String>['packages/test_package/a/foo'],
      );
      writePackagesFile('test_package:p/p/lib/');
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
      );

      final List<String> assets = <String>['a/foo', 'a/v/foo'];
      writeAssets('p/p/lib/', assets);

      const String expectedManifest = '{"packages/test_package/a/foo":'
          '["packages/test_package/a/foo","packages/test_package/a/v/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Two assets are bundled when the package has and lists '
      'two assets in its pubspec', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assets = <String>['a/foo', 'a/bar'];
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assets,
      );

      writeAssets('p/p/', assets);
      const String expectedAssetManifest =
          '{"packages/test_package/a/bar":["packages/test_package/a/bar"],'
          '"packages/test_package/a/foo":["packages/test_package/a/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext("Two assets are bundled when the package has two assets, listed in the app's pubspec", () async {
      final List<String> assetEntries = <String>[
        'packages/test_package/a/foo',
        'packages/test_package/a/bar',
      ];
      writePubspecFile(
        'pubspec.yaml',
        'test',
         assets: assetEntries,
      );
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assets = <String>['a/foo', 'a/bar'];
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
      );

      writeAssets('p/p/lib/', assets);
      const String expectedAssetManifest =
          '{"packages/test_package/a/bar":["packages/test_package/a/bar"],'
          '"packages/test_package/a/foo":["packages/test_package/a/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Two assets are bundled when two packages each have and list an asset their pubspec', () async {
      writePubspecFile(
        'pubspec.yaml',
        'test',
      );
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

      const String expectedAssetManifest =
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
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext("Two assets are bundled when two packages each have an asset, listed in the app's pubspec", () async {
      final List<String> assetEntries = <String>[
        'packages/test_package/a/foo',
        'packages/test_package2/a/foo',
      ];
      writePubspecFile(
        'pubspec.yaml',
        'test',
        assets: assetEntries,
      );
      writePackagesFile('test_package:p/p/lib/\ntest_package2:p2/p/lib/');
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
      );
      writePubspecFile(
        'p2/p/pubspec.yaml',
        'test_package2',
      );

      final List<String> assets = <String>['a/foo', 'a/v/foo'];
      writeAssets('p/p/lib/', assets);
      writeAssets('p2/p/lib/', assets);

      const String expectedAssetManifest =
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
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('One asset is bundled when the app depends on a package, '
      'listing in its pubspec an asset from another package', () async {
      writePubspecFile(
        'pubspec.yaml',
        'test',
      );
      writePackagesFile('test_package:p/p/lib/\ntest_package2:p2/p/lib/');
      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: <String>['packages/test_package2/a/foo'],
      );
      writePubspecFile(
        'p2/p/pubspec.yaml',
        'test_package2',
      );

      final List<String> assets = <String>['a/foo', 'a/v/foo'];
      writeAssets('p2/p/lib/', assets);

      const String expectedAssetManifest =
          '{"packages/test_package2/a/foo":'
          '["packages/test_package2/a/foo","packages/test_package2/a/v/foo"]}';

      await buildAndVerifyAssets(
        assets,
        <String>['test_package2'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  testUsingContext('Asset paths can contain URL reserved characters', () async {
    writePubspecFile('pubspec.yaml', 'test');
    writePackagesFile('test_package:p/p/lib/');

    final List<String> assets = <String>['a/foo', 'a/foo[x]'];
    writePubspecFile(
      'p/p/pubspec.yaml',
      'test_package',
      assets: assets,
    );

    writeAssets('p/p/', assets);
    const String expectedAssetManifest =
        '{"packages/test_package/a/foo":["packages/test_package/a/foo"],'
        '"packages/test_package/a/foo%5Bx%5D":["packages/test_package/a/foo%5Bx%5D"]}';

    await buildAndVerifyAssets(
      assets,
      <String>['test_package'],
      expectedAssetManifest,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
  });

  group('AssetBundle assets from scanned paths', () {
    testUsingContext('Two assets are bundled when scanning their directory', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assetsOnDisk = <String>['a/foo', 'a/bar'];
      final List<String> assetsOnManifest = <String>['a/'];

      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assetsOnManifest,
      );

      writeAssets('p/p/', assetsOnDisk);
      const String expectedAssetManifest =
          '{"packages/test_package/a/bar":["packages/test_package/a/bar"],'
          '"packages/test_package/a/foo":["packages/test_package/a/foo"]}';

      await buildAndVerifyAssets(
        assetsOnDisk,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Two assets are bundled when listing one and scanning second directory', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assetsOnDisk = <String>['a/foo', 'abc/bar'];
      final List<String> assetOnManifest = <String>['a/foo', 'abc/'];

      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assetOnManifest,
      );

      writeAssets('p/p/', assetsOnDisk);
      const String expectedAssetManifest =
          '{"packages/test_package/a/foo":["packages/test_package/a/foo"],'
          '"packages/test_package/abc/bar":["packages/test_package/abc/bar"]}';

      await buildAndVerifyAssets(
        assetsOnDisk,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('One asset is bundled with variant, scanning wrong directory', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assetsOnDisk = <String>['a/foo','a/b/foo','a/bar'];
      final List<String> assetOnManifest = <String>['a','a/bar']; // can't list 'a' as asset, should be 'a/'

      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assetOnManifest,
      );

      writeAssets('p/p/', assetsOnDisk);

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml', packagesPath: '.packages');

      expect(bundle.entries['AssetManifest.json'], isNull,
        reason: 'Invalid pubspec.yaml should not generate AssetManifest.json'  );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('AssetBundle assets from scanned paths with MemoryFileSystem', () {
    testUsingContext('One asset is bundled with variant, scanning directory', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assetsOnDisk = <String>['a/foo','a/b/foo'];
      final List<String> assetOnManifest = <String>['a/',];

      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assetOnManifest,
      );

      writeAssets('p/p/', assetsOnDisk);
      const String expectedAssetManifest =
          '{"packages/test_package/a/foo":["packages/test_package/a/foo","packages/test_package/a/b/foo"]}';

      await buildAndVerifyAssets(
        assetsOnDisk,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('No asset is bundled with variant, no assets or directories are listed', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assetsOnDisk = <String>['a/foo', 'a/b/foo'];
      final List<String> assetOnManifest = <String>[];

      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assetOnManifest,
      );

      writeAssets('p/p/', assetsOnDisk);
      const String expectedAssetManifest = '{}';

      await buildAndVerifyAssets(
        assetOnManifest,
        <String>['test_package'],
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Expect error generating manifest, wrong non-existing directory is listed', () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackagesFile('test_package:p/p/lib/');

      final List<String> assetOnManifest = <String>['c/'];

      writePubspecFile(
        'p/p/pubspec.yaml',
        'test_package',
        assets: assetOnManifest,
      );

      await buildAndVerifyAssets(
        assetOnManifest,
        <String>['test_package'],
        null,
        expectExists: false,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}
