// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('Read operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.read) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    final File file = fs.file('test')..createSync();

    await file.readAsBytes();
    file.readAsBytesSync();
    await file.readAsString();
    file.readAsStringSync();

    expect(contexts, <String>['test', 'test', 'test', 'test']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.read,
      FileSystemOp.read,
      FileSystemOp.read,
      FileSystemOp.read
    ]);
  });

  test('Write operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.write) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    final File file = fs.file('test')..createSync();

    await file.writeAsBytes(<int>[]);
    file.writeAsBytesSync(<int>[]);
    await file.writeAsString('');
    file.writeAsStringSync('');

    expect(contexts, <String>['test', 'test', 'test', 'test']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.write,
      FileSystemOp.write,
      FileSystemOp.write,
      FileSystemOp.write
    ]);
  });

  test('Delete operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.delete) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    final File file = fs.file('test')..createSync();
    final Directory directory = fs.directory('testDir')..createSync();
    final Link link = fs.link('testLink')..createSync('foo');

    await file.delete();
    file.createSync();
    file.deleteSync();

    await directory.delete();
    directory.createSync();
    directory.deleteSync();

    await link.delete();
    link.createSync('foo');
    link.deleteSync();

    expect(contexts,
        <String>['test', 'test', 'testDir', 'testDir', 'testLink', 'testLink']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.delete,
      FileSystemOp.delete,
      FileSystemOp.delete,
      FileSystemOp.delete,
      FileSystemOp.delete,
      FileSystemOp.delete,
    ]);
  });

  test('Create operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.create) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    fs.file('testA').createSync();
    await fs.file('testB').create();
    fs.directory('testDirA').createSync();
    await fs.directory('testDirB').create();
    fs.link('testLinkA').createSync('foo');
    await fs.link('testLinkB').create('foo');
    fs.currentDirectory.createTempSync('tmp.bar');
    await fs.currentDirectory.createTemp('tmp.bar');

    expect(contexts, <dynamic>[
      'testA',
      'testB',
      'testDirA',
      'testDirB',
      'testLinkA',
      'testLinkB',
      startsWith('/tmp.bar'),
      startsWith('/tmp.bar'),
    ]);
    expect(operations, <FileSystemOp>[
      FileSystemOp.create,
      FileSystemOp.create,
      FileSystemOp.create,
      FileSystemOp.create,
      FileSystemOp.create,
      FileSystemOp.create,
      FileSystemOp.create,
      FileSystemOp.create,
    ]);
  });

  test('Open operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.open) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    final File file = fs.file('test')..createSync();

    await file.open();
    file.openSync();
    file.openRead();
    file.openWrite();

    expect(contexts, <String>['test', 'test', 'test', 'test']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.open,
      FileSystemOp.open,
      FileSystemOp.open,
      FileSystemOp.open,
    ]);
  });

  test('Copy operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.copy) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    final File file = fs.file('test')..createSync();

    await file.copy('A');
    file.copySync('B');

    expect(contexts, <String>['test', 'test']);
    expect(operations, <FileSystemOp>[
      FileSystemOp.copy,
      FileSystemOp.copy,
    ]);
  });

  test('Exists operations invoke opHandle', () async {
    List<String> contexts = <String>[];
    List<FileSystemOp> operations = <FileSystemOp>[];
    MemoryFileSystem fs = MemoryFileSystem.test(
        opHandle: (String context, FileSystemOp operation) {
      if (operation == FileSystemOp.exists) {
        contexts.add(context);
        operations.add(operation);
      }
    });
    fs.file('testA').existsSync();
    await fs.file('testB').exists();
    fs.directory('testDirA').existsSync();
    await fs.directory('testDirB').exists();
    fs.link('testLinkA').existsSync();
    await fs.link('testLinkB').exists();

    expect(contexts, <dynamic>[
      'testA',
      'testB',
      'testDirA',
      'testDirB',
      'testLinkA',
      'testLinkB',
    ]);
    expect(operations, <FileSystemOp>[
      FileSystemOp.exists,
      FileSystemOp.exists,
      FileSystemOp.exists,
      FileSystemOp.exists,
      FileSystemOp.exists,
      FileSystemOp.exists,
    ]);
  });

  test('FileSystemOp toString', () {
    expect(FileSystemOp.create.toString(), 'FileSystemOp.create');
    expect(FileSystemOp.delete.toString(), 'FileSystemOp.delete');
    expect(FileSystemOp.read.toString(), 'FileSystemOp.read');
    expect(FileSystemOp.write.toString(), 'FileSystemOp.write');
    expect(FileSystemOp.exists.toString(), 'FileSystemOp.exists');
  });
}
