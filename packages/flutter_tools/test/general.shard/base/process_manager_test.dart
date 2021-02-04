// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';

import '../../src/common.dart';

void main() {
  group('getExecutablePath', () {
    FileSystem fileSystem;
    Directory workingDir;
    Directory dir1;
    Directory dir2;
    Directory dir3;

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

        String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path', () {
        String command = 'bla.exe';
        final String expectedPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();

        String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path multiple times', () {
        String command = 'bla.exe';
        final String expectedPath = fileSystem.path.join(dir1.path, command);
        final String wrongPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath).createSync();

        String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in subdir of work dir', () {
        String command = fileSystem.path.join('.', 'foo', 'bla.exe');
        final String expectedPath = fileSystem.path.join(workingDir.path, command);
        fileSystem.file(expectedPath).createSync(recursive: true);

        String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in work dir', () {
        String command = fileSystem.path.join('.', 'bla.exe');
        final String expectedPath = fileSystem.path.join(workingDir.path, command);
        final String wrongPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath).createSync();

        String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);

        command = fileSystem.path.withoutExtension(command);
        executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
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

        final String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('not found', () {
        const String command = 'foo.exe';

        final String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        expect(executablePath, isNull);
      });

      test('when path has spaces', () {
        expect(
            sanitizeExecutablePath(r'Program Files\bla.exe', platform: platform),
            r'"Program Files\bla.exe"');
        expect(
            sanitizeExecutablePath(r'ProgramFiles\bla.exe', platform: platform),
            r'ProgramFiles\bla.exe');
        expect(
            sanitizeExecutablePath(r'"Program Files\bla.exe"', platform: platform),
            r'"Program Files\bla.exe"');
        expect(
            sanitizeExecutablePath(r'"Program Files\bla.exe"', platform: platform),
            r'"Program Files\bla.exe"');
        expect(
            sanitizeExecutablePath(r'C:"Program Files"\bla.exe', platform: platform),
            r'C:"Program Files"\bla.exe');
      });

      test('with absolute path when currentDirectory getter throws', () {
        final FileSystem fileSystemNoCwd = MemoryFileSystemNoCwd(fileSystem);
        final String command = fileSystem.path.join(dir3.path, 'bla.exe');
        final String expectedPath = command;
        fileSystem.file(command).createSync();

        final String executablePath = getExecutablePath(
          command,
          null,
          platform: platform,
          fileSystem: fileSystemNoCwd,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('with relative path when currentDirectory getter throws', () {
        final FileSystem fileSystemNoCwd = MemoryFileSystemNoCwd(fileSystem);
        final String command = fileSystem.path.join('.', 'bla.exe');

        final String executablePath = getExecutablePath(
          command,
          null,
          platform: platform,
          fileSystem: fileSystemNoCwd,
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
            environment: <String, String>{'PATH': '${dir1.path}:${dir2.path}'});
      });

      test('absolute', () {
        final String command = fileSystem.path.join(dir3.path, 'bla');
        final String expectedPath = command;
        final String wrongPath = fileSystem.path.join(dir3.path, 'bla.bat');
        fileSystem.file(command).createSync();
        fileSystem.file(wrongPath).createSync();

        final String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('in path multiple times', () {
        const String command = 'xxx';
        final String expectedPath = fileSystem.path.join(dir1.path, command);
        final String wrongPath = fileSystem.path.join(dir2.path, command);
        fileSystem.file(expectedPath).createSync();
        fileSystem.file(wrongPath).createSync();

        final String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        _expectSamePath(executablePath, expectedPath);
      });

      test('not found', () {
        const String command = 'foo';

        final String executablePath = getExecutablePath(
          command,
          workingDir.path,
          platform: platform,
          fileSystem: fileSystem,
        );
        expect(executablePath, isNull);
      });

      test('when path has spaces', () {
        expect(
            sanitizeExecutablePath('/usr/local/bin/foo bar',
                platform: platform),
            '/usr/local/bin/foo bar');
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
