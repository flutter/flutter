// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';

import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:standard_message_codec/standard_message_codec.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/package_config.dart';

void main() {
  String fixPath(String path) {
    // The in-memory file system is strict about slashes on Windows being the
    // correct way so until https://github.com/google/file.dart/issues/112 is
    // fixed we fix them here.
    // TODO(dantup): Remove this function once the above issue is fixed and
    // rolls into Flutter.
    return path.replaceAll('/', globals.fs.path.separator);
  }

  void writePubspecFile(
    String path,
    String name, {
    List<String>? assets,
    Map<String, String>? dependencies,
    List<(String path, String flavor)>? flavoredAssets,
  }) {
    String assetsSection;
    if (assets == null && flavoredAssets == null) {
      assetsSection = '';
    } else {
      final buffer = StringBuffer();
      buffer.write('''
flutter:
     assets:
''');

      for (final String asset in (assets ?? <String>[])) {
        buffer.write('''
       - $asset
''');
      }

      for (final (String path, String flavor) in flavoredAssets ?? <(String, String)>[]) {
        buffer.write('''
       - path: $path
         flavors:
           - $flavor
''');
      }

      assetsSection = buffer.toString();
    }

    dependencies = dependencies ?? <String, String>{};

    globals.fs.file(fixPath(path))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: $name
dependencies:
  flutter:
    sdk: flutter
${dependencies.entries.map((MapEntry<String, String> d) => '  ${d.key}: {path: ${d.value}}').join('\n')}
$assetsSection
''');
  }

  Future<void> buildAndVerifyAssets(
    List<String> assets,
    List<String> packages,
    Map<Object, Object> expectedAssetManifest, {
    String? flavor,
  }) async {
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    await bundle.build(
      packageConfigPath: '.dart_tool/package_config.json',
      flavor: flavor,
      targetPlatform: TargetPlatform.tester,
    );

    for (final packageName in packages) {
      for (final asset in assets) {
        final String entryKey = Uri.encodeFull('packages/$packageName/$asset');
        expect(bundle.entries, contains(entryKey), reason: 'Cannot find key on bundle: $entryKey');
        expect(utf8.decode(await bundle.entries[entryKey]!.contentsAsBytes()), asset);
      }
    }

    final assetManifest =
        const StandardMessageCodec().decodeMessage(
              ByteData.sublistView(
                Uint8List.fromList(await bundle.entries['AssetManifest.bin']!.contentsAsBytes()),
              ),
            )
            as Map<Object?, Object?>;

    expect(assetManifest, expectedAssetManifest);
  }

  void writeAssets(String path, List<String> assets) {
    for (final asset in assets) {
      final String fullPath = fixPath(globals.fs.path.join(path, asset));

      globals.fs.file(fullPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(asset);
    }
  }

  late FileSystem testFileSystem;

  setUp(() async {
    testFileSystem = MemoryFileSystem(
      style: globals.platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    );
    testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync(
      'flutter_asset_bundle_test.',
    );
  });

  group('AssetBundle assets from packages', () {
    testUsingContext(
      'No assets are bundled when the package has no assets',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'test',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>['NOTICES.Z', 'AssetManifest.bin', 'FontManifest.json']),
        );
        expect(utf8.decode(await bundle.entries['FontManifest.json']!.contentsAsBytes()), '[]');
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'No assets are bundled when the package has an asset that is not listed',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'test',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        final assets = <String>['a/foo'];
        writeAssets('p/p/', assets);

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>['NOTICES.Z', 'AssetManifest.bin', 'FontManifest.json']),
        );
        expect(utf8.decode(await bundle.entries['FontManifest.json']!.contentsAsBytes()), '[]');
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'One asset is bundled when the package has and lists one '
      'asset its pubspec',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'test',
        );

        final assets = <String>['a/foo'];
        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assets);

        writeAssets('p/p/', assets);

        final expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<Object, Object>>[
            <Object, Object>{'asset': 'packages/test_package/a/foo'},
          ],
        };

        await buildAndVerifyAssets(assets, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'One asset is bundled when the package has one asset, '
      "listed in the app's pubspec",
      () async {
        final assetEntries = <String>['packages/test_package/a/foo'];
        writePubspecFile('pubspec.yaml', 'test', assets: assetEntries);
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'test',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        final assets = <String>['a/foo'];
        writeAssets('p/p/lib/', assets);

        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
          ],
        };
        await buildAndVerifyAssets(assets, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'One asset and its variant are bundled when the package '
      'has an asset and a variant, and lists the asset in its pubspec',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          packages: <String, String>{'test_package': 'p/p/'},
          mainLibName: 'test',
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: <String>['a/foo', 'a/bar']);

        final assets = <String>['a/foo', 'a/2x/foo', 'a/bar'];
        writeAssets('p/p/', assets);

        const expectedManifest = <Object, Object>{
          'packages/test_package/a/bar': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/bar'},
          ],
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
            <String, Object>{'asset': 'packages/test_package/a/2x/foo', 'dpr': 2.0},
          ],
        };

        await buildAndVerifyAssets(assets, <String>['test_package'], expectedManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'One asset and its variant are bundled when the package '
      'has an asset and a variant, and the app lists the asset in its pubspec',
      () async {
        writePubspecFile('pubspec.yaml', 'test', assets: <String>['packages/test_package/a/foo']);
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        final assets = <String>['a/foo', 'a/2x/foo'];
        writeAssets('p/p/lib/', assets);

        const expectedManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
            <String, Object>{'asset': 'packages/test_package/a/2x/foo', 'dpr': 2.0},
          ],
        };

        await buildAndVerifyAssets(assets, <String>['test_package'], expectedManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'Two assets are bundled when the package has and lists '
      'two assets in its pubspec',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assets = <String>['a/foo', 'a/bar'];
        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assets);

        writeAssets('p/p/', assets);
        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/bar': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/bar'},
          ],
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
          ],
        };

        await buildAndVerifyAssets(assets, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      "Two assets are bundled when the package has two assets, listed in the app's pubspec",
      () async {
        final assetEntries = <String>['packages/test_package/a/foo', 'packages/test_package/a/bar'];
        writePubspecFile('pubspec.yaml', 'test', assets: assetEntries);
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assets = <String>['a/foo', 'a/bar'];
        writePubspecFile('p/p/pubspec.yaml', 'test_package');

        writeAssets('p/p/lib/', assets);
        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/bar': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/bar'},
          ],
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
          ],
        };

        await buildAndVerifyAssets(assets, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'Two assets are bundled when two packages each have and list an asset their pubspec',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/', 'test_package2': 'p2/p/'},
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: <String>['a/foo']);
        writePubspecFile('p2/p/pubspec.yaml', 'test_package2', assets: <String>['a/foo']);

        final assets = <String>['a/foo', 'a/2x/foo'];
        writeAssets('p/p/', assets);
        writeAssets('p2/p/', assets);

        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
            <String, Object>{'asset': 'packages/test_package/a/2x/foo', 'dpr': 2.0},
          ],
          'packages/test_package2/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package2/a/foo'},
            <String, Object>{'asset': 'packages/test_package2/a/2x/foo', 'dpr': 2.0},
          ],
        };

        await buildAndVerifyAssets(assets, <String>[
          'test_package',
          'test_package2',
        ], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      "Two assets are bundled when two packages each have an asset, listed in the app's pubspec",
      () async {
        final assetEntries = <String>[
          'packages/test_package/a/foo',
          'packages/test_package2/a/foo',
        ];
        writePubspecFile('pubspec.yaml', 'test', assets: assetEntries);
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/', 'test_package2': 'p2/p/'},
        );
        writePubspecFile('p/p/pubspec.yaml', 'test_package');
        writePubspecFile('p2/p/pubspec.yaml', 'test_package2');

        final assets = <String>['a/foo', 'a/2x/foo'];
        writeAssets('p/p/lib/', assets);
        writeAssets('p2/p/lib/', assets);

        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
            <String, Object>{'asset': 'packages/test_package/a/2x/foo', 'dpr': 2.0},
          ],
          'packages/test_package2/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package2/a/foo'},
            <String, Object>{'asset': 'packages/test_package2/a/2x/foo', 'dpr': 2.0},
          ],
        };

        await buildAndVerifyAssets(assets, <String>[
          'test_package',
          'test_package2',
        ], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'One asset is bundled when the app depends on a package, '
      'listing in its pubspec an asset from another package',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/', 'test_package2': 'p2/p/'},
        );
        writePubspecFile(
          'p/p/pubspec.yaml',
          'test_package',
          assets: <String>['packages/test_package2/a/foo'],
        );
        writePubspecFile('p2/p/pubspec.yaml', 'test_package2');

        final assets = <String>['a/foo', 'a/2x/foo'];
        writeAssets('p2/p/lib/', assets);

        const expectedAssetManifest = <Object, Object>{
          'packages/test_package2/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package2/a/foo'},
            <String, Object>{'asset': 'packages/test_package2/a/2x/foo', 'dpr': 2.0},
          ],
        };

        await buildAndVerifyAssets(assets, <String>['test_package2'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'Flavored assets are bundled when the app depends on a package',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );
        writePubspecFile(
          'p/p/pubspec.yaml',
          'test_package',
          flavoredAssets: <(String, String)>[('assets/vanilla.txt', 'vanilla')],
        );

        final assets = <String>['assets/vanilla.txt'];
        writeAssets('p/p', assets);

        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/assets/vanilla.txt': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/assets/vanilla.txt'},
          ],
        };

        await buildAndVerifyAssets(
          assets,
          <String>['test_package'],
          expectedAssetManifest,
          flavor: 'vanilla',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  testUsingContext(
    'Asset paths can contain URL reserved characters',
    () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'test',
        packages: <String, String>{'test_package': 'p/p/'},
      );

      final assets = <String>['a/foo', 'a/foo [x]'];
      writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assets);

      writeAssets('p/p/', assets);
      const expectedAssetManifest = <Object, Object>{
        'packages/test_package/a/foo': <Map<String, Object>>[
          <String, Object>{'asset': 'packages/test_package/a/foo'},
        ],
        'packages/test_package/a/foo [x]': <Map<String, Object>>[
          <String, Object>{'asset': 'packages/test_package/a/foo [x]'},
        ],
      };

      await buildAndVerifyAssets(assets, <String>['test_package'], expectedAssetManifest);
    },
    overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'Asset paths can contain URL reserved characters',
    () async {
      writePubspecFile('pubspec.yaml', 'test');
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'test',
        packages: <String, String>{'test_package': 'p/p/'},
      );

      final assets = <String>['a/foo', 'a/foo [x]'];
      writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assets);

      writeAssets('p/p/', assets);
      const expectedAssetManifest = <Object, Object>{
        'packages/test_package/a/foo': <Map<String, Object>>[
          <String, Object>{'asset': 'packages/test_package/a/foo'},
        ],
        'packages/test_package/a/foo [x]': <Map<String, Object>>[
          <String, Object>{'asset': 'packages/test_package/a/foo [x]'},
        ],
      };

      await buildAndVerifyAssets(assets, <String>['test_package'], expectedAssetManifest);
    },
    overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  group('AssetBundle assets from scanned paths', () {
    testUsingContext(
      'Two assets are bundled when scanning their directory',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assetsOnDisk = <String>['a/foo', 'a/bar'];
        final assetsOnManifest = <String>['a/'];

        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assetsOnManifest);

        writeAssets('p/p/', assetsOnDisk);
        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/bar': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/bar'},
          ],
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
          ],
        };

        await buildAndVerifyAssets(assetsOnDisk, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'Two assets are bundled when listing one and scanning second directory',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assetsOnDisk = <String>['a/foo', 'abc/bar'];
        final assetOnManifest = <String>['a/foo', 'abc/'];

        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assetOnManifest);

        writeAssets('p/p/', assetsOnDisk);
        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
          ],
          'packages/test_package/abc/bar': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/abc/bar'},
          ],
        };

        await buildAndVerifyAssets(assetsOnDisk, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'One asset is bundled with variant, scanning wrong directory',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assetsOnDisk = <String>['a/foo', 'a/b/foo', 'a/bar'];
        final assetOnManifest = <String>['a', 'a/bar']; // can't list 'a' as asset, should be 'a/'

        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assetOnManifest);

        writeAssets('p/p/', assetsOnDisk);

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );

        expect(
          bundle.entries['AssetManifest.bin'],
          isNull,
          reason: 'Invalid pubspec.yaml should not generate AssetManifest.bin',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  group('AssetBundle assets from scanned paths with MemoryFileSystem', () {
    testUsingContext(
      'One asset is bundled with variant, scanning directory',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assetsOnDisk = <String>['a/foo', 'a/2x/foo'];
        final assetOnManifest = <String>['a/'];

        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assetOnManifest);

        writeAssets('p/p/', assetsOnDisk);
        const expectedAssetManifest = <Object, Object>{
          'packages/test_package/a/foo': <Map<String, Object>>[
            <String, Object>{'asset': 'packages/test_package/a/foo'},
            <String, Object>{'asset': 'packages/test_package/a/2x/foo', 'dpr': 2.0},
          ],
        };
        await buildAndVerifyAssets(assetsOnDisk, <String>['test_package'], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'No asset is bundled with variant, no assets or directories are listed',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assetsOnDisk = <String>['a/foo', 'a/2x/foo'];
        final assetOnManifest = <String>[];

        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assetOnManifest);

        writeAssets('p/p/', assetsOnDisk);
        const expectedAssetManifest = <Object, Object>{};

        await buildAndVerifyAssets(assetOnManifest, <String>[
          'test_package',
        ], expectedAssetManifest);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'Expect error generating manifest, wrong non-existing directory is listed',
      () async {
        writePubspecFile('pubspec.yaml', 'test');
        writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'test',
          packages: <String, String>{'test_package': 'p/p/'},
        );

        final assetOnManifest = <String>['c/'];

        writePubspecFile('p/p/pubspec.yaml', 'test_package', assets: assetOnManifest);

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}
