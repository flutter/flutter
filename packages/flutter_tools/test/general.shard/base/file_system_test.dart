// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('fsUtils', () {
    MemoryFileSystem fs;
    FileSystemUtils fsUtils;

    setUp(() {
      fs = MemoryFileSystem();
      fsUtils = FileSystemUtils(
        fileSystem: fs,
        platform: FakePlatform(),
      );
    });

    testWithoutContext('ensureDirectoryExists recursively creates a directory if it does not exist', () async {
      fsUtils.ensureDirectoryExists('foo/bar/baz.flx');
      expect(fs.isDirectorySync('foo/bar'), true);
    });

    testWithoutContext('ensureDirectoryExists throws tool exit on failure to create', () async {
      fs.file('foo').createSync();
      expect(() => fsUtils.ensureDirectoryExists('foo/bar.flx'), throwsToolExit());
    });

    testWithoutContext('getUniqueFile creates a unique file name', () async {
      final File fileA = fsUtils.getUniqueFile(fs.currentDirectory, 'foo', 'json')
        ..createSync();
      final File fileB = fsUtils.getUniqueFile(fs.currentDirectory, 'foo', 'json');

      expect(fileA.path, '/foo_01.json');
      expect(fileB.path, '/foo_02.json');
    });

    testWithoutContext('getUniqueDirectory creates a unique directory name', () async {
      final Directory directoryA = fsUtils.getUniqueDirectory(fs.currentDirectory, 'foo')
        ..createSync();
      final Directory directoryB = fsUtils.getUniqueDirectory(fs.currentDirectory, 'foo');

      expect(directoryA.path, '/foo_01');
      expect(directoryB.path, '/foo_02');
    });
  });

  group('copyDirectorySync', () {
    /// Test file_systems.copyDirectorySync() using MemoryFileSystem.
    /// Copies between 2 instances of file systems which is also supported by copyDirectorySync().
    testWithoutContext('test directory copy', () async {
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

      final FileSystemUtils fsUtils = FileSystemUtils(
        fileSystem: sourceMemoryFs,
        platform: FakePlatform(),
      );
      fsUtils.copyDirectorySync(sourceDirectory, targetDirectory);

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

    testWithoutContext('Skip files if shouldCopyFile returns false', () {
      final MemoryFileSystem fileSystem = MemoryFileSystem();
      final FileSystemUtils fsUtils = FileSystemUtils(
        fileSystem: fileSystem,
        platform: FakePlatform(),
      );
      final Directory origin = fileSystem.directory('/origin');
      origin.createSync();
      fileSystem.file(fileSystem.path.join('origin', 'a.txt')).writeAsStringSync('irrelevant');
      fileSystem.directory('/origin/nested').createSync();
      fileSystem.file(fileSystem.path.join('origin', 'nested', 'a.txt')).writeAsStringSync('irrelevant');
      fileSystem.file(fileSystem.path.join('origin', 'nested', 'b.txt')).writeAsStringSync('irrelevant');

      final Directory destination = fileSystem.directory('/destination');
      fsUtils.copyDirectorySync(origin, destination, shouldCopyFile: (File origin, File dest) {
        return origin.basename == 'b.txt';
      });

      expect(destination.existsSync(), isTrue);
      expect(destination.childDirectory('nested').existsSync(), isTrue);
      expect(destination.childDirectory('nested').childFile('b.txt').existsSync(), isTrue);

      expect(destination.childFile('a.txt').existsSync(), isFalse);
      expect(destination.childDirectory('nested').childFile('a.txt').existsSync(), isFalse);
    });
  });

  group('escapePath', () {
    testWithoutContext('on Windows', () {
      final MemoryFileSystem fileSystem = MemoryFileSystem();
      final FileSystemUtils fsUtils = FileSystemUtils(
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'windows'),
      );
      expect(fsUtils.escapePath(r'C:\foo\bar\cool.dart'), r'C:\\foo\\bar\\cool.dart');
      expect(fsUtils.escapePath(r'foo\bar\cool.dart'), r'foo\\bar\\cool.dart');
      expect(fsUtils.escapePath('C:/foo/bar/cool.dart'), 'C:/foo/bar/cool.dart');
    });

    testWithoutContext('on Linux', () {
      final MemoryFileSystem fileSystem = MemoryFileSystem();
      final FileSystemUtils fsUtils = FileSystemUtils(
        fileSystem: fileSystem,
        platform: FakePlatform(operatingSystem: 'linux'),
      );
      expect(fsUtils.escapePath('/foo/bar/cool.dart'), '/foo/bar/cool.dart');
      expect(fsUtils.escapePath('foo/bar/cool.dart'), 'foo/bar/cool.dart');
      expect(fsUtils.escapePath(r'foo\cool.dart'), r'foo\cool.dart');
    });
  });

  group('LocalFileSystem', () {
    MockIoProcessSignal mockSignal;
    ProcessSignal signalUnderTest;
    StreamController<io.ProcessSignal> controller;

    setUp(() {
      mockSignal = MockIoProcessSignal();
      signalUnderTest = ProcessSignal(mockSignal);
      controller = StreamController<io.ProcessSignal>();
      when(mockSignal.watch()).thenAnswer((Invocation invocation) => controller.stream);
    });

    testUsingContext('deletes system temp entry on a fatal signal', () async {
      final Completer<void> completer = Completer<void>();
      final Signals signals = Signals.test();
      final LocalFileSystem localFileSystem = LocalFileSystem.test(
        signals: signals,
        fatalSignals: <ProcessSignal>[signalUnderTest],
      );
      final Directory temp = localFileSystem.systemTempDirectory;

      signals.addHandler(signalUnderTest, (ProcessSignal s) {
        completer.complete();
      });

      expect(temp.existsSync(), isTrue);

      controller.add(mockSignal);
      await completer.future;

      expect(temp.existsSync(), isFalse);
    });
  });
}

class MockIoProcessSignal extends Mock implements io.ProcessSignal {}
