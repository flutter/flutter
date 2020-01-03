// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });
  test('Can parse depfile from file', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync('''
a.txt: b.txt
''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs.single.path, 'b.txt');
    expect(depfile.outputs.single.path, 'a.txt');
  }));

  test('Can parse depfile with multiple inputs', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync('''
a.txt: b.txt c.txt d.txt
''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs.map((File file) => file.path), <String>[
      'b.txt',
      'c.txt',
      'd.txt',
    ]);
    expect(depfile.outputs.single.path, 'a.txt');
  }));

  test('Can parse depfile with multiple outputs', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync('''
a.txt c.txt d.txt: b.txt
''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs.single.path, 'b.txt');
    expect(depfile.outputs.map((File file) => file.path), <String>[
      'a.txt',
      'c.txt',
      'd.txt',
    ]);
  }));

  test('Can parse depfile with windows file paths', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync(r'''
C:\\a.txt: C:\\b.txt
''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs.single.path, r'C:\b.txt');
    expect(depfile.outputs.single.path, r'C:\a.txt');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
  }));

  test('Resillient to weird whitespace', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync(r'''
a.txt
  : b.txt    c.txt


''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs, hasLength(2));
    expect(depfile.outputs.single.path, 'a.txt');
  }));

  test('Resillient to duplicate files', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync(r'''
a.txt: b.txt b.txt
''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs.single.path, 'b.txt');
    expect(depfile.outputs.single.path, 'a.txt');
  }));

  test('Resillient to malformed file, missing :', () => testbed.run(() {
    final File depfileSource = fs.file('example.d')..writeAsStringSync(r'''
a.text b.txt
''');
    final Depfile depfile = Depfile.parse(depfileSource);

    expect(depfile.inputs, isEmpty);
    expect(depfile.outputs, isEmpty);
  }));

  test('Can parse dart2js output format', () => testbed.run(() {
    final File dart2jsDependencyFile = fs.file('main.dart.js.deps')..writeAsStringSync(r'''
file:///Users/foo/collection.dart
file:///Users/foo/algorithms.dart
file:///Users/foo/canonicalized_map.dart
''');

    final Depfile depfile = Depfile.parseDart2js(dart2jsDependencyFile, fs.file('foo.dart.js'));

    expect(depfile.inputs.map((File file) => file.path), <String>[
      fs.path.absolute(fs.path.join('Users', 'foo', 'collection.dart')),
      fs.path.absolute(fs.path.join('Users', 'foo', 'algorithms.dart')),
      fs.path.absolute(fs.path.join('Users', 'foo', 'canonicalized_map.dart')),
    ]);
    expect(depfile.outputs.single.path, 'foo.dart.js');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.posix)
  }));

  test('Can parse handle invalid uri', () => testbed.run(() {
    final File dart2jsDependencyFile = fs.file('main.dart.js.deps')..writeAsStringSync('''
file:///Users/foo/collection.dart
abcdevf
file:///Users/foo/canonicalized_map.dart
''');

    final Depfile depfile = Depfile.parseDart2js(dart2jsDependencyFile, fs.file('foo.dart.js'));

    expect(depfile.inputs.map((File file) => file.path), <String>[
      fs.path.absolute(fs.path.join('Users', 'foo', 'collection.dart')),
      fs.path.absolute(fs.path.join('Users', 'foo', 'canonicalized_map.dart')),
    ]);
    expect(depfile.outputs.single.path, 'foo.dart.js');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.posix)
  }));
}
