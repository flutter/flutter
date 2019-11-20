// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/file_hash_store.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
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

  test('Initializes file cache', () => testbed.run(() {
    final FileHashStore fileCache = FileHashStore(environment, fs);
    fileCache.initialize();
    fileCache.persist();

    expect(fs.file(fs.path.join(environment.buildDir.path, '.filecache')).existsSync(), true);

    final Uint8List buffer = fs.file(fs.path.join(environment.buildDir.path, '.filecache'))
        .readAsBytesSync();
    final FileStorage fileStorage = FileStorage.fromBuffer(buffer);

    expect(fileStorage.files, isEmpty);
    expect(fileStorage.version, 2);
  }));

  test('saves and restores to file cache', () => testbed.run(() async {
    final File file = fs.file('foo.dart')
      ..createSync()
      ..writeAsStringSync('hello');
    final FileHashStore fileCache = FileHashStore(environment, fs);
    fileCache.initialize();
    await fileCache.hashFiles(<File>[file]);
    fileCache.persist();
    final String currentHash =  fileCache.currentHashes[file.path];
    final Uint8List buffer = fs.file(fs.path.join(environment.buildDir.path, '.filecache'))
        .readAsBytesSync();
    FileStorage fileStorage = FileStorage.fromBuffer(buffer);

    expect(fileStorage.files.single.hash, currentHash);
    expect(fileStorage.files.single.path, file.path);


    final FileHashStore newFileCache = FileHashStore(environment, fs);
    newFileCache.initialize();
    expect(newFileCache.currentHashes, isEmpty);
    expect(newFileCache.previousHashes['foo.dart'],  currentHash);
    newFileCache.persist();

    // Still persisted correctly.
    fileStorage = FileStorage.fromBuffer(buffer);

    expect(fileStorage.files.single.hash, currentHash);
    expect(fileStorage.files.single.path, file.path);
  }));

  test('handles persisting with a missing build directory', () => testbed.run(() async {
    final File file = fs.file('foo.dart')
      ..createSync()
      ..writeAsStringSync('hello');
    final FileHashStore fileCache = FileHashStore(environment, fs);
    fileCache.initialize();
    environment.buildDir.deleteSync(recursive: true);

    await fileCache.hashFiles(<File>[file]);
    // Does not throw.
    fileCache.persist();
  }));

  test('handles hashing missing files', () => testbed.run(() async {
    final FileHashStore fileCache = FileHashStore(environment, fs);
    fileCache.initialize();

    final List<File> results = await fileCache.hashFiles(<File>[fs.file('hello.dart')]);

    expect(results, hasLength(1));
    expect(results.single.path, 'hello.dart');
    expect(fileCache.currentHashes, isNot(contains(fs.path.absolute('hello.dart'))));
  }));

  test('handles failure to persist file cache', () => testbed.run(() async {
    final FakeForwardingFileSystem fakeForwardingFileSystem = FakeForwardingFileSystem(fs);
    final FileHashStore fileCache = FileHashStore(environment, fakeForwardingFileSystem);
    final String cacheFile = environment.buildDir.childFile('.filecache').path;
    final MockFile mockFile = MockFile();
    when(mockFile.writeAsBytesSync(any)).thenThrow(const FileSystemException('Out of space!'));
    when(mockFile.existsSync()).thenReturn(true);

    fileCache.initialize();
    fakeForwardingFileSystem.files[cacheFile] = mockFile;
    fileCache.persist();

    expect(testLogger.errorText, contains('Out of space!'));
  }));

  test('handles failure to restore file cache', () => testbed.run(() async {
    final FakeForwardingFileSystem fakeForwardingFileSystem = FakeForwardingFileSystem(fs);
    final FileHashStore fileCache = FileHashStore(environment, fakeForwardingFileSystem);
    final String cacheFile = environment.buildDir.childFile('.filecache').path;
    final MockFile mockFile = MockFile();
    when(mockFile.readAsBytesSync()).thenThrow(const FileSystemException('Out of space!'));
    when(mockFile.existsSync()).thenReturn(true);

    fakeForwardingFileSystem.files[cacheFile] = mockFile;
    fileCache.initialize();

    expect(testLogger.errorText, contains('Out of space!'));
  }));
}

class FakeForwardingFileSystem extends ForwardingFileSystem {
  FakeForwardingFileSystem(FileSystem fileSystem) : super(fileSystem);

  final Map<String, File> files = <String, File>{};

  @override
  File file(dynamic path) => files[path] ?? super.file(path);
}
class MockFile extends Mock implements File {}
