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
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

import '../src/common.dart';
import '../src/context.dart';
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
        globals.fs.file('pubspec.yaml')
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
      'wildcard directories do not include subdirectories',
      () async {
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
        globals.fs.file('pubspec.yaml').writeAsStringSync('''
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
          final File assetFile = globals.fs.file(globals.fs.path.joinAll(asset.split('/')));
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
          directory: globals.fs.currentDirectory,
          mainLibName: 'my_app',
        );

        globals.fs
            .file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        globals.fs.file('pubspec.yaml')
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
        globals.fs.file(globals.fs.path.join('assets', 'foo', 'fizz.txt'))
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
        globals.fs
            .file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        final File pubspec = globals.fs.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
''');
        final File packageConfig = writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
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
        globals.fs.directory(globals.fs.path.join('assets', 'foo')).deleteSync(recursive: true);
        globals.fs.file('pubspec.yaml')
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
        globals.fs
            .file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        // Create a directory in the same path to test that we're only looking at File
        // objects.
        globals.fs.directory(globals.fs.path.join('assets', 'foo', 'bar')).createSync();
        globals.fs.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/foo/
''');
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
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

    testUsingContext(
      'deferred assets are parsed',
      () async {
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
        globals.fs
            .file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        globals.fs
            .file(globals.fs.path.join('assets', 'bar', 'barbie.txt'))
            .createSync(recursive: true);
        globals.fs
            .file(globals.fs.path.join('assets', 'wild', 'dash.txt'))
            .createSync(recursive: true);
        globals.fs.file('pubspec.yaml')
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
          logger: globals.logger,
          fileSystem: globals.fs,
          platform: globals.platform,
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
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'deferred assets are parsed regularly when splitDeferredAssets Disabled',
      () async {
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
        globals.fs
            .file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        globals.fs
            .file(globals.fs.path.join('assets', 'bar', 'barbie.txt'))
            .createSync(recursive: true);
        globals.fs
            .file(globals.fs.path.join('assets', 'wild', 'dash.txt'))
            .createSync(recursive: true);
        globals.fs.file('pubspec.yaml')
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

    testUsingContext(
      'deferred assets wildcard parsed',
      () async {
        final File packageFile = writePackageConfigFiles(
          directory: globals.fs.currentDirectory,
          mainLibName: 'my_app',
        );
        globals.fs
            .file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
            .createSync(recursive: true);
        globals.fs
            .file(globals.fs.path.join('assets', 'bar', 'barbie.txt'))
            .createSync(recursive: true);
        globals.fs
            .file(globals.fs.path.join('assets', 'wild', 'dash.txt'))
            .createSync(recursive: true);
        globals.fs.file('pubspec.yaml')
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
          logger: globals.logger,
          fileSystem: globals.fs,
          platform: globals.platform,
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
        globals.fs.file(globals.fs.path.join('assets', 'wild', 'fizz.txt'))
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
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        Platform: () => platform,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
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

    testWithoutContext(
      "AssetBundleEntry::content::isModified is true when an asset's transformers change in between builds",
      () async {
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
      },
    );
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
        globals.fs.file('pubspec.yaml')
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
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
        globals.fs.file('pubspec.yaml').writeAsStringSync(r'''
name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - assets/bar/lizard.png
''');
        globals.fs
            .file(globals.fs.path.joinAll(<String>['assets', 'bar', 'lizard.png']))
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
              )
              as String,
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

  testUsingContext('Failed directory delete shows message', () async {
    final handler = FileExceptionHandler();
    final FileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);

    final Directory directory = fileSystem.directory('foo')..createSync();
    handler.addError(
      directory,
      FileSystemOp.delete,
      const FileSystemException('Expected Error Text'),
    );

    await writeBundle(
      directory,
      const <String, AssetBundleEntry>{},
      targetPlatform: TargetPlatform.android,
      impellerStatus: ImpellerStatus.disabled,
      processManager: globals.processManager,
      fileSystem: globals.fs,
      artifacts: globals.artifacts!,
      logger: testLogger,
      projectDir: globals.fs.currentDirectory,
      buildMode: BuildMode.debug,
    );

    expect(testLogger.warningText, contains('Expected Error Text'));
  });

  testUsingContext(
    'does not unnecessarily recreate asset manifest, font manifest, license',
    () async {
      writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
assets:
  - assets/foo/bar.txt
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
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
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'inserts dummy file into additionalDependencies when '
    'wildcards are used',
    () async {
      writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
      globals.fs.file(globals.fs.path.join('assets', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

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
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'Does not insert dummy file into additionalDependencies '
    'when wildcards are not used',
    () async {
      writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
      globals.fs.file(globals.fs.path.join('assets', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - assets/bar.txt
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        0,
      );
      expect(bundle.additionalDependencies, isEmpty);
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(),
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

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

    testUsingContext(
      'Including a shader triggers the shader compiler',
      () async {
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
        fileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
  name: my_app
  flutter:
    shaders:
      - assets/shader.frag
  ''');
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

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
          targetPlatform: TargetPlatform.android,
          impellerStatus: ImpellerStatus.disabled,
          processManager: globals.processManager,
          fileSystem: globals.fs,
          artifacts: globals.artifacts!,
          logger: testLogger,
          projectDir: globals.fs.currentDirectory,
          buildMode: BuildMode.debug,
        );
      },
      overrides: <Type, Generator>{
        Artifacts: () => artifacts,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
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
        ]),
      },
    );

    testUsingContext(
      'Included shaders are compiled for the web',
      () async {
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
        fileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
  name: my_app
  flutter:
    shaders:
      - assets/shader.frag
  ''');
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

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
          targetPlatform: TargetPlatform.web_javascript,
          impellerStatus: ImpellerStatus.disabled,
          processManager: globals.processManager,
          fileSystem: globals.fs,
          artifacts: globals.artifacts!,
          logger: testLogger,
          projectDir: globals.fs.currentDirectory,
          buildMode: BuildMode.debug,
        );
      },
      overrides: <Type, Generator>{
        Artifacts: () => artifacts,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
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
        ]),
      },
    );

    testUsingContext(
      'Material shaders are compiled for the web',
      () async {
        writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');

        final String materialIconsPath = fileSystem.path.join(
          getFlutterRoot(),
          'bin',
          'cache',
          'artifacts',
          'material_fonts',
          'MaterialIcons-Regular.otf',
        );
        fileSystem.file(materialIconsPath).createSync(recursive: true);

        final String materialPath = fileSystem.path.join(
          getFlutterRoot(),
          'packages',
          'flutter',
          'lib',
          'src',
          'material',
        );
        final Directory materialDir = fileSystem.directory(materialPath)
          ..createSync(recursive: true);
        for (final String shader in kMaterialShaders) {
          materialDir.childFile(shader).createSync(recursive: true);
        }

        final testShaders = <String>['ink_sparkle.frag', 'stretch_effect.frag'];

        for (final shader in testShaders) {
          (globals.processManager as FakeProcessManager).addCommand(
            FakeCommand(
              command: <String>[
                impellerc,
                '--sksl',
                '--iplr',
                '--json',
                '--sl=${fileSystem.path.join(output.path, 'shaders', shader)}',
                '--spirv=${fileSystem.path.join(output.path, 'shaders', '$shader.spirv')}',
                '--input=${fileSystem.path.join(materialDir.path, 'shaders', shader)}',
                '--input-type=frag',
                '--include=${fileSystem.path.join(materialDir.path, 'shaders')}',
                '--include=$shaderLibDir',
              ],
              onRun: (_) {
                fileSystem.file(outputPath).createSync(recursive: true);
                fileSystem.file('$outputPath.spirv').createSync(recursive: true);
              },
            ),
          );
        }

        fileSystem.file('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync(r'''
  name: my_app
  flutter:
    uses-material-design: true
  ''');
        final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

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
          targetPlatform: TargetPlatform.web_javascript,
          impellerStatus: ImpellerStatus.disabled,
          processManager: globals.processManager,
          fileSystem: globals.fs,
          artifacts: globals.artifacts!,
          logger: testLogger,
          projectDir: globals.fs.currentDirectory,
          buildMode: BuildMode.debug,
        );
        expect((globals.processManager as FakeProcessManager).hasRemainingExpectations, false);
      },
      overrides: <Type, Generator>{
        Artifacts: () => artifacts,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.list(<FakeCommand>[]),
      },
    );
  });

  testUsingContext(
    'Does not insert dummy file into additionalDependencies '
    'when wildcards are used by dependencies',
    () async {
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'foo': 'foo'},
      );
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any
''');
      globals.fs.file('foo/pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar/
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      globals.fs.file('foo/bar/fizz.txt').createSync(recursive: true);

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        0,
      );
      expect(bundle.additionalDependencies, isEmpty);
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
    },
  );

  testUsingContext(
    'does not track wildcard directories from dependencies',
    () async {
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'foo': 'foo'},
      );
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any
''');
      globals.fs.file('foo/pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar/
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      globals.fs.file('foo/bar/fizz.txt').createSync(recursive: true);

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
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).deleteSync();

      expect(bundle.needsBuild(), false);
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
    },
  );

  testUsingContext(
    'reports package that causes asset bundle error when it is '
    'a dependency',
    () async {
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'foo': 'foo'},
      );
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any
''');
      globals.fs.file('foo/pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar.txt
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        1,
      );
      expect(testLogger.errorText, contains('This asset was included from package foo'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
    },
  );

  testUsingContext(
    'does not report package that causes asset bundle error '
    'when it is from own pubspec',
    () async {
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'foo': 'foo'},
      );
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
flutter:
  assets:
    - bar.txt
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        1,
      );
      expect(testLogger.errorText, isNot(contains('This asset was included from')));
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
    },
  );

  testUsingContext(
    'does not include Material Design assets if uses-material-design: true is '
    'specified only by a dependency',
    () async {
      writePackageConfigFiles(
        directory: globals.fs.currentDirectory,
        mainLibName: 'my_app',
        packages: <String, String>{'foo': 'foo'},
      );
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app
dependencies:
  foo: any

flutter:
  uses-material-design: false
''');
      globals.fs.file('foo/pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
name: foo

flutter:
  uses-material-design: true
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        0,
      );
      expect((bundle.entries['FontManifest.json']!.content as DevFSStringContent).string, '[]');
      expect(testLogger.errorText, contains('package:foo has `uses-material-design: true` set'));
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
    },
  );

  testUsingContext(
    'does not include assets in project directories as asset variants',
    () async {
      writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: my_app

flutter:
  assets:
    - assets/foo.txt
''');
      globals.fs.file('assets/foo.txt').createSync(recursive: true);

      // Potential build artifacts outside of build directory.
      globals.fs.file('linux/flutter/foo.txt').createSync(recursive: true);
      globals.fs.file('windows/flutter/foo.txt').createSync(recursive: true);
      globals.fs.file('windows/CMakeLists.txt').createSync();
      globals.fs.file('macos/Flutter/foo.txt').createSync(recursive: true);
      globals.fs.file('ios/foo.txt').createSync(recursive: true);
      globals.fs.file('build/foo.txt').createSync(recursive: true);

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

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
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
    },
  );

  testUsingContext(
    'deferred and regular assets are included in manifest alphabetically',
    () async {
      writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'my_app');
      globals.fs.file('pubspec.yaml')
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
      globals.fs.file('assets/foo.jpg').createSync(recursive: true);
      globals.fs.file('assets/bar.jpg').createSync();
      globals.fs.file('assets/apple.jpg').createSync();
      globals.fs.file('assets/zebra.jpg').createSync();
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(
        await bundle.build(
          packageConfigPath: '.dart_tool/package_config.json',
          targetPlatform: TargetPlatform.tester,
        ),
        0,
      );
      expect((bundle.entries['FontManifest.json']!.content as DevFSStringContent).string, '[]');
    },
    overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => FakePlatform(),
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
