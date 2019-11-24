// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

const String packagesContents = r'''
xml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/xml-3.2.3/lib/
yaml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/yaml-2.1.15/lib/
example:file:///example/lib/
''';

const String multiRootPackagesContents = r'''
xml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/xml-3.2.3/lib/
yaml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/yaml-2.1.15/lib/
example:org-dartlang-app:/
''';

void main() {
  MockFileSystem mockFileSystem;
  MockFile mockFile;

  setUp(() {
    mockFileSystem = MockFileSystem();
    mockFile = MockFile();
    when(mockFileSystem.path).thenReturn(fs.path);
    when(mockFileSystem.file(any)).thenReturn(mockFile);
    when(mockFile.readAsBytesSync()).thenReturn(utf8.encode(packagesContents) as Uint8List);
  });

  testUsingContext('Can map main.dart to correct package', () async {
    final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', null, null);
    expect(packageUriMapper.map('/example/lib/main.dart').toString(),
        'package:example/main.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => mockFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('single-root maps file from other package to null', () async {
    final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', null, null);
    expect(packageUriMapper.map('/xml/lib/xml.dart'), null);
  }, overrides: <Type, Generator>{
    FileSystem: () => mockFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('single-root maps non-main file from same package', () async {
    final PackageUriMapper packageUriMapper = PackageUriMapper('/example/lib/main.dart', '.packages', null, null);
    expect(packageUriMapper.map('/example/lib/src/foo.dart').toString(),
        'package:example/src/foo.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => mockFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('multi-root maps main file from same package on multiroot scheme', () async {
    final MockFileSystem mockFileSystem = MockFileSystem();
    final MockFile mockFile = MockFile();
    when(mockFileSystem.path).thenReturn(fs.path);
    when(mockFileSystem.file(any)).thenReturn(mockFile);
    when(mockFile.readAsBytesSync())
        .thenReturn(utf8.encode(multiRootPackagesContents) as Uint8List);
    final PackageUriMapper packageUriMapper = PackageUriMapper(
        '/example/lib/main.dart',
        '.packages',
        'org-dartlang-app',
        <String>['/example/lib/', '/gen/lib/']);
    expect(packageUriMapper.map('/example/lib/main.dart').toString(),
        'package:example/main.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => mockFileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
