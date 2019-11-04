// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/filestore.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  Environment environment;

  setUp(() {
    testbed = Testbed(setup: () {
      fs.directory('build').createSync();
      environment = Environment(
        outputDir: fs.currentDirectory,
        projectDir: fs.currentDirectory,
      );
      environment.buildDir.createSync(recursive: true);
    });
  });

  for (bool timestampMode in <bool>[true, false]) {
    test('Initializes file store with timestampmode:$timestampMode', () => testbed.run(() {
      final FileStore filestore = FileStore.create(environment, fs, timestampMode);
      filestore.initialize();
      filestore.persist();

      expect(fs.file(fs.path.join(environment.buildDir.path, '.filecache')).existsSync(), true);

      final List<int> buffer = fs.file(fs.path.join(environment.buildDir.path, '.filecache'))
          .readAsBytesSync();
      final FileStorage fileStorage = FileStorage.fromBuffer(buffer);

      expect(fileStorage.files, isEmpty);
      expect(fileStorage.version, 2);
    }));

    test('saves and restores to file store with timestampmode:$timestampMode', () => testbed.run(() async {
      final File file = fs.file('foo.dart')
        ..createSync()
        ..writeAsStringSync('hello');
      final FileStore filestore = FileStore.create(environment, fs, timestampMode);
      filestore.initialize();
      await filestore.updateFiles(<File>[file]);
      filestore.persist();
      final String currentHash =  filestore.currentStamps[file.path];
      final List<int> buffer = fs.file(fs.path.join(environment.buildDir.path, '.filecache'))
          .readAsBytesSync();
      FileStorage fileStorage = FileStorage.fromBuffer(buffer);

      expect(fileStorage.files.single.hash, currentHash);
      expect(fileStorage.files.single.path, file.path);


      final FileStore newFileCache = FileStore.create(environment, fs, timestampMode);
      newFileCache.initialize();
      expect(newFileCache.currentStamps, isEmpty);
      expect(newFileCache.previousStamps['foo.dart'],  currentHash);
      newFileCache.persist();

      // Still persisted correctly.
      fileStorage = FileStorage.fromBuffer(buffer);

      expect(fileStorage.files.single.hash, currentHash);
      expect(fileStorage.files.single.path, file.path);
    }));

    test('handles persisting with a missing build directory with timestampmode:$timestampMode', () => testbed.run(() async {
      final File file = fs.file('foo.dart')
        ..createSync()
        ..writeAsStringSync('hello');
      final FileStore filestore = FileStore.create(environment, fs, timestampMode);
      filestore.initialize();
      environment.buildDir.deleteSync(recursive: true);

      await filestore.updateFiles(<File>[file]);
      // Does not throw.
      filestore.persist();
    }));

    test('handles hashing missing files with timestampmode:$timestampMode', () => testbed.run(() async {
      final FileStore filestore = FileStore.create(environment, fs, timestampMode);
      filestore.initialize();

      final List<File> results = await filestore.updateFiles(<File>[fs.file('hello.dart')]);

      expect(results, hasLength(1));
      expect(results.single.path, 'hello.dart');
      expect(filestore.currentStamps, isNot(contains(fs.path.absolute('hello.dart'))));
    }));

    test('handles failure to persist file store with timestampmode:$timestampMode', () => testbed.run(() async {
      final BufferLogger bufferLogger = logger;
      final FakeForwardingFileSystem fakeForwardingFileSystem = FakeForwardingFileSystem(fs);
      final FileStore filestore = FileStore.create(environment, fakeForwardingFileSystem, timestampMode);
      final String cacheFile = environment.buildDir.childFile('.filecache').path;
      final MockFile mockFile = MockFile();
      when(mockFile.writeAsBytesSync(any)).thenThrow(const FileSystemException('Out of space!'));
      when(mockFile.existsSync()).thenReturn(true);

      filestore.initialize();
      fakeForwardingFileSystem.files[cacheFile] = mockFile;
      filestore.persist();

      expect(bufferLogger.errorText, contains('Out of space!'));
    }));

    test('handles failure to restore file store with timestampmode:$timestampMode', () => testbed.run(() async {
      final BufferLogger bufferLogger = logger;
      final FakeForwardingFileSystem fakeForwardingFileSystem = FakeForwardingFileSystem(fs);
      final FileStore filestore = FileStore.create(environment, fakeForwardingFileSystem, timestampMode);
      final String cacheFile = environment.buildDir.childFile('.filecache').path;
      final MockFile mockFile = MockFile();
      when(mockFile.readAsBytesSync()).thenThrow(const FileSystemException('Out of space!'));
      when(mockFile.existsSync()).thenReturn(true);

      fakeForwardingFileSystem.files[cacheFile] = mockFile;
      filestore.initialize();

      expect(bufferLogger.errorText, contains('Out of space!'));
    }));
  }
}

class FakeForwardingFileSystem extends ForwardingFileSystem {
  FakeForwardingFileSystem(FileSystem fileSystem) : super(fileSystem);

  final Map<String, FileSystemEntity> files = <String, FileSystemEntity>{};

  @override
  File file(dynamic path) => files[path] ?? super.file(path);
}
class MockFile extends Mock implements File {}
