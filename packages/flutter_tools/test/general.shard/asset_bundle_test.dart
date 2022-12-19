// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

const String shaderLibDir = '/./shader_lib';

void main() {
  group('AssetBundle.build', () {
    late FileSystem testFileSystem;

    setUp(() async {
      testFileSystem = MemoryFileSystem(
        style: globals.platform.isWindows
          ? FileSystemStyle.windows
          : FileSystemStyle.posix,
      );
      testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync('flutter_asset_bundle_test.');
    });

    testUsingContext('nonempty', () async {
      final AssetBundle ab = AssetBundleFactory.instance.createBundle();
      expect(await ab.build(packagesPath: '.packages'), 0);
      expect(ab.entries.length, greaterThan(0));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('empty pubspec', () async {
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('');

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(packagesPath: '.packages');
      expect(bundle.entries.length, 1);
      const String expectedAssetManifest = '{}';
      expect(
        utf8.decode(await bundle.entries['AssetManifest.json']!.contentsAsBytes()),
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('wildcard directories are updated when filesystem changes', () async {
      final File packageFile = globals.fs.file('.packages')..createSync();
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(), false);

      // Simulate modifying the files by updating the filestat time manually.
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'fizz.txt'))
        ..createSync(recursive: true)
        ..setLastModifiedSync(packageFile.lastModifiedSync().add(const Duration(hours: 1)));

      expect(bundle.needsBuild(), true);
      await bundle.build(packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      //  - assets/foo/fizz.txt
      expect(bundle.entries.length, 5);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('handle removal of wildcard directories', () async {
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      final File pubspec = globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      globals.fs.file('.packages').createSync();
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(), false);

      // Delete the wildcard directory and update pubspec file.
      final DateTime modifiedTime = pubspec.lastModifiedSync().add(const Duration(hours: 1));
      globals.fs.directory(globals.fs.path.join('assets', 'foo')).deleteSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example''')
        ..setLastModifiedSync(modifiedTime);

      // touch .packages to make sure its change time is after pubspec.yaml's
      globals.fs.file('.packages')
        .setLastModifiedSync(modifiedTime);

      // Even though the previous file was removed, it is left in the
      // asset manifest and not updated. This is due to the devfs not
      // supporting file deletion.
      expect(bundle.needsBuild(), true);
      await bundle.build(packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    // https://github.com/flutter/flutter/issues/42723
    testUsingContext('Test regression for mistyped file', () async {
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      // Create a directory in the same path to test that we're only looking at File
      // objects.
      globals.fs.directory(globals.fs.path.join('assets', 'foo', 'bar')).createSync();
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      globals.fs.file('.packages').createSync();
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('deferred assets are parsed', () async {
      globals.fs.file('.packages').createSync();
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'bar', 'barbie.txt')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'wild', 'dash.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
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
      await bundle.build(packagesPath: '.packages', deferredComponentsEnabled: true);
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.deferredComponentsEntries.length, 1);
      expect(bundle.deferredComponentsEntries['component1']!.length, 2);
      expect(bundle.needsBuild(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('deferred assets are parsed regularly when splitDeferredAssets Disabled', () async {
      globals.fs.file('.packages').createSync();
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'bar', 'barbie.txt')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'wild', 'dash.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
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
      await bundle.build(packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 6);
      expect(bundle.deferredComponentsEntries.isEmpty, true);
      expect(bundle.needsBuild(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('deferred assets wildcard parsed', () async {
      final File packageFile = globals.fs.file('.packages')..createSync();
      globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'bar', 'barbie.txt')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join('assets', 'wild', 'dash.txt')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
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
      await bundle.build(packagesPath: '.packages', deferredComponentsEnabled: true);
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.deferredComponentsEntries.length, 1);
      expect(bundle.deferredComponentsEntries['component1']!.length, 2);
      expect(bundle.needsBuild(), false);

      // Simulate modifying the files by updating the filestat time manually.
      globals.fs.file(globals.fs.path.join('assets', 'wild', 'fizz.txt'))
        ..createSync(recursive: true)
        ..setLastModifiedSync(packageFile.lastModifiedSync().add(const Duration(hours: 1)));

      expect(bundle.needsBuild(), true);
      await bundle.build(packagesPath: '.packages', deferredComponentsEnabled: true);

      expect(bundle.entries.length, 4);
      expect(bundle.deferredComponentsEntries.length, 1);
      expect(bundle.deferredComponentsEntries['component1']!.length, 3);
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  testUsingContext('Failed directory delete shows message', () async {
    final FileExceptionHandler handler = FileExceptionHandler();
    final FileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);

    final Directory directory = fileSystem.directory('foo')
      ..createSync();
    handler.addError(directory, FileSystemOp.delete, const FileSystemException('Expected Error Text'));

    await writeBundle(
      directory,
      <String, DevFSContent>{},
      <String, AssetKind>{},
      loggerOverride: testLogger,
      targetPlatform: TargetPlatform.android,
    );

    expect(testLogger.warningText, contains('Expected Error Text'));
  });

  testUsingContext('does not unnecessarily recreate asset manifest, font manifest, license', () async {
    globals.fs.file('.packages').createSync();
    globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
assets:
  - assets/foo/bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    await bundle.build(packagesPath: '.packages');

    final DevFSStringContent? assetManifest = bundle.entries['AssetManifest.json']
      as DevFSStringContent?;
    final DevFSStringContent? fontManifest = bundle.entries['FontManifest.json']
      as DevFSStringContent?;
    final DevFSStringContent? license = bundle.entries['NOTICES']
      as DevFSStringContent?;

    await bundle.build(packagesPath: '.packages');

    expect(assetManifest, bundle.entries['AssetManifest.json']);
    expect(fontManifest, bundle.entries['FontManifest.json']);
    expect(license, bundle.entries['NOTICES']);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('inserts dummy file into additionalDependencies when '
    'wildcards are used', () async {
    globals.fs.file('.packages').createSync();
    globals.fs.file(globals.fs.path.join('assets', 'bar.txt')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(packagesPath: '.packages'), 0);
    expect(bundle.additionalDependencies.single.path, contains('DOES_NOT_EXIST_RERUN_FOR_WILDCARD'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Does not insert dummy file into additionalDependencies '
    'when wildcards are not used', () async {
    globals.fs.file('.packages').createSync();
    globals.fs.file(globals.fs.path.join('assets', 'bar.txt')).createSync(recursive: true);
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(packagesPath: '.packages'), 0);
    expect(bundle.additionalDependencies, isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
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

    testUsingContext('Including a shader triggers the shader compiler', () async {
      fileSystem.file('.packages').createSync();
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
  name: example
  flutter:
    shaders:
      - assets/shader.frag
  ''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(await bundle.build(packagesPath: '.packages'), 0);

      await writeBundle(
        output,
        bundle.entries,
        bundle.entryKinds,
        loggerOverride: testLogger,
        targetPlatform: TargetPlatform.android,
      );

    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--iplr',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=/$shaderPath',
            '--input-type=frag',
            '--remap-samplers',
            '--include=/$assetsPath',
            '--include=$shaderLibDir',
          ],
          onRun: () {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
      ]),
    });

    testUsingContext('Included shaders are compiled for the web', () async {
      fileSystem.file('.packages').createSync();
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
  name: example
  flutter:
    shaders:
      - assets/shader.frag
  ''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(await bundle.build(packagesPath: '.packages', targetPlatform: TargetPlatform.web_javascript), 0);

      await writeBundle(
        output,
        bundle.entries,
        bundle.entryKinds,
        loggerOverride: testLogger,
        targetPlatform: TargetPlatform.web_javascript,
      );

    }, overrides: <Type, Generator>{
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
          onRun: () {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
      ]),
    });

    testUsingContext('Material shaders are compiled for the web', () async {
      fileSystem.file('.packages').createSync();

      final String materialIconsPath = fileSystem.path.join(
        getFlutterRoot(),
        'bin', 'cache', 'artifacts', 'material_fonts',
        'MaterialIcons-Regular.otf',
      );
      fileSystem.file(materialIconsPath).createSync(recursive: true);

      final String materialPath = fileSystem.path.join(
        getFlutterRoot(),
        'packages', 'flutter', 'lib', 'src', 'material',
      );
      final Directory materialDir = fileSystem.directory(materialPath)..createSync(recursive: true);
      for (final String shader in kMaterialShaders) {
        materialDir.childFile(shader).createSync(recursive: true);
      }

      (globals.processManager as FakeProcessManager)
        .addCommand(FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--iplr',
            '--json',
            '--sl=${fileSystem.path.join(output.path, 'shaders', 'ink_sparkle.frag')}',
            '--spirv=${fileSystem.path.join(output.path, 'shaders', 'ink_sparkle.frag.spirv')}',
            '--input=${fileSystem.path.join(materialDir.path, 'shaders', 'ink_sparkle.frag')}',
            '--input-type=frag',
            '--remap-samplers',
            '--include=${fileSystem.path.join(materialDir.path, 'shaders')}',
            '--include=$shaderLibDir',
          ],
          onRun: () {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ));

      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
  name: example
  flutter:
    uses-material-design: true
  ''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

      expect(await bundle.build(packagesPath: '.packages', targetPlatform: TargetPlatform.web_javascript), 0);

      await writeBundle(
        output,
        bundle.entries,
        bundle.entryKinds,
        loggerOverride: testLogger,
        targetPlatform: TargetPlatform.web_javascript,
      );

    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[]),
    });
  });

  testUsingContext('Does not insert dummy file into additionalDependencies '
    'when wildcards are used by dependencies', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
      .createSync(recursive: true);
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
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

    expect(await bundle.build(packagesPath: '.packages'), 0);
    expect(bundle.additionalDependencies, isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });

  testUsingContext('does not track wildcard directories from dependencies', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
      .createSync(recursive: true);
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
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

    await bundle.build(packagesPath: '.packages');

    expect(bundle.entries, hasLength(4));
    expect(bundle.needsBuild(), false);

    // Does not track dependency's wildcard directories.
    globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
      .deleteSync();

    expect(bundle.needsBuild(), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });

  testUsingContext('reports package that causes asset bundle error when it is '
    'a dependency', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    globals.fs.file(globals.fs.path.join('assets', 'foo', 'bar.txt'))
      .createSync(recursive: true);
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
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

    expect(await bundle.build(packagesPath: '.packages'), 1);
    expect(testLogger.errorText, contains('This asset was included from package foo'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });

  testUsingContext('does not report package that causes asset bundle error '
    'when it is from own pubspec', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
''');
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(packagesPath: '.packages'), 1);
    expect(testLogger.errorText, isNot(contains('This asset was included from')));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });

  testUsingContext('does not include Material Design assets if uses-material-design: true is '
    'specified only by a dependency', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
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

    expect(await bundle.build(packagesPath: '.packages'), 0);
    expect((bundle.entries['FontManifest.json']! as DevFSStringContent).string, '[]');
    expect((bundle.entries['AssetManifest.json']! as DevFSStringContent).string, '{}');
    expect(testLogger.errorText, contains(
      'package:foo has `uses-material-design: true` set'
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });

  testUsingContext('does not include assets in project directories as asset variants', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
''');
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

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

    expect(await bundle.build(packagesPath: '.packages'), 0);
    expect(bundle.entries.length, 4);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });

  testUsingContext('deferred and regular assets are included in manifest alphabetically', () async {
    globals.fs.file('.packages').writeAsStringSync(r'''
example:lib/
''');
    globals.fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

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

    expect(await bundle.build(packagesPath: '.packages'), 0);
    expect((bundle.entries['FontManifest.json']! as DevFSStringContent).string, '[]');
    // The assets from deferred components and regular assets
    // are both included in alphabetical order
    expect((bundle.entries['AssetManifest.json']! as DevFSStringContent).string, '{"assets/apple.jpg":["assets/apple.jpg"],"assets/bar.jpg":["assets/bar.jpg"],"assets/foo.jpg":["assets/foo.jpg"],"assets/zebra.jpg":["assets/zebra.jpg"]}');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => FakePlatform(),
  });
}
