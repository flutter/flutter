// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import '../src/package_config.dart';

void main() {
  const shaderLibDir = '/./shader_lib';

  group('AssetBundle.build (using context)', () {
    late FileSystem testFileSystem;
    late Platform platform;

    setUp(() async {
      testFileSystem = MemoryFileSystem();
      testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync(
        'flutter_asset_bundle_test.',
      );
      platform = FakePlatform();
    });

    testUsingContext(
      'nonempty',
      () async {
        final AssetBundle ab = AssetBundleFactory.instance.createBundle();
        expect(
          await ab.build(
            packageConfigPath: '.dart_tool/package_config.json',
            targetPlatform: TargetPlatform.tester,
          ),
          0,
        );
        expect(ab.entries.length, greaterThan(0));
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'empty pubspec',
      () async {
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('');

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(bundle.entries.keys, unorderedEquals(<String>['AssetManifest.bin']));
        const expectedBinAssetManifest = <Object, Object>{};
        expect(
          const StandardMessageCodec().decodeMessage(
            ByteData.sublistView(
              Uint8List.fromList(await bundle.entries['AssetManifest.bin']!.contentsAsBytes()),
            ),
          ),
          expectedBinAssetManifest,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'empty pubspec with data assets from hook',
      () async {
        writePackageConfigFiles(directory: testFileSystem.currentDirectory, mainLibName: 'my_app');
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('');
        final File dataAssetFile = testFileSystem.file('data/foo.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync('hello');

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
          flutterHookResult: FlutterHookResult(
            buildStart: DateTime.now(),
            buildEnd: DateTime.now(),
            dataAssets: <HookAsset>[
              HookAsset(file: dataAssetFile.uri, name: 'data/foo.txt', package: 'my_app'),
            ],
            dependencies: <Uri>[dataAssetFile.uri],
          ),
        );
        expect(bundle.entries.keys, contains('packages/my_app/data/foo.txt'));
        expect(
          const StandardMessageCodec().decodeMessage(
            ByteData.sublistView(
              Uint8List.fromList(await bundle.entries['AssetManifest.bin']!.contentsAsBytes()),
            ),
          ),
          <Object?, Object?>{
            'packages/my_app/data/foo.txt': <Object?>[
              <Object?, Object?>{'asset': 'packages/my_app/data/foo.txt'},
            ],
          },
        );
        expect(bundle.needsBuild(), isFalse);
        dataAssetFile.deleteSync();
        expect(bundle.needsBuild(), isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'wildcard directories do not include subdirectories',
      () async {
        writePackageConfigFiles(directory: testFileSystem.currentDirectory, mainLibName: 'my_app');
        testFileSystem.file('pubspec.yaml').writeAsStringSync('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - assets/foo/
    - assets/bar/lizard.png
''');

        final assets = <String>[
          'assets/foo/dog.png',
          'assets/foo/sub/cat.png',
          'assets/bar/lizard.png',
          'assets/bar/sheep.png',
        ];

        for (final asset in assets) {
          final File assetFile = testFileSystem.file(testFileSystem.path.joinAll(asset.split('/')));
          assetFile.createSync(recursive: true);
        }

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );

        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
            'assets/foo/dog.png',
            'assets/bar/lizard.png',
          ]),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'wildcard directories are updated when filesystem changes',
      () async {
        final File packageFile = writePackageConfigFiles(
          directory: testFileSystem.currentDirectory,
          mainLibName: 'my_app',
        );

        testFileSystem
            .file(testFileSystem.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
''');
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
            'assets/foo/bar.txt',
          ]),
        );
        // Simulate modifying the files by updating the filestat time manually.
        testFileSystem.file(testFileSystem.path.join('assets', 'foo', 'fizz.txt'))
          ..createSync(recursive: true)
          ..setLastModifiedSync(packageFile.lastModifiedSync().add(const Duration(hours: 1)));

        expect(bundle.needsBuild(), true);
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
            'assets/foo/bar.txt',
            'assets/foo/fizz.txt',
          ]),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'handle removal of wildcard directories',
      () async {
        testFileSystem
            .file(testFileSystem.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        final File pubspec = testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
''');
        final File packageConfig = writePackageConfigFiles(
          directory: testFileSystem.currentDirectory,
          mainLibName: 'my_app',
        );
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
            'assets/foo/bar.txt',
          ]),
        );
        expect(bundle.needsBuild(), false);

        // Delete the wildcard directory and update pubspec file.
        final DateTime modifiedTime = pubspec.lastModifiedSync().add(const Duration(hours: 1));
        testFileSystem
            .directory(testFileSystem.path.join('assets', 'foo'))
            .deleteSync(recursive: true);
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app''')
          ..setLastModifiedSync(modifiedTime);

        // touch the package config to make sure its change time is after pubspec.yaml's
        packageConfig.setLastModifiedSync(modifiedTime);

        // Even though the previous file was removed, it is left in the
        // asset manifest and not updated. This is due to the devfs not
        // supporting file deletion.
        expect(bundle.needsBuild(), true);
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
            'assets/foo/bar.txt',
          ]),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    // https://github.com/flutter/flutter/issues/42723
    testUsingContext(
      'Test regression for mistyped file',
      () async {
        testFileSystem
            .file(testFileSystem.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        // Create a directory in the same path to test that we're only looking at File
        // objects.
        testFileSystem.directory(testFileSystem.path.join('assets', 'foo', 'bar')).createSync();
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
''');
        writePackageConfigFiles(directory: testFileSystem.currentDirectory, mainLibName: 'my_app');
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
            'assets/foo/bar.txt',
          ]),
        );
        expect(bundle.needsBuild(), false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testWithoutContext('deferred assets are parsed', () async {
      writePackageConfigFiles(directory: testFileSystem.currentDirectory, mainLibName: 'my_app');
      testFileSystem
          .file(testFileSystem.path.join('assets', 'foo', 'bar.txt'))
          .createSync(recursive: true);
      testFileSystem
          .file(testFileSystem.path.join('assets', 'bar', 'barbie.txt'))
          .createSync(recursive: true);
      testFileSystem
          .file(testFileSystem.path.join('assets', 'wild', 'dash.txt'))
          .createSync(recursive: true);
      testFileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
  deferred-components:
    - name: component1
      assets:
        - assets/bar/barbie.txt
        - assets/wild/
''');
      final AssetBundle bundle = AssetBundleFactory.defaultInstance(
        logger: BufferLogger.test(),
        fileSystem: testFileSystem,
        flutterRoot: getFlutterRoot(),
        platform: platform,
        splitDeferredAssets: true,
      ).createBundle();
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        deferredComponentsEnabled: true,
        targetPlatform: TargetPlatform.tester,
      );
      expect(
        bundle.entries.keys,
        unorderedEquals(<String>[
          'AssetManifest.bin',
          'FontManifest.json',
          'NOTICES.Z',
          'assets/foo/bar.txt',
        ]),
      );
      expect(bundle.deferredComponentsEntries.length, 1);
      expect(bundle.deferredComponentsEntries['component1']!.length, 2);
      expect(bundle.needsBuild(), false);
    });

    testUsingContext(
      'deferred assets are parsed regularly when splitDeferredAssets Disabled',
      () async {
        writePackageConfigFiles(directory: testFileSystem.currentDirectory, mainLibName: 'my_app');
        testFileSystem
            .file(testFileSystem.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        testFileSystem
            .file(testFileSystem.path.join('assets', 'bar', 'barbie.txt'))
            .createSync(recursive: true);
        testFileSystem
            .file(testFileSystem.path.join('assets', 'wild', 'dash.txt'))
            .createSync(recursive: true);
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
  deferred-components:
    - name: component1
      assets:
        - assets/bar/barbie.txt
        - assets/wild/
''');
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        );
        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'assets/foo/bar.txt',
            'assets/bar/barbie.txt',
            'assets/wild/dash.txt',
            'AssetManifest.bin',
            'FontManifest.json',
            'NOTICES.Z',
          ]),
        );
        expect(bundle.deferredComponentsEntries.isEmpty, true);
        expect(bundle.needsBuild(), false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testWithoutContext('deferred assets wildcard parsed', () async {
      final File packageFile = writePackageConfigFiles(
        directory: testFileSystem.currentDirectory,
        mainLibName: 'my_app',
      );
      testFileSystem
          .file(testFileSystem.path.join('assets', 'foo', 'bar.txt'))
          .createSync(recursive: true);
      testFileSystem
          .file(testFileSystem.path.join('assets', 'bar', 'barbie.txt'))
          .createSync(recursive: true);
      testFileSystem
          .file(testFileSystem.path.join('assets', 'wild', 'dash.txt'))
          .createSync(recursive: true);
      testFileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
  deferred-components:
    - name: component1
      assets:
        - assets/bar/barbie.txt
        - assets/wild/
''');
      final AssetBundle bundle = AssetBundleFactory.defaultInstance(
        logger: BufferLogger.test(),
        fileSystem: testFileSystem,
        flutterRoot: getFlutterRoot(),
        platform: platform,
        splitDeferredAssets: true,
      ).createBundle();
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        deferredComponentsEnabled: true,
        targetPlatform: TargetPlatform.tester,
      );
      expect(
        bundle.entries.keys,
        unorderedEquals(<String>[
          'assets/foo/bar.txt',
          'AssetManifest.bin',
          'FontManifest.json',
          'NOTICES.Z',
        ]),
      );
      expect(bundle.deferredComponentsEntries.length, 1);
      expect(bundle.deferredComponentsEntries['component1']!.length, 2);
      expect(bundle.needsBuild(), false);

      // Simulate modifying the files by updating the filestat time manually.
      testFileSystem.file(testFileSystem.path.join('assets', 'wild', 'fizz.txt'))
        ..createSync(recursive: true)
        ..setLastModifiedSync(packageFile.lastModifiedSync().add(const Duration(hours: 1)));

      expect(bundle.needsBuild(), true);
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        deferredComponentsEnabled: true,
        targetPlatform: TargetPlatform.tester,
      );

      expect(
        bundle.entries.keys,
        unorderedEquals(<String>[
          'assets/foo/bar.txt',
          'AssetManifest.bin',
          'FontManifest.json',
          'NOTICES.Z',
        ]),
      );
      expect(bundle.deferredComponentsEntries.length, 1);
      expect(bundle.deferredComponentsEntries['component1']!.length, 3);
    });
  });

  group('AssetBundle.build', () {
    testWithoutContext('throws ToolExit when directory entry has an invalid scheme', () async {
      final fileSystem = MemoryFileSystem(style: FileSystemStyle.windows);
      final logger = BufferLogger.test();
      final platform = FakePlatform(operatingSystem: 'windows');
      final String flutterRoot = Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fileSystem,
        userMessages: UserMessages(),
      );

      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - https://mywebsite.com/images/
''');
      final bundle = ManifestAssetBundle(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: flutterRoot,
      );

      expect(
        () => bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          targetPlatform: TargetPlatform.tester,
        ),
        throwsToolExit(
          message:
              'Asset path "https://mywebsite.com/images/" has scheme "https" and is not a valid '
              'file or directory path. Please update this entry in the pubspec.yaml to point to a '
              'valid file path.',
        ),
      );
    });

    testWithoutContext('throws ToolExit when file entry has an invalid scheme', () async {
      final FileSystem fileSystem = MemoryFileSystem(style: FileSystemStyle.windows);
      final logger = BufferLogger.test();
      final platform = FakePlatform(operatingSystem: 'windows');
      final String flutterRoot = Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fileSystem,
        userMessages: UserMessages(),
      );
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - http://website.com/hi.png
''');
      final bundle = ManifestAssetBundle(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: flutterRoot,
      );

      expect(
        () => bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          targetPlatform: TargetPlatform.tester,
        ),
        throwsToolExit(
          message:
              'Asset path "http://website.com/hi.png" has scheme "http" and is not a valid '
              'file or directory path. Please update this entry in the pubspec.yaml to point to a '
              'valid file path.',
        ),
      );
    });

    testWithoutContext("AssetBundleEntry::content::isModified is true when an asset's transformers change in between builds", () async {
      final FileSystem fileSystem = MemoryFileSystem.test();

      fileSystem.file('my-asset.txt').createSync();

      final logger = BufferLogger.test();
      final platform = FakePlatform();
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - path: my-asset.txt
      transformers:
        - package: my-transformer-one
''');
      final bundle = ManifestAssetBundle(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: Cache.defaultFlutterRoot(
          platform: platform,
          fileSystem: fileSystem,
          userMessages: UserMessages(),
        ),
      );

      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        targetPlatform: TargetPlatform.tester,
      );

      expect(bundle.entries['my-asset.txt']!.content.isModified, isTrue);
      bundle.entries['my-asset.txt']!.content.markClean();

      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        targetPlatform: TargetPlatform.tester,
      );

      expect(bundle.entries['my-asset.txt']!.content.isModified, isFalse);

      fileSystem.file('pubspec.yaml').writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - path: my-asset.txt
      transformers:
        - package: my-transformer-one
        - package: my-transformer-two
''');

      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        targetPlatform: TargetPlatform.tester,
      );

      expect(bundle.entries['my-asset.txt']!.content.isModified, isTrue);
    });
  });

  group('AssetBundle.build (web builds)', () {
    late FileSystem testFileSystem;
    late Platform testPlatform;

    setUp(() async {
      testFileSystem = MemoryFileSystem();
      testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync(
        'flutter_asset_bundle_test.',
      );
      testPlatform = FakePlatform();
    });

    testUsingContext(
      'empty pubspec',
      () async {
        testFileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('');

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.web_javascript,
        );

        expect(
          bundle.entries.keys,
          unorderedEquals(<String>['AssetManifest.bin', 'AssetManifest.bin.json']),
        );
        expect(
          utf8.decode(await bundle.entries['AssetManifest.bin.json']!.contentsAsBytes()),
          '""',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => testPlatform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'pubspec contains an asset',
      () async {
        writePackageConfigFiles(directory: testFileSystem.currentDirectory, mainLibName: 'my_app');
        testFileSystem.file('pubspec.yaml').writeAsStringSync(r'''
name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - assets/bar/lizard.png
''');
        testFileSystem
            .file(testFileSystem.path.joinAll(<String>['assets', 'bar', 'lizard.png']))
            .createSync(recursive: true);

        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.web_javascript,
        );

        expect(
          bundle.entries.keys,
          unorderedEquals(<String>[
            'AssetManifest.bin',
            'AssetManifest.bin.json',
            'FontManifest.json',
            'NOTICES', // not .Z
            'assets/bar/lizard.png',
          ]),
        );

        final Uint8List manifestBinJsonBytes = base64.decode(
          json.decode(
            utf8.decode(await bundle.entries['AssetManifest.bin.json']!.contentsAsBytes()),
          ) as String,
        );

        final manifestBinBytes = Uint8List.fromList(
          await bundle.entries['AssetManifest.bin']!.contentsAsBytes(),
        );

        expect(
          manifestBinJsonBytes,
          equals(manifestBinBytes),
          reason: 'JSON-encoded binary content should be identical to BIN file.',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => testPlatform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  testWithoutContext('Failed directory delete shows message', () async {
    final handler = FileExceptionHandler();
    final FileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);
    final logger = BufferLogger.test();

    final Directory directory = fileSystem.directory('foo')..createSync();
    handler.addError(
      directory,
      FileSystemOp.delete,
      const FileSystemException('Expected Error Text'),
    );

    await writeBundle(
      directory,
      const <String, AssetBundleEntry>{},
      buildMode: BuildMode.debug,
      impellerStatus: ImpellerStatus.disabled,
      projectDir: fileSystem.currentDirectory,
      targetPlatform: TargetPlatform.android,
      toolContext: FakeToolContext(fs: fileSystem, logger: logger),
    );

    expect(logger.warningText, contains('Expected Error Text'));
  });

  testWithoutContext(
    'does not unnecessarily recreate asset manifest, font manifest, license',
    () async {
      final fs = MemoryFileSystem.test();
      writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'my_app');
      fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
assets:
  - assets/foo/bar.txt
''');
      final bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: FakePlatform(),
        flutterRoot: getFlutterRoot(),
      );
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      );

      final AssetBundleEntry? fontManifest = bundle.entries['FontManifest.json'];
      final AssetBundleEntry? license = bundle.entries['NOTICES'];

      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      );

      expect(fontManifest, bundle.entries['FontManifest.json']);
      expect(license, bundle.entries['NOTICES']);
    },
  );

  testWithoutContext('inserts dummy file into additionalDependencies when '
      'wildcards are used', () async {
    final fs = MemoryFileSystem.test();
    writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'my_app');
    fs.file(fs.path.join('assets', 'bar.txt')).createSync(recursive: true);
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/
''');
    final bundle = ManifestAssetBundle(
      logger: BufferLogger.test(),
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      0,
    );
    expect(
      bundle.additionalDependencies.single.path,
      contains('DOES_NOT_EXIST_RERUN_FOR_WILDCARD'),
    );
  });

  testWithoutContext('Does not insert dummy file into additionalDependencies '
      'when wildcards are not used', () async {
    final fs = MemoryFileSystem.test();
    writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'my_app');
    fs.file(fs.path.join('assets', 'bar.txt')).createSync(recursive: true);
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/bar.txt
''');
    final bundle = ManifestAssetBundle(
      logger: BufferLogger.test(),
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      0,
    );
    expect(bundle.additionalDependencies, isEmpty);
  });

  group('Shaders: ', () {
    late MemoryFileSystem fileSystem;
    late Artifacts artifacts;
    late String impellerc;
    late Directory output;
    late String assetsPath;
    late String shaderPath;
    late String outputPath;

    setUp(() {
      artifacts = Artifacts.test();
      fileSystem = MemoryFileSystem.test();
      impellerc = artifacts.getHostArtifact(HostArtifact.impellerc).path;

      fileSystem.file(impellerc).createSync(recursive: true);

      output = fileSystem.directory('asset_output')..createSync(recursive: true);
      assetsPath = 'assets';
      shaderPath = fileSystem.path.join(assetsPath, 'shader.frag');
      outputPath = fileSystem.path.join(output.path, assetsPath, 'shader.frag');
      fileSystem.file(shaderPath).createSync(recursive: true);
    });

    testWithoutContext('Including a shader triggers the shader compiler', () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--runtime-stage-gles',
            '--runtime-stage-gles3',
            '--runtime-stage-vulkan',
            '--iplr',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=/$shaderPath',
            '--input-type=frag',
            '--include=/$assetsPath',
            '--include=$shaderLibDir',
          ],
          onRun: (_) {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
      ]);
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
  name: my_app
  flutter:
    shaders:
      - assets/shader.frag
  ''');
      final bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        platform: FakePlatform(),
        flutterRoot: getFlutterRoot(),
      );

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        0,
      );

      await writeBundle(
        output,
        bundle.entries,
        buildMode: BuildMode.debug,
        impellerStatus: ImpellerStatus.disabled,
        projectDir: fileSystem.currentDirectory,
        targetPlatform: TargetPlatform.android,
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: BufferLogger.test(),
          platform: FakePlatform(),
          processManager: processManager,
        ),
      );
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('Included shaders are compiled for the web', () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--iplr',
            '--json',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=/$shaderPath',
            '--input-type=frag',
            '--include=/$assetsPath',
            '--include=$shaderLibDir',
          ],
          onRun: (_) {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
      ]);
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
  name: my_app
  flutter:
    shaders:
      - assets/shader.frag
  ''');
      final bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        platform: FakePlatform(),
        flutterRoot: getFlutterRoot(),
      );

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.web_javascript,
        ),
        0,
      );

      await writeBundle(
        output,
        bundle.entries,
        buildMode: BuildMode.debug,
        impellerStatus: ImpellerStatus.disabled,
        projectDir: fileSystem.currentDirectory,
        targetPlatform: TargetPlatform.web_javascript,
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: BufferLogger.test(),
          platform: FakePlatform(),
          processManager: processManager,
        ),
      );
      expect(processManager.hasRemainingExpectations, false);
    });

    testWithoutContext('Material shaders are compiled for the web', () async {
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');

      final String materialIconsPath = fileSystem.path.join(
        getFlutterRoot(),
        'bin',
        'cache',
        'artifacts',
        'material_fonts',
        'MaterialIcons-Regular.otf',
      );
      fileSystem.file(materialIconsPath).createSync(recursive: true);

      final String flutterRoot = getFlutterRoot();
      fileSystem
          .file(
            fileSystem.path.join(
              flutterRoot,
              'packages',
              'flutter',
              'lib',
              'src',
              'material',
              'shaders',
              'ink_sparkle.frag',
            ),
          )
          .createSync(recursive: true);
      fileSystem
          .file(
            fileSystem.path.join(
              flutterRoot,
              'packages',
              'flutter',
              'lib',
              'src',
              'widgets',
              'shaders',
              'stretch_effect.frag',
            ),
          )
          .createSync(recursive: true);

      final String materialShaderDir = fileSystem.path.join(
        flutterRoot,
        'packages',
        'flutter',
        'lib',
        'src',
        'material',
        'shaders',
      );
      final String widgetsShaderDir = fileSystem.path.join(
        flutterRoot,
        'packages',
        'flutter',
        'lib',
        'src',
        'widgets',
        'shaders',
      );

      final processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--iplr',
            '--json',
            '--sl=${fileSystem.path.join(output.path, 'shaders', 'ink_sparkle.frag')}',
            '--spirv=${fileSystem.path.join(output.path, 'shaders', 'ink_sparkle.frag.spirv')}',
            '--input=${fileSystem.path.join(materialShaderDir, 'ink_sparkle.frag')}',
            '--input-type=frag',
            '--include=$materialShaderDir',
            '--include=$shaderLibDir',
          ],
          onRun: (_) {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--iplr',
            '--json',
            '--sl=${fileSystem.path.join(output.path, 'shaders', 'stretch_effect.frag')}',
            '--spirv=${fileSystem.path.join(output.path, 'shaders', 'stretch_effect.frag.spirv')}',
            '--input=${fileSystem.path.join(widgetsShaderDir, 'stretch_effect.frag')}',
            '--input-type=frag',
            '--include=$widgetsShaderDir',
            '--include=$shaderLibDir',
          ],
          onRun: (_) {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
      ]);

      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
  name: my_app
  flutter:
    uses-material-design: true
  ''');
      final bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        platform: FakePlatform(),
        flutterRoot: flutterRoot,
      );

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.web_javascript,
        ),
        0,
      );

      await writeBundle(
        output,
        bundle.entries,
        buildMode: BuildMode.debug,
        impellerStatus: ImpellerStatus.disabled,
        projectDir: fileSystem.currentDirectory,
        targetPlatform: TargetPlatform.web_javascript,
        toolContext: FakeToolContext(
          artifacts: artifacts,
          fs: fileSystem,
          logger: BufferLogger.test(),
          platform: FakePlatform(),
          processManager: processManager,
        ),
      );
      expect(processManager.hasRemainingExpectations, false);
    });
  });

  testWithoutContext('Does not insert dummy file into additionalDependencies '
      'when wildcards are used by dependencies', () async {
    final fs = MemoryFileSystem.test();
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'foo': 'foo'},
    );
    fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any
