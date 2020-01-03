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
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  group('AssetBundle.build', () {
    FileSystem testFileSystem;

    setUp(() async {
      testFileSystem = MemoryFileSystem(
        style: platform.isWindows
          ? FileSystemStyle.windows
          : FileSystemStyle.posix,
      );
      testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync('flutter_asset_bundle_test.');
    });

    testUsingContext('nonempty', () async {
      final AssetBundle ab = AssetBundleFactory.instance.createBundle();
      expect(await ab.build(), 0);
      expect(ab.entries.length, greaterThan(0));
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('empty pubspec', () async {
      fs.file('pubspec.yaml')
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
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('wildcard directories are updated when filesystem changes', () async {
      final File packageFile = fs.file('.packages')..createSync();
      fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      final AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');
      // Expected assets:
      //  - asset manifest
      //  - font manifest
      //  - license file
      //  - assets/foo/bar.txt
      expect(bundle.entries.length, 4);
      expect(bundle.needsBuild(manifestPath: 'pubspec.yaml'), false);

      // Simulate modifying the files by updating the filestat time manually.
      fs.file(fs.path.join('assets', 'foo', 'fizz.txt'))
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
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('handle removal of wildcard directories', () async {
      fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      final File pubspec = fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      fs.file('.packages').createSync();
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
      fs.directory(fs.path.join('assets', 'foo')).deleteSync(recursive: true);
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example''')
        ..setLastModifiedSync(modifiedTime);

      // touch .packages to make sure its change time is after pubspec.yaml's
      fs.file('.packages')
        ..setLastModifiedSync(modifiedTime);

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
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    // https://github.com/flutter/flutter/issues/42723
    testUsingContext('Test regression for mistyped file', () async {
      fs.file(fs.path.join('assets', 'foo', 'bar.txt')).createSync(recursive: true);
      // Create a directory in the same path to test that we're only looking at File
      // objects.
      fs.directory(fs.path.join('assets', 'foo', 'bar')).createSync();
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example
flutter:
  assets:
    - assets/foo/
''');
      fs.file('.packages').createSync();
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
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  test('Failed directory delete shows message', () async {
    final MockDirectory mockDirectory = MockDirectory();
    final BufferLogger bufferLogger = BufferLogger();
    when(mockDirectory.existsSync()).thenReturn(true);
    when(mockDirectory.deleteSync(recursive: true)).thenThrow(const FileSystemException('ABCD'));

    await writeBundle(mockDirectory, <String, DevFSContent>{}, loggerOverride: bufferLogger);

    verify(mockDirectory.createSync(recursive: true)).called(1);
    expect(bufferLogger.errorText, contains('ABCD'));
  });
}

class MockDirectory extends Mock implements Directory {}
