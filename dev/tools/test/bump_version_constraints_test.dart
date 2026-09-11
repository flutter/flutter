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
      <String>['^3.10.0-0', '^3.13.0-0'],
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

  test('updates pubspec.yaml files with matching SDK constraints and skips deviators', () {
    final File pubspec1 = fileSystem.file('/flutter/packages/flutter/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: flutter
environment:
  sdk: ^3.10.0-0
dependencies:
  meta: any
''');

    final File pubspec2 = fileSystem.file('/flutter/packages/flutter_tools/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: flutter_tools
environment:
  sdk: ^3.10.0-0
''');

    final File pubspecDeviator = fileSystem.file('/flutter/packages/deviator/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: deviator
environment:
  sdk: ^3.12.0
''');

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
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
    expect(pubspecDeviator.readAsStringSync(), '''
name: deviator
environment:
  sdk: ^3.12.0
''');
    expect(
      stdout.toString(),
      contains('Updated ${fileSystem.path.join('packages', 'flutter', 'pubspec.yaml')}'),
    );
    expect(
      stdout.toString(),
      contains('Updated ${fileSystem.path.join('packages', 'flutter_tools', 'pubspec.yaml')}'),
    );
    expect(
      stdout.toString(),
      contains(
        'Skipping ${fileSystem.path.join('packages', 'deviator', 'pubspec.yaml')}: SDK constraint "^3.12.0" does not match expected "^3.10.0-0".',
      ),
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
      <String>['^3.10.0-0', '^3.13.0-0'],
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
      <String>['^3.10.0-0', '^3.13.0-0'],
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

  test('ignores pubspec.yaml outside flutterRoot, in dot-directories, or in bin/cache', () {
    // Hidden dot-directory
    final File pubspecHidden = fileSystem.file('/flutter/.git/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: hidden
environment:
  sdk: ^3.10.0-0
''');

    // Outside flutterRoot
    final File pubspecOutside = fileSystem.file('/bar/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: outside
environment:
  sdk: ^3.10.0-0
''');

    // Inside a build directory
    final File pubspecBuild = fileSystem.file('/flutter/build/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: build_package
environment:
  sdk: ^3.10.0-0
''');

    // Inside bin/cache
    final File pubspecCache = fileSystem.file('/flutter/bin/cache/pkg/sky_engine/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: sky_engine
environment:
  sdk: ^3.10.0-0
''');

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspecHidden.readAsStringSync(), contains('  sdk: ^3.10.0-0\n'));
    expect(pubspecOutside.readAsStringSync(), contains('  sdk: ^3.10.0-0\n'));
    expect(pubspecBuild.readAsStringSync(), contains('  sdk: ^3.10.0-0\n'));
    expect(pubspecCache.readAsStringSync(), contains('  sdk: ^3.10.0-0\n'));
    expect(stdout.toString(), contains('Done. Updated 0 pubspec.yaml files.'));
  });

  test('prints usage and exits with 0 on --help or -h', () {
    bump.run(
      <String>['--help'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 0);
    expect(
      stdout.toString(),
      contains(
        'Usage: dart dev/tools/bin/bump_version_constraints.dart <old_sdk_constraint> <new_sdk_constraint>',
      ),
    );
    expect(stdout.toString(), contains('Options:'));
    expect(stdout.toString(), contains('-h, --help'));
    expect(stderr.toString(), isEmpty);

    stdout.clear();
    stderr.clear();
    exitCode = null;

    bump.run(
      <String>['-h'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 0);
    expect(
      stdout.toString(),
      contains(
        'Usage: dart dev/tools/bin/bump_version_constraints.dart <old_sdk_constraint> <new_sdk_constraint>',
      ),
    );
    expect(stderr.toString(), isEmpty);
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
      contains(
        'ERROR: Expected exactly two arguments specifying the old SDK constraint and the new SDK constraint.',
      ),
    );
    expect(
      stderr.toString(),
      contains(
        'Usage: dart dev/tools/bin/bump_version_constraints.dart <old_sdk_constraint> <new_sdk_constraint>',
      ),
    );

    stdout.clear();
    stderr.clear();
    exitCode = null;

    bump.run(
      <String>['^3.10.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(
      stderr.toString(),
      contains(
        'ERROR: Expected exactly two arguments specifying the old SDK constraint and the new SDK constraint.',
      ),
    );

    stdout.clear();
    stderr.clear();
    exitCode = null;

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0', 'extra-arg'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(
      stderr.toString(),
      contains(
        'ERROR: Expected exactly two arguments specifying the old SDK constraint and the new SDK constraint.',
      ),
    );
  });

  test('continues and exits with 1 when encountering file read/write errors', () {
    final File pubspecGood = fileSystem.file('/flutter/packages/good/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: good
environment:
  sdk: ^3.10.0-0
''');

    fileSystem.file('/flutter/packages/bad/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: bad
environment:
  sdk: ^3.10.0-0
''');

    final FileSystem faultyFileSystem = FaultyFileSystem(fileSystem);

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
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

  test('errors out on unrecognized flags', () {
    bump.run(
      <String>['--invalid-flag'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(
      stderr.toString(),
      contains('ERROR: FormatException: Could not find an option named "--invalid-flag".'),
    );
    expect(
      stderr.toString(),
      contains(
        'Usage: dart dev/tools/bin/bump_version_constraints.dart <old_sdk_constraint> <new_sdk_constraint>',
      ),
    );
  });

  test('handles malformed or non-map pubspec.yaml', () {
    final File pubspecMalformed = fileSystem.file('/flutter/packages/invalid/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('not a yaml map');

    final File pubspecGood = fileSystem.file('/flutter/packages/good/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: good
environment:
  sdk: ^3.10.0-0
''');

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, 1);
    expect(pubspecMalformed.readAsStringSync(), 'not a yaml map');
    expect(pubspecGood.readAsStringSync(), contains('  sdk: ^3.13.0-0\n'));
    expect(
      stderr.toString(),
      contains(
        'Error: ${fileSystem.path.join('packages', 'invalid', 'pubspec.yaml')} is not a valid YAML map.',
      ),
    );
    expect(stdout.toString(), contains('Done. Updated 1 pubspec.yaml file.'));
  });

  test('handles pubspec.yaml with missing or non-map environment', () {
    final File pubspecNoEnv = fileSystem.file('/flutter/packages/no_env/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: no_env
''');

    final File pubspecScalarEnv = fileSystem.file('/flutter/packages/scalar_env/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: scalar_env
environment: invalid
''');

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspecNoEnv.readAsStringSync(), '''
name: no_env
''');
    expect(pubspecScalarEnv.readAsStringSync(), '''
name: scalar_env
environment: invalid
''');
    expect(stdout.toString(), contains('Done. Updated 0 pubspec.yaml files.'));
    expect(stderr.toString(), isEmpty);
  });

  test('does not ignore cache directory if outside bin/', () {
    final File pubspecCacheOutsideBin = fileSystem.file('/flutter/packages/cache/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: cache_pkg
environment:
  sdk: ^3.10.0-0
''');

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(exitCode, isNull);
    expect(pubspecCacheOutsideBin.readAsStringSync(), contains('  sdk: ^3.13.0-0\n'));
    expect(stdout.toString(), contains('Done. Updated 1 pubspec.yaml file.'));
    expect(stderr.toString(), isEmpty);
  });

  test('handles directory traversal errors gracefully', () {
    fileSystem.file('/flutter/packages/unreadable/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: unreadable
environment:
  sdk: ^3.10.0-0
''');

    final File pubspecGood = fileSystem.file('/flutter/packages/good/pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: good
environment:
  sdk: ^3.10.0-0
''');

    final FileSystem faultyFileSystem = FaultyFileSystem(fileSystem);

    bump.run(
      <String>['^3.10.0-0', '^3.13.0-0'],
      fileSystem: faultyFileSystem,
      flutterRoot: faultyFileSystem.directory('/flutter'),
      stdout: stdout,
      stderr: stderr,
      exit: mockExit,
    );

    expect(pubspecGood.readAsStringSync(), contains('  sdk: ^3.13.0-0\n'));
    expect(
      stderr.toString(),
      contains('Error traversing ${fileSystem.path.join('/flutter', 'packages', 'unreadable')}:'),
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
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) {
    if (path.contains('unreadable')) {
      throw const FileSystemException('Simulated directory list failure');
    }
    return super.listSync(recursive: recursive, followLinks: followLinks);
  }

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
