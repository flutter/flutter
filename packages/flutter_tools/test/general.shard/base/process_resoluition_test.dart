// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';

void main() {
  group('resolveExecutablePath', () {
    FileSystem fileSystem;
    Directory workingDir, dir1, dir2, dir3;

    void initialize(FileSystemStyle style) {
      setUp(() {
        fileSystem = MemoryFileSystem(style: style);
        workingDir = fileSystem.systemTempDirectory.createTempSync('work_dir_');
        dir1 = fileSystem.systemTempDirectory.createTempSync('dir1_');
        dir2 = fileSystem.systemTempDirectory.createTempSync('dir2_');
        dir3 = fileSystem.systemTempDirectory.createTempSync('dir3_');
      });
    }

    tearDown(() {
      workingDir.deleteSync(recursive: true);
      dir1.deleteSync(recursive: true);
      dir2.deleteSync(recursive: true);
      dir3.deleteSync(recursive: true);
    });

    group('on windows', () {
      Platform platform;

      initialize(FileSystemStyle.windows);

      setUp(() {
        platform = FakePlatform(
          operatingSystem: 'windows',
          environment: <String, String>{
            'PATH': '${dir1.path};${dir2.path}',
            'PATHEXT': '.exe;.bat'
          },
        );
      });

      test('absolute', () {
        String command = fileSystem.path.join(dir3.path, 'bla.exe');
        final String expectedPath = command;
        fileSystem.file(command).createSync();

        String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path as link', () {
        String command = 'bla.exe';
        final File target = fileSystem.file(fileSystem.path.join('something', 'else', 'bla.exe'))
          ..createSync(recursive: true);
        fileSystem.link(fileSystem.path.join(dir2.path, command)).createSync(target.absolute.path, recursive: true);
        final String expectedPath = target.absolute.path;

        String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );

        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path', () {
        String command = 'bla.exe';
        final String expectedPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();

        String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path multiple times', () {
        String command = 'bla.exe';
        final String expectedPath = fileSystem.path.join(dir1.path, command);
        final String wrongPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath).createSync();

        String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in subdir of work dir', () {
        String command = fileSystem.path.join('.', 'foo', 'bla.exe');
        final String expectedPath = fileSystem.path.join(workingDir.path, command);
        fileSystem.file(expectedPath).createSync(recursive: true);

        String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in work dir', () {
        String command = fileSystem.path.join('.', 'bla.exe');
        final String expectedPath = fileSystem.path.join(workingDir.path, command);
        final String wrongPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath).createSync();

        String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('with multiple extensions', () {
        const String command = 'foo';
        final String expectedPath = fileSystem.path.join(dir1.path, '$command.exe');
        final String wrongPath1 = fileSystem.path.join(dir1.path, '$command.bat');
        final String wrongPath2 = fileSystem.path.join(dir2.path, '$command.exe');
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath1).createSync();
        fileSystem.file(wrongPath2).createSync();

        final String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('not found', () {
        const String command = 'foo.exe';

        final String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        expect(executablePath, isNull);
      });

      test('with absolute path when currentDirectory getter throws', () {
        final FileSystem fileSystemNoCwd = MemoryFileSystemNoCwd(fileSystem);
        final String command = fileSystem.path.join(dir3.path, 'bla.exe');
        final String expectedPath = command;
        fileSystem.file(command).createSync();

        final String executablePath = resolveExecutablePath(
          command,
          null,
          platform: platform,
          fileSystem: fileSystemNoCwd,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('with relative path when currentDirectory getter throws', () {
        final FileSystem fileSystemNoCwd = MemoryFileSystemNoCwd(fileSystem);
        final String command = fileSystem.path.join('.', 'bla.exe');

        final String executablePath = resolveExecutablePath(
          command,
          null,
          platform: platform,
          fileSystem: fileSystemNoCwd,
          logger: BufferLogger.test(),
          strict: true,
        );
        expect(executablePath, isNull);
      });
    });

    group('on Linux', () {
      Platform platform;

      initialize(FileSystemStyle.posix);

      setUp(() {
        platform = FakePlatform(
          operatingSystem: 'linux',
          environment: <String, String>{'PATH': '${dir1.path}:${dir2.path}'},
        );
      });

      test('absolute', () {
        final String command = fileSystem.path.join(dir3.path, 'bla');
        final String expectedPath = command;
        final String wrongPath = fileSystem.path.join(dir3.path, 'bla.bat');
        fileSystem.file(command).createSync();
        fileSystem.file(wrongPath).createSync();

        final String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path multiple times', () {
        const String command = 'xxx';
        final String expectedPath = fileSystem.path.join(dir1.path, command);
        final String wrongPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath).createSync();

        final String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('not found with strict', () {
        const String command = 'foo';

        final String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: true,
        );
        expect(executablePath, isNull);
      });

      test('not found without strict', () {
        const String command = 'foo';

        final String executablePath = resolveExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
          strict: false,
        );
        expect(executablePath, 'foo');
      });
    });
  });
}

void _expectSamePath(String actual, String expected) {
  expect(actual, isNotNull);
  expect(actual.toLowerCase(), expected.toLowerCase());
}

class MemoryFileSystemNoCwd extends ForwardingFileSystem {
  MemoryFileSystemNoCwd(FileSystem delegate) : super(delegate);

  @override
  Directory get currentDirectory {
    throw const FileSystemException('Access denied');
  }
}