''');
    fs.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar/
''');
    final bundle = ManifestAssetBundle(
      logger: BufferLogger.test(),
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );
    fs.file('foo/bar/fizz.txt').createSync(recursive: true);

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      0,
    );
    expect(bundle.additionalDependencies, isEmpty);
  });

  testWithoutContext('does not track wildcard directories from dependencies', () async {
    final fs = MemoryFileSystem.test();
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'foo': 'foo'},
    );
    fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any
''');
    fs.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar/
''');
    final bundle = ManifestAssetBundle(
      logger: BufferLogger.test(),
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );
    fs.file('foo/bar/fizz.txt').createSync(recursive: true);

    await bundle.build(
      packageConfigPath: '.dart_tool/package_config.json',
      targetPlatform: TargetPlatform.tester,
    );

    expect(
      bundle.entries.keys,
      unorderedEquals(<String>[
        'packages/foo/bar/fizz.txt',
        'AssetManifest.bin',
        'FontManifest.json',
        'NOTICES.Z',
      ]),
    );
    expect(bundle.needsBuild(), false);

    // Does not track dependency's wildcard directories.
    fs.file(fs.path.join('assets', 'foo', 'bar.txt')).deleteSync();

    expect(bundle.needsBuild(), false);
  });

  testWithoutContext('reports package that causes asset bundle error when it is '
      'a dependency', () async {
    final fs = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'foo': 'foo'},
    );
    fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any
