// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/compile.dart';

import '../src/common.dart';
import '../src/context.dart';

const String kPackagesContents = r'''
xml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/xml-3.2.3/lib/
yaml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/yaml-2.1.15/lib/
example:file:///example/lib/
''';

const String kMultiRootPackagesContents = r'''
xml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/xml-3.2.3/lib/
yaml:file:///Users/flutter_user/.pub-cache/hosted/pub.dartlang.org/yaml-2.1.15/lib/
example:org-dartlang-app:/
''';

void main() {
  FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  testUsingContext('Can map main.dart to correct package', () async {
    fileSystem.file('.packages').writeAsStringSync(kPackagesContents);
    final PackageUriMapper packageUriMapper = await PackageUriMapper.create(
      '/example/lib/main.dart', '.packages', null, null);

    expect(packageUriMapper.map('/example/lib/main.dart').toString(),
        'package:example/main.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('single-root maps file from other package to null', () async {
    fileSystem.file('.packages').writeAsStringSync(kPackagesContents);
    final PackageUriMapper packageUriMapper = await PackageUriMapper.create(
      '/example/lib/main.dart', '.packages', null, null);

    expect(packageUriMapper.map('/xml/lib/xml.dart'), null);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('single-root maps non-main file from same package', () async {
    fileSystem.file('.packages').writeAsStringSync(kPackagesContents);
    final PackageUriMapper packageUriMapper = await PackageUriMapper.create(
      '/example/lib/main.dart', '.packages', null, null);

    expect(packageUriMapper.map('/example/lib/src/foo.dart').toString(),
      'package:example/src/foo.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('multi-root maps main file from same package on multiroot scheme', () async {
    fileSystem.file('.packages').writeAsStringSync(kMultiRootPackagesContents);
    final PackageUriMapper packageUriMapper = await PackageUriMapper.create(
        '/example/lib/main.dart',
        '.packages',
        'org-dartlang-app',
        <String>['/example/lib/', '/gen/lib/']);

    expect(packageUriMapper.map('/example/lib/main.dart').toString(),
      'package:example/main.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}
