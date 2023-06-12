// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file/src/backends/memory/memory_random_access_file.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('MemoryFileSystem unix style', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    runCommonTests(() => fs);

    group('toString', () {
      test('File', () {
        expect(fs.file('/foo').toString(), "MemoryFile: '/foo'");
      });

      test('Directory', () {
        expect(fs.directory('/foo').toString(), "MemoryDirectory: '/foo'");
      });

      test('Link', () {
        expect(fs.link('/foo').toString(), "MemoryLink: '/foo'");
      });
    });
  });

  group('MemoryFileSystem windows style', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem(style: FileSystemStyle.windows);
    });

    runCommonTests(
      () => fs,
      root: () => fs.style.root,
    );

    group('toString', () {
      test('File', () {
        expect(fs.file('C:\\foo').toString(), "MemoryFile: 'C:\\foo'");
      });

      test('Directory', () {
        expect(
            fs.directory('C:\\foo').toString(), "MemoryDirectory: 'C:\\foo'");
      });

      test('Link', () {
        expect(fs.link('C:\\foo').toString(), "MemoryLink: 'C:\\foo'");
      });
    });
  });

  test('MemoryFileSystem.test', () {
    final MemoryFileSystem fs =
        MemoryFileSystem.test(); // creates root directory
    fs.file('/test1.txt').createSync(); // creates file
    fs.file('/test2.txt').createSync(); // creates file
    expect(fs.directory('/').statSync().modified, DateTime(2000, 1, 1, 0, 1));
    expect(
        fs.file('/test1.txt').statSync().modified, DateTime(2000, 1, 1, 0, 2));
    expect(
        fs.file('/test2.txt').statSync().modified, DateTime(2000, 1, 1, 0, 3));
    fs.file('/test1.txt').createSync();
    fs.file('/test2.txt').createSync();
    expect(fs.file('/test1.txt').statSync().modified,
        DateTime(2000, 1, 1, 0, 2)); // file already existed
    expect(fs.file('/test2.txt').statSync().modified,
        DateTime(2000, 1, 1, 0, 3)); // file already existed
    fs.file('/test1.txt').writeAsStringSync('test'); // touches file
    expect(
        fs.file('/test1.txt').statSync().modified, DateTime(2000, 1, 1, 0, 4));
    expect(fs.file('/test2.txt').statSync().modified,
        DateTime(2000, 1, 1, 0, 3)); // didn't touch it
    fs.file('/test1.txt').copySync(
        '/test2.txt'); // creates file, then mutates file (so time changes twice)
    expect(fs.file('/test1.txt').statSync().modified,
        DateTime(2000, 1, 1, 0, 4)); // didn't touch it
    expect(
        fs.file('/test2.txt').statSync().modified, DateTime(2000, 1, 1, 0, 6));
  });

  test('MemoryFile.openSync returns a MemoryRandomAccessFile', () async {
    final MemoryFileSystem fs = MemoryFileSystem.test();
    final io.File file = fs.file('/test1')..createSync();

    io.RandomAccessFile raf = file.openSync();
    try {
      expect(raf, isA<MemoryRandomAccessFile>());
    } finally {
      raf.closeSync();
    }

    raf = await file.open();
    try {
      expect(raf, isA<MemoryRandomAccessFile>());
    } finally {
      raf.closeSync();
    }
  });

  test('MemoryFileSystem.systemTempDirectory test', () {
    final MemoryFileSystem fs = MemoryFileSystem.test();

    final io.Directory fooA = fs.systemTempDirectory.createTempSync('foo');
    final io.Directory fooB = fs.systemTempDirectory.createTempSync('foo');

    expect(fooA.path, '/.tmp_rand0/foorand0');
    expect(fooB.path, '/.tmp_rand0/foorand1');

    final MemoryFileSystem secondFs = MemoryFileSystem.test();

    final io.Directory fooAA =
        secondFs.systemTempDirectory.createTempSync('foo');
    final io.Directory fooBB =
        secondFs.systemTempDirectory.createTempSync('foo');

    // Names are recycled with a new instance
    expect(fooAA.path, '/.tmp_rand0/foorand0');
    expect(fooBB.path, '/.tmp_rand0/foorand1');
  });

  test('Failed UTF8 decoding in MemoryFileSystem throws a FileSystemException',
      () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('foo')
      ..writeAsBytesSync(<int>[0xFFFE]); // Invalid UTF8

    expect(file.readAsStringSync, throwsA(isA<FileSystemException>()));
  });

  test('Creating a temporary directory actually creates the directory', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Directory tempDir = fileSystem.currentDirectory.createTempSync('foo');

    expect(tempDir.existsSync(), true);
  });
}
