// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io show Directory, File, Link;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import '../bin/bump_version_constraints.dart' as bump;

void main() {
  late MemoryFileSystem fileSystem;
  late Directory flutterRoot;
  late StringBuffer stdout;
  late StringBuffer stderr;
  int? exitCode;

  void mockExit(int code) {
    exitCode = code;
  }

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    flutterRoot = fileSystem.directory('/flutter')..createSync();
    stdout = StringBuffer();
    stderr = StringBuffer();
    exitCode = null;
  });

  test('succeeds with no pubspec files', () {
    bump.run(
      <String>['^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(stdout.toString(), contains('Done. Updated 0 pubspec.yaml files.'));
    expect(stderr.toString(), isEmpty);
  });

  test('updates pubspec.yaml files with correct SDK constraints', () {
    final File pubspec1 = fileSystem.file('/flutter/packages/flutter/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: flutter
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  meta: any
''');

    final File pubspec2 = fileSystem.file('/flutter/packages/flutter_tools/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: flutter_tools
environment:
  sdk: '>=3.10.0 <4.0.0'
''');

    bump.run(
      <String>['^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspec1.readAsStringSync(), '''
name: flutter
environment:
  sdk: ^3.13.0-0
dependencies:
  meta: any
''');
    expect(pubspec2.readAsStringSync(), '''
name: flutter_tools
environment:
  sdk: ^3.13.0-0
''');
    expect(
      stdout.toString(),
      contains('Updated ${fileSystem.path.join('packages', 'flutter', 'pubspec.yaml')}'),
    );
    expect(
      stdout.toString(),
      contains('Updated ${fileSystem.path.join('packages', 'flutter_tools', 'pubspec.yaml')}'),
    );
    expect(stdout.toString(), contains('Done. Updated 2 pubspec.yaml files.'));
    expect(stderr.toString(), isEmpty);
  });

  test('does not update pubspec.yaml if SDK constraint is already correct', () {
    final File pubspec = fileSystem.file('/flutter/packages/flutter/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: flutter
environment:
  sdk: ^3.13.0-0
''');

    bump.run(
      <String>['^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspec.readAsStringSync(), '''
name: flutter
environment:
  sdk: ^3.13.0-0
''');
    expect(stdout.toString(), contains('Done. Updated 0 pubspec.yaml files.'));
    expect(stderr.toString(), isEmpty);
  });

  test('handles environment: without sdk:', () {
    final File pubspec = fileSystem.file('/flutter/packages/flutter/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: flutter
environment:
  foo: bar
''');

    bump.run(
      <String>['^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspec.readAsStringSync(), '''
name: flutter
environment:
  foo: bar
''');
    expect(stdout.toString(), contains('Done. Updated 0 pubspec.yaml files.'));
    expect(stderr.toString(), isEmpty);
  });

  test('ignores pubspec.yaml outside flutterRoot or in dot-directories', () {
    // Hidden dot-directory
    final File pubspecHidden = fileSystem.file('/flutter/.git/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: hidden
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    // Outside flutterRoot
    final File pubspecOutside = fileSystem.file('/bar/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: outside
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    // Inside a build directory
    final File pubspecBuild = fileSystem.file('/flutter/build/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: build_package
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    bump.run(
      <String>['^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspecHidden.readAsStringSync(), contains("  sdk: '>=3.0.0 <4.0.0'\n"));
    expect(pubspecOutside.readAsStringSync(), contains("  sdk: '>=3.0.0 <4.0.0'\n"));
    expect(pubspecBuild.readAsStringSync(), contains("  sdk: '>=3.0.0 <4.0.0'\n"));
    expect(stdout.toString(), contains('Done. Updated 0 pubspec.yaml files.'));
  });

  test('errors out on wrong number of arguments', () {
    bump.run(
      <String>[],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(
      stderr.toString(),
      contains('ERROR: Expected exactly one argument specifying the new SDK constraint.'),
    );
    expect(
      stderr.toString(),
      contains('Usage: dart dev/tools/bin/bump_version_constraints.dart <new_sdk_constraint>'),
    );

    stdout.clear();
    stderr.clear();
    exitCode = null;

    bump.run(
      <String>['^3.13.0-0', 'extra-arg'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(
      stderr.toString(),
      contains('ERROR: Expected exactly one argument specifying the new SDK constraint.'),
    );
  });

  test('continues and exits with 1 when encountering file read/write errors', () {
    final File pubspecGood = fileSystem.file('/flutter/packages/good/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: good
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    fileSystem.file('/flutter/packages/bad/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: bad
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    final FileSystem faultyFileSystem = FaultyFileSystem(fileSystem);

    bump.run(
      <String>['^3.13.0-0'],
      fileSystem: faultyFileSystem,
      flutterRoot: faultyFileSystem.directory('/flutter'),
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(pubspecGood.readAsStringSync(), contains('  sdk: ^3.13.0-0\n'));
    expect(
      stdout.toString(),
      contains('Updated ${fileSystem.path.join('packages', 'good', 'pubspec.yaml')}'),
    );
    expect(stdout.toString(), contains('Done. Updated 1 pubspec.yaml file.'));
    expect(
      stderr.toString(),
      contains('Error updating ${fileSystem.path.join('packages', 'bad', 'pubspec.yaml')}:'),
    );
  });
}

class FaultyFileSystem extends ForwardingFileSystem {
  FaultyFileSystem(super.delegate);

  @override
  File file(dynamic path) => FaultyFile(this, delegate.file(path));

  @override
  Directory directory(dynamic path) => FaultyDirectory(this, delegate.directory(path));
}

class FaultyFile extends ForwardingFileSystemEntity<File, io.File> with ForwardingFile {
  FaultyFile(this._fileSystem, this.delegate);

  final FaultyFileSystem _fileSystem;

  @override
  final io.File delegate;

  @override
  FileSystem get fileSystem => _fileSystem;

  @override
  File wrapFile(io.File delegate) => FaultyFile(_fileSystem, delegate as File);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      FaultyDirectory(_fileSystem, delegate as Directory);

  @override
  Link wrapLink(io.Link delegate) => delegate as Link;

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    if (path.contains('bad')) {
      throw const FileSystemException('Simulated read failure');
    }
    return delegate.readAsLinesSync(encoding: encoding);
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    if (path.contains('bad')) {
      throw const FileSystemException('Simulated read failure');
    }
    return delegate.readAsStringSync(encoding: encoding);
  }

  @override
  void writeAsStringSync(
    String content, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    if (path.contains('bad')) {
      throw const FileSystemException('Simulated write failure');
    }
    delegate.writeAsStringSync(content, mode: mode, encoding: encoding, flush: flush);
  }
}

class FaultyDirectory extends ForwardingFileSystemEntity<Directory, io.Directory>
    with ForwardingDirectory<Directory> {
  FaultyDirectory(this._fileSystem, this.delegate);

  final FaultyFileSystem _fileSystem;

  @override
  final io.Directory delegate;

  @override
  FileSystem get fileSystem => _fileSystem;

  @override
  File wrapFile(io.File delegate) => FaultyFile(_fileSystem, delegate as File);

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      FaultyDirectory(_fileSystem, delegate as Directory);

  @override
  Link wrapLink(io.Link delegate) => delegate as Link;

  @override
  Directory childDirectory(String basename) {
    return fileSystem.directory(fileSystem.path.join(path, basename));
  }

  @override
  File childFile(String basename) {
    return fileSystem.file(fileSystem.path.join(path, basename));
  }

  @override
  Link childLink(String basename) {
    return fileSystem.link(fileSystem.path.join(path, basename));
  }
}
