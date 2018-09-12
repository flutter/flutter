// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:platform/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('ensureDirectoryExists', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    testUsingContext('recursively creates a directory if it does not exist', () async {
      ensureDirectoryExists('foo/bar/baz.flx');
      expect(fs.isDirectorySync('foo/bar'), true);
    }, overrides: <Type, Generator>{ FileSystem: () => fs });

    testUsingContext('throws tool exit on failure to create', () async {
      fs.file('foo').createSync();
      expect(() => ensureDirectoryExists('foo/bar.flx'), throwsToolExit());
    }, overrides: <Type, Generator>{ FileSystem: () => fs });
  });

  group('copyDirectorySync', () {
    /// Test file_systems.copyDirectorySync() using MemoryFileSystem.
    /// Copies between 2 instances of file systems which is also supported by copyDirectorySync().
    test('test directory copy', () async {
      final MemoryFileSystem sourceMemoryFs = MemoryFileSystem();
      const String sourcePath = '/some/origin';
      final Directory sourceDirectory = await sourceMemoryFs.directory(sourcePath).create(recursive: true);
      sourceMemoryFs.currentDirectory = sourcePath;
      final File sourceFile1 = sourceMemoryFs.file('some_file.txt')..writeAsStringSync('bleh');
      final DateTime writeTime = sourceFile1.lastModifiedSync();
      sourceMemoryFs.file('sub_dir/another_file.txt').createSync(recursive: true);
      sourceMemoryFs.directory('empty_directory').createSync();

      // Copy to another memory file system instance.
      final MemoryFileSystem targetMemoryFs = MemoryFileSystem();
      const String targetPath = '/some/non-existent/target';
      final Directory targetDirectory = targetMemoryFs.directory(targetPath);
      copyDirectorySync(sourceDirectory, targetDirectory);

      expect(targetDirectory.existsSync(), true);
      targetMemoryFs.currentDirectory = targetPath;
      expect(targetMemoryFs.directory('empty_directory').existsSync(), true);
      expect(targetMemoryFs.file('sub_dir/another_file.txt').existsSync(), true);
      expect(targetMemoryFs.file('some_file.txt').readAsStringSync(), 'bleh');

      // Assert that the copy operation hasn't modified the original file in some way.
      expect(sourceMemoryFs.file('some_file.txt').lastModifiedSync(), writeTime);
      // There's still 3 things in the original directory as there were initially.
      expect(sourceMemoryFs.directory(sourcePath).listSync().length, 3);
    });
  });

  group('canonicalizePath', () {
    test('does not lowercase on Windows', () {
      String path = 'C:\\Foo\\bAr\\cOOL.dart';
      expect(canonicalizePath(path), path);
      // fs.path.canonicalize does lowercase on Windows
      expect(fs.path.canonicalize(path), isNot(path));

      path = '..\\bar\\.\\\\Foo';
      final String expected = fs.path.join(fs.currentDirectory.parent.absolute.path, 'bar', 'Foo');
      expect(canonicalizePath(path), expected);
      // fs.path.canonicalize should return the same result (modulo casing)
      expect(fs.path.canonicalize(path), expected.toLowerCase());
    }, testOn: 'windows');

    test('does not lowercase on posix', () {
      String path = '/Foo/bAr/cOOL.dart';
      expect(canonicalizePath(path), path);
      // fs.path.canonicalize and canonicalizePath should be the same on Posix
      expect(fs.path.canonicalize(path), path);

      path = '../bar/.//Foo';
      final String expected = fs.path.join(fs.currentDirectory.parent.absolute.path, 'bar', 'Foo');
      expect(canonicalizePath(path), expected);
    }, testOn: 'posix');
  });

  group('escapePath', () {
    testUsingContext('on Windows', () {
      expect(escapePath('C:\\foo\\bar\\cool.dart'), 'C:\\\\foo\\\\bar\\\\cool.dart');
      expect(escapePath('foo\\bar\\cool.dart'), 'foo\\\\bar\\\\cool.dart');
      expect(escapePath('C:/foo/bar/cool.dart'), 'C:/foo/bar/cool.dart');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(operatingSystem: 'windows')
    });

    testUsingContext('on Linux', () {
      expect(escapePath('/foo/bar/cool.dart'), '/foo/bar/cool.dart');
      expect(escapePath('foo/bar/cool.dart'), 'foo/bar/cool.dart');
      expect(escapePath('foo\\cool.dart'), 'foo\\cool.dart');
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(operatingSystem: 'linux')
    });
  });
}
