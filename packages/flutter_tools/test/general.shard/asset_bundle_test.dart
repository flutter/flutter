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
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';


final Platform platform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{},
);

void main() {
  FileSystem fileSystem;

  setUp(() async {
    fileSystem = MemoryFileSystem();
  });

  group('AssetBundle.build', () {

    testUsingContext('nonempty', () async {
      final AssetBundle ab = AssetBundleFactory.instance.createBundle();
      expect(await ab.build(), 0);
      expect(ab.entries.length, greaterThan(0));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
    });

    testUsingContext('empty pubspec', () async {
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('');

      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      expect(bundle.entries.length, 1);
      const String expectedAssetManifest = '{}';
      expect(
        utf8.decode(await bundle.entries['AssetManifest.json'].contentsAsBytes()),
        expectedAssetManifest,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
    });

    testUsingContext('wildcard directories are updated when filesystem changes', () async {
      final File packageFile = fileSystem.file('.packages')
        ..createSync()
        ..writeAsStringSync('\n');
      fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml', packagesPath: '.packages');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), false);

      // Simulate modifying the files by updating the filestat time manually.
      fileSystem.file(fileSystem.path.join('assets', 'foo', 'fizz.txt'))
        ..createSync(recursive: true)
        ..setLastModifiedSync(packageFile.lastModifiedSync().add(const Duration(hours: 1)));

      expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), true);
      await bundle.build(manifestPath: 'pubspec.yaml');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      //  - assets/foo/fizz.txt
      expect(bundle.entries.length, 5);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
    });

    testUsingContext('handle removal of wildcard directories', () async {
      fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      final File pubspec = fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      fileSystem.file('.packages').createSync();
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), false);

      // Delete the wildcard directory and update pubspec file.
      final DateTime modifiedTime = pubspec.lastModifiedSync().add(const Duration(hours: 1));
      fileSystem.directory(fileSystem.path.join('assets', 'foo')).deleteSync(recursive: true);
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example''')
        ..setLastModifiedSync(modifiedTime);

      // touch .packages to make sure its change time is after pubspec.yaml's
      fileSystem.file('.packages')
        .setLastModifiedSync(modifiedTime);

      // Even though the previous file was removed, it is left in the
      // asset manifest and not updated. This is due to the devfs not
      // supporting file deletion.
      expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), true);
      await bundle.build(manifestPath: 'pubspec.yaml');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
    });

    // https://github.com/flutter/flutter/issues/42723
    testUsingContext('Test regression for mistyped file', () async {
      fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      // Create a directory in the same path to test that we're only looking at File
      // objects.
      fileSystem.directory(fileSystem.path.join('assets', 'foo', 'bar')).createSync();
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      fileSystem.file('.packages').createSync();
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
    });
  });

  testUsingContext('Failed directory delete shows message', () async {
    final MockDirectory mockDirectory = MockDirectory();
    when(mockDirectory.existsSync()).thenReturn(true);
    when(mockDirectory.deleteSync(recursive: true)).thenThrow(const FileSystemException('ABCD'));

    await writeBundle(mockDirectory, <String, DevFSContent>{}, loggerOverride: testLogger);

    verify(mockDirectory.createSync(recursive: true)).called(1);
    expect(testLogger.errorText, contains('ABCD'));
  });

  testUsingContext('does not unnecessarily recreate asset manifest, font manifest, license', () async {
    fileSystem.file('.packages').writeAsStringSync('\n');
    fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
assets:
  - assets/foo/bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    await bundle.build(manifestPath: 'pubspec.yaml');

    final DevFSStringContent assetManifest = bundle.entries['AssetManifest.json']
      as DevFSStringContent;
    final DevFSStringContent fontManifest = bundle.entries['FontManifest.json']
      as DevFSStringContent;
    final DevFSStringContent license = bundle.entries['NOTICES']
      as DevFSStringContent;

    await bundle.build(manifestPath: 'pubspec.yaml');

    expect(assetManifest, bundle.entries['AssetManifest.json']);
    expect(fontManifest, bundle.entries['FontManifest.json']);
    expect(license, bundle.entries['NOTICES']);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('inserts dummy file into additionalDependencies when '
    'wildcards are used', () async {
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('assets', 'bar.txt')).createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(manifestPath: 'pubspec.yaml'), 0);
    expect(bundle.additionalDependencies.single.path, contains('DOES_NOT_EXIST_RERUN_FOR_WILDCARD'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('Does not insert dummy file into additionalDependencies '
    'when wildcards are not used', () async {
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('assets', 'bar.txt')).createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(manifestPath: 'pubspec.yaml'), 0);
    expect(bundle.additionalDependencies, isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('Does not insert dummy file into additionalDependencies '
    'when wildcards are used by dependencies', () async {
    fileSystem.file('.packages').writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt'))
      .createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
dependencies:
  foo: any
''');
    fileSystem.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar/
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    fileSystem.file('foo/bar/fizz.txt').createSync(recursive: true);

    expect(await bundle.build(manifestPath: 'pubspec.yaml'), 0);
    expect(bundle.additionalDependencies, isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('does not track wildcard directories from dependencies', () async {
    final File packagesFile = fileSystem.file('.packages')
      ..writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt'))
      .createSync(recursive: true);
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
dependencies:
  foo: any
''');
    fileSystem.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar/
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
    fileSystem.file('foo/bar/fizz.txt').createSync(recursive: true);

    await bundle.build(
      manifestPath: 'pubspec.yaml',
      packagesPath: packagesFile.path,
    );

    expect(bundle.entries, hasLength(4));
    expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), false);

    // Does not track dependency's wildcard directories.
    fileSystem.file(fileSystem.path.join('assets', 'foo', 'bar.txt'))
      .deleteSync();

    expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('reports package that causes asset bundle error when it is '
    'a dependency', () async {
    final File packagesFile = fileSystem.file('.packages')
      ..writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
dependencies:
  foo: any
''');
    fileSystem.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  assets:
    - bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(
      manifestPath: 'pubspec.yaml',
      packagesPath: packagesFile.path,
    ), 1);
    expect(testLogger.errorText, contains('This asset was included from package foo'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('does not report package that causes asset bundle error '
    'when it is from own pubspec', () async {
     final File packagesFile = fileSystem.file('.packages')
      ..writeAsStringSync(r'''
example:lib/
''');
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - bar.txt
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(
      manifestPath: 'pubspec.yaml',
      packagesPath: packagesFile.path,
    ), 1);
    expect(testLogger.errorText, isNot(contains('This asset was included from')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
  });

  testUsingContext('does not include material design assets if uses-material-design: true is '
    'specified only by a dependency', () async {
    final File packagesFile = fileSystem.file('.packages')
      ..writeAsStringSync(r'''
example:lib/
foo:foo/lib/
''');
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
dependencies:
  foo: any

flutter:
  uses-material-design: false
''');
    fileSystem.file('foo/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
name: foo

flutter:
  uses-material-design: true
''');
    final AssetBundle bundle = AssetBundleFactory.instance.createBundle();

    expect(await bundle.build(
      manifestPath: 'pubspec.yaml',
      packagesPath: packagesFile.path,
    ), 0);
    expect((bundle.entries['FontManifest.json'] as DevFSStringContent).string, '[]');
    expect((bundle.entries['AssetManifest.json'] as DevFSStringContent).string, '{}');
    expect(testLogger.errorText, contains(
      'package:foo has `uses-material-design: true` set'
    ));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => platform,
    Logger: () => BufferLogger.test(),
  });
}

class MockDirectory extends Mock implements Directory {}
