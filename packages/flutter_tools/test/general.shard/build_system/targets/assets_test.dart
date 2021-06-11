// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart';
import 'package:flutter_tools/src/build_system/targets/assets.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/devfs.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  Environment environment;
  FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      processManager: FakeProcessManager.any(),
      artifacts: Artifacts.test(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
    );
    fileSystem.file(environment.buildDir.childFile('app.dill')).createSync(recursive: true);
    fileSystem.file('packages/flutter_tools/lib/src/build_system/targets/assets.dart')
      .createSync(recursive: true);
    fileSystem.file('assets/foo/bar.png')
      .createSync(recursive: true);
    fileSystem.file('assets/wildcard/#bar.png')
      .createSync(recursive: true);
    fileSystem.file('.packages')
      .createSync();
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
  assets:
    - assets/foo/bar.png
    - assets/wildcard/
''');
  });

  testUsingContext('includes LICENSE file inputs in dependencies', () async {
    fileSystem.file('.packages')
      .writeAsStringSync('foo:file:///bar/lib');
    fileSystem.file('bar/LICENSE')
      ..createSync(recursive: true)
      ..writeAsStringSync('THIS IS A LICENSE');

    await const CopyAssets().build(environment);

    final File depfile = environment.buildDir.childFile('flutter_assets.d');

    expect(depfile, exists);

    final DepfileService depfileService = DepfileService(
      logger: null,
      fileSystem: fileSystem,
    );
    final Depfile dependencies = depfileService.parse(depfile);

    expect(
      dependencies.inputs.firstWhere((File file) => file.path == '/bar/LICENSE', orElse: () => null),
      isNotNull,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Copies files to correct asset directory', () async {
    await const CopyAssets().build(environment);

    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/AssetManifest.json'), exists);
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/FontManifest.json'), exists);
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/NOTICES.Z'), exists);
    // See https://github.com/flutter/flutter/issues/35293
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/foo/bar.png'), exists);
    // See https://github.com/flutter/flutter/issues/46163
    expect(fileSystem.file('${environment.buildDir.path}/flutter_assets/assets/wildcard/%23bar.png'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Throws exception if pubspec contains missing files', () async {
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('''
name: example

flutter:
  assets:
    - assets/foo/bar2.png

''');

    expect(() async => const CopyAssets().build(environment), throwsException);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testWithoutContext('processSkSLBundle returns null if there is no path '
    'to the bundle', () {

    expect(processSkSLBundle(
      null,
      targetPlatform: TargetPlatform.android,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      engineVersion: null,
    ), isNull);
  });

  testWithoutContext('processSkSLBundle throws exception if bundle file is '
    'missing', () {

    expect(() => processSkSLBundle(
      'does_not_exist.sksl',
      targetPlatform: TargetPlatform.android,
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      engineVersion: null,
    ), throwsException);
  });

  testWithoutContext('processSkSLBundle throws exception if the bundle is not '
    'valid JSON', () {

    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    fileSystem.file('bundle.sksl').writeAsStringSync('{');

    expect(() => processSkSLBundle(
      'bundle.sksl',
      targetPlatform: TargetPlatform.android,
      fileSystem: fileSystem,
      logger: logger,
      engineVersion: null,
    ), throwsException);
    expect(logger.errorText, contains('was not a JSON object'));
  });

  testWithoutContext('processSkSLBundle throws exception if the bundle is not '
    'a JSON object', () {

    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    fileSystem.file('bundle.sksl').writeAsStringSync('[]');

    expect(() => processSkSLBundle(
      'bundle.sksl',
      targetPlatform: TargetPlatform.android,
      fileSystem: fileSystem,
      logger: logger,
      engineVersion: null,
    ), throwsException);
    expect(logger.errorText, contains('was not a JSON object'));
  });

  testWithoutContext('processSkSLBundle throws an exception if the engine '
    'revision is different', () {

    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, String>{
        'engineRevision': '1'
      }
    ));

    expect(() => processSkSLBundle(
      'bundle.sksl',
      targetPlatform: TargetPlatform.android,
      fileSystem: fileSystem,
      logger: logger,
      engineVersion: '2',
    ), throwsException);
    expect(logger.errorText, contains('Expected Flutter 1, but found 2'));
  });

  testWithoutContext('processSkSLBundle warns if the bundle target platform is '
    'different from the current target', () async {

    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'fuchsia',
        'data': <String, Object>{}
      }
    ));

    final DevFSContent content = processSkSLBundle(
      'bundle.sksl',
      targetPlatform: TargetPlatform.android,
      fileSystem: fileSystem,
      logger: logger,
      engineVersion: '2',
    );

    expect(await content.contentsAsBytes(), utf8.encode('{"data":{}}'));
    expect(logger.errorText, contains('This may lead to less efficient shader caching'));
  });

  testWithoutContext('processSkSLBundle does not warn and produces bundle', () async {

    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'android',
        'data': <String, Object>{}
      }
    ));

    final DevFSContent content = processSkSLBundle(
      'bundle.sksl',
      targetPlatform: TargetPlatform.android,
      fileSystem: fileSystem,
      logger: logger,
      engineVersion: '2',
    );

    expect(await content.contentsAsBytes(), utf8.encode('{"data":{}}'));
    expect(logger.errorText, isEmpty);
  });
}