''');
    fs.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar.txt
''');
    final bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      1,
    );
    expect(logger.errorText, contains('This asset was included from package foo'));
  });

  testWithoutContext('does not report package that causes asset bundle error '
      'when it is from own pubspec', () async {
    final fs = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'foo': 'foo'},
    );
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - bar.txt
''');
    final bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      1,
    );
    expect(logger.errorText, isNot(contains('This asset was included from')));
  });

  testWithoutContext('does not include Material Design assets if uses-material-design: true is '
      'specified only by a dependency', () async {
    final fs = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    writePackageConfigFiles(
      directory: fs.currentDirectory,
      mainLibName: 'my_app',
      packages: <String, String>{'foo': 'foo'},
    );
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any

flutter:
  uses-material-design: false
''');
    fs.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  uses-material-design: true
''');
    final bundle = ManifestAssetBundle(
      logger: logger,
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      0,
    );
    expect((bundle.entries['FontManifest.json']!.content as DevFSStringContent).string, '[]');
    expect(logger.errorText, contains('package:foo has `uses-material-design: true` set'));
  });

  testWithoutContext('does not include assets in project directories as asset variants', () async {
    final fs = MemoryFileSystem.test();
    writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'my_app');
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: my_app

flutter:
  assets:
    - assets/foo.txt
''');
    fs.file('assets/foo.txt').createSync(recursive: true);

    // Potential build artifacts outside of build directory.
    fs.file('linux/flutter/foo.txt').createSync(recursive: true);
    fs.file('windows/flutter/foo.txt').createSync(recursive: true);
    fs.file('windows/CMakeLists.txt').createSync();
    fs.file('macos/Flutter/foo.txt').createSync(recursive: true);
    fs.file('ios/foo.txt').createSync(recursive: true);
    fs.file('build/foo.txt').createSync(recursive: true);

    final bundle = ManifestAssetBundle(
      logger: BufferLogger.test(),
      fileSystem: fs,
      platform: FakePlatform(),
      flutterRoot: getFlutterRoot(),
    );

    expect(
      await bundle.build(
        packageConfigPath: '.dart_tool/package_config.json',
        targetPlatform: TargetPlatform.tester,
      ),
      0,
    );
    expect(
      bundle.entries.keys,
      unorderedEquals(<String>[
        'assets/foo.txt',
        'AssetManifest.bin',
        'FontManifest.json',
        'NOTICES.Z',
      ]),
    );
  });

  testWithoutContext(
    'deferred and regular assets are included in manifest alphabetically',
    () async {
      final fs = MemoryFileSystem.test();
      writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'my_app');
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app

flutter:
  assets:
    - assets/zebra.jpg
    - assets/foo.jpg

  deferred-components:
    - name: component1
      assets:
        - assets/bar.jpg
        - assets/apple.jpg
''');
      fs.file('assets/foo.jpg').createSync(recursive: true);
      fs.file('assets/bar.jpg').createSync();
      fs.file('assets/apple.jpg').createSync();
      fs.file('assets/zebra.jpg').createSync();
      final bundle = ManifestAssetBundle(
        logger: BufferLogger.test(),
        fileSystem: fs,
        platform: FakePlatform(),
        flutterRoot: getFlutterRoot(),
      );

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        0,
      );
      expect((bundle.entries['FontManifest.json']!.content as DevFSStringContent).string, '[]');
    },
  );

  group('reports error for absolute paths', () {
    Future<void> testCase({
      required String pubspecContents,
      required Uri assetPath,
      required FileSystem fileSystem,
      required Platform platform,
    }) async {
      final logger = BufferLogger.test();
      expect(pubspecContents, contains(assetPath.toString()));
      final String flutterRoot = Cache.defaultFlutterRoot(
        platform: platform,
        fileSystem: fileSystem,
        userMessages: UserMessages(),
      );
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(pubspecContents);

      final bundle = ManifestAssetBundle(
        logger: logger,
        fileSystem: fileSystem,
        platform: platform,
        flutterRoot: flutterRoot,
      );
      expect(
        () => bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          flutterProject: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          targetPlatform: TargetPlatform.tester,
        ),
        throwsToolExit(
          message:
              'is not a valid asset path. Asset paths must be relative to the location of '
              'pubspec.yaml. Please update this entry in the pubspec.yaml to use a relative path.',
        ),
      );
    }

    for (final platform in <FakePlatform>[
      FakePlatform(),
      FakePlatform(operatingSystem: 'windows'),
    ]) {
      group('on ${platform.isWindows ? 'Windows' : 'POSIX'} for', () {
        final FileSystem fileSystem = MemoryFileSystem(
          style: platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
        );
        fileSystem.currentDirectory = fileSystem.systemTempDirectory;
        final assetPath = Uri.file(
          platform.isWindows ? r'c:\asset\path.json' : '/asset/path.json',
          windows: platform.isWindows,
        );
        testWithoutContext('standard assets', () async {
          await testCase(
            pubspecContents:
                '''
name: my_app
flutter:
  assets:
    - $assetPath
''',
            assetPath: assetPath,
            fileSystem: fileSystem,
            platform: platform,
          );
        });

        testWithoutContext('font assets', () async {
          await testCase(
            pubspecContents:
                '''
name: my_app
flutter:
  fonts:
    - family: Foo
      fonts:
        - asset: $assetPath
''',
            assetPath: assetPath,
            fileSystem: fileSystem,
            platform: platform,
          );
        });

        testWithoutContext('shader assets', () async {
          await testCase(
            pubspecContents:
                '''
name: my_app
flutter:
  shaders:
    - $assetPath
''',
            assetPath: assetPath,
            fileSystem: fileSystem,
            platform: platform,
          );
        });
      });
    }
  });
}
