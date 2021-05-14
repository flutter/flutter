// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

void main() {
  late Config config;
  late MemoryFileSystem memoryFileSystem;
  late FakePlatform fakePlatform;

  setUp(() {
    memoryFileSystem = MemoryFileSystem.test();
    fakePlatform = FakePlatform(
      operatingSystem: 'linux',
      environment: <String, String>{
        'HOME': '/',
      },
    );
    config = Config(
      'example',
      fileSystem: memoryFileSystem,
      logger: BufferLogger.test(),
      platform: fakePlatform,
    );
  });

  testWithoutContext('Config get set value', () async {
    expect(config.getValue('foo'), null);
    config.setValue('foo', 'bar');
    expect(config.getValue('foo'), 'bar');
    expect(config.keys, contains('foo'));
  });

  testWithoutContext('Config get set bool value', () async {
    expect(config.getValue('foo'), null);
    config.setValue('foo', true);
    expect(config.getValue('foo'), true);
    expect(config.keys, contains('foo'));
  });

  testWithoutContext('Config containsKey', () async {
    expect(config.containsKey('foo'), false);
    config.setValue('foo', 'bar');
    expect(config.containsKey('foo'), true);
  });

  testWithoutContext('Config removeValue', () async {
    expect(config.getValue('foo'), null);
    config.setValue('foo', 'bar');
    expect(config.getValue('foo'), 'bar');
    expect(config.keys, contains('foo'));
    config.removeValue('foo');
    expect(config.getValue('foo'), null);
    expect(config.keys, isNot(contains('foo')));
  });

  testWithoutContext('Config parse error', () {
    final BufferLogger bufferLogger = BufferLogger.test();
    final File file = memoryFileSystem.file('.flutter_example')
      ..writeAsStringSync('{"hello":"bar');
    config = Config(
      'example',
      fileSystem: memoryFileSystem,
      logger: bufferLogger,
      platform: fakePlatform,
    );

    expect(file.existsSync(), false);
    expect(bufferLogger.errorText, contains('Failed to decode preferences'));
  });

  testWithoutContext('Config does not error on missing file', () {
    final BufferLogger bufferLogger = BufferLogger.test();
    final File file = memoryFileSystem.file('example');
    config = Config(
      'example',
      fileSystem: memoryFileSystem,
      logger: bufferLogger,
      platform: fakePlatform,
    );

    expect(file.existsSync(), false);
    expect(bufferLogger.errorText, isEmpty);
  });

  testWithoutContext('Config does not error on a normally fatal file system exception', () {
    final BufferLogger bufferLogger = BufferLogger.test();
    final File file = ErrorHandlingFile(
      platform: FakePlatform(operatingSystem: 'linux'),
      fileSystem: MemoryFileSystem.test(),
      delegate: FakeFile('testfile'),
    );

    config = Config.createForTesting(file, bufferLogger);

    expect(bufferLogger.errorText, contains('Could not read preferences in testfile'));
    expect(bufferLogger.errorText, contains(r'sudo chown -R $(whoami) /testfile'));
  });

  testWithoutContext('Config in home dir is used if it exists', () {
    memoryFileSystem.file('.flutter_example').writeAsStringSync('{"hello":"bar"}');
    config = Config(
      'example',
      fileSystem: memoryFileSystem,
      logger: BufferLogger.test(),
      platform: fakePlatform,
    );
    expect(config.getValue('hello'), 'bar');
    expect(memoryFileSystem.file('.config/flutter/example').existsSync(), false);
  });

  testWithoutContext('Config is created in config dir if it does not already exist in home dir', () {
    config = Config(
      'example',
      fileSystem: memoryFileSystem,
      logger: BufferLogger.test(),
      platform: fakePlatform,
    );

    config.setValue('foo', 'bar');
    expect(memoryFileSystem.file('.config/flutter/example').existsSync(), true);
  });
}

class FakeFile extends Fake implements File {
  FakeFile(this.path);

  @override
  final String path;

  @override
  bool existsSync() {
    return true;
  }

  @override
  String readAsStringSync({Encoding encoding = utf8ForTesting}) {
    throw const FileSystemException('', '', OSError('', 13)); // EACCES error on linux
  }
}
