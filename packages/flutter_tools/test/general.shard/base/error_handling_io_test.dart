// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io; // ignore: dart_io_import
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path; // ignore: package_path_import

import '../../src/common.dart';
import '../../src/context.dart';

class MockFile extends Mock implements File {}
class MockFileSystem extends Mock implements FileSystem {}
class MockPathContext extends Mock implements path.Context {}
class MockDirectory extends Mock implements Directory {}

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'PATH': '',
    'PATHEXT': '',
  }
);

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'PATH': '',
  }
);

final Platform macOSPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'PATH': '',
  }
);

void setupWriteMocks({
  FileSystem mockFileSystem,
  ErrorHandlingFileSystem fs,
  int errorCode,
}) {
  final MockFile mockFile = MockFile();
  when(mockFileSystem.file(any)).thenReturn(mockFile);
  when(mockFile.writeAsBytes(
    any,
    mode: anyNamed('mode'),
    flush: anyNamed('flush'),
  )).thenAnswer((_) async {
    throw FileSystemException('', '', OSError('', errorCode));
  });
  when(mockFile.writeAsString(
    any,
    mode: anyNamed('mode'),
    encoding: anyNamed('encoding'),
    flush: anyNamed('flush'),
  )).thenAnswer((_) async {
    throw FileSystemException('', '', OSError('', errorCode));
  });
  when(mockFile.writeAsBytesSync(
    any,
    mode: anyNamed('mode'),
    flush: anyNamed('flush'),
  )).thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockFile.writeAsStringSync(
    any,
    mode: anyNamed('mode'),
    encoding: anyNamed('encoding'),
    flush: anyNamed('flush'),
  )).thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockFile.openSync(
    mode: anyNamed('mode'),
  )).thenThrow(FileSystemException('', '', OSError('', errorCode)));
}

void setupReadMocks({
  FileSystem mockFileSystem,
  ErrorHandlingFileSystem fs,
  int errorCode,
}) {
  final MockFile mockFile = MockFile();
  when(mockFileSystem.file(any)).thenReturn(mockFile);
  when(mockFile.readAsStringSync(
    encoding: anyNamed('encoding'),
  )).thenThrow(FileSystemException('', '', OSError('', errorCode)));
}

void setupDirectoryMocks({
  FileSystem mockFileSystem,
  ErrorHandlingFileSystem fs,
  int errorCode,
}) {
  final MockDirectory mockDirectory = MockDirectory();
  when(mockFileSystem.directory(any)).thenReturn(mockDirectory);
  when(mockDirectory.createTemp(any)).thenAnswer((_) async {
    throw FileSystemException('', '', OSError('', errorCode));
  });
  when(mockDirectory.createTempSync(any))
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.createSync(recursive: anyNamed('recursive')))
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.create())
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.createSync())
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.delete())
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.deleteSync())
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.existsSync())
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
}

void main() {
  testWithoutContext('deleteIfExists does not delete if file does not exist', () {
    final File file = MockFile();
    when(file.existsSync()).thenReturn(false);

    expect(ErrorHandlingFileSystem.deleteIfExists(file), false);
  });

  testWithoutContext('deleteIfExists deletes if file exists', () {
    final File file = MockFile();
    when(file.existsSync()).thenReturn(true);

     expect(ErrorHandlingFileSystem.deleteIfExists(file), true);
  });

  testWithoutContext('deleteIfExists handles separate program deleting file', () {
    final File file = MockFile();
    bool exists = true;
    // Return true for the first call, false for any subsequent calls.
    when(file.existsSync()).thenAnswer((Invocation _) {
      final bool result = exists;
      exists = false;
      return result;
    });
    when(file.deleteSync(recursive: false))
      .thenThrow(const FileSystemException('', '', OSError('', 2)));

    expect(ErrorHandlingFileSystem.deleteIfExists(file), true);
  });

  testWithoutContext('deleteIfExists throws tool exit if file exists on read-only volume', () {
    final File file = MockFile();
    when(file.existsSync()).thenReturn(true);
    when(file.deleteSync(recursive: false))
      .thenThrow(const FileSystemException('', '', OSError('', 2)));

    expect(() => ErrorHandlingFileSystem.deleteIfExists(file), throwsA(isA<ToolExit>()));
  });

  testWithoutContext('deleteIfExists does not tool exit if file exists on read-only '
    'volume and it is run under noExitOnFailure', () {
    final File file = MockFile();
    when(file.existsSync()).thenReturn(true);
    when(file.deleteSync(recursive: false))
      .thenThrow(const FileSystemException('', '', OSError('', 2)));

    expect(() {
      ErrorHandlingFileSystem.noExitOnFailure(() {
        ErrorHandlingFileSystem.deleteIfExists(file);
      });
    }, throwsA(isA<FileSystemException>()));
  });

  group('throws ToolExit on Windows', () {
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    const int kUserPermissionDenied = 5;
    MockFileSystem mockFileSystem;
    ErrorHandlingFileSystem fs;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: windowsPlatform,
      );
      when(mockFileSystem.path).thenReturn(MockPathContext());
    });

    testWithoutContext('bypasses error handling when withAllowedFailure is used', () {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserPermissionDenied,
      );

      final File file = fs.file('file');

      expect(() => ErrorHandlingFileSystem.noExitOnFailure(
        () => file.writeAsStringSync('')), throwsA(isA<Exception>()));

      // nesting does not unconditionally re-enable errors.
      expect(() {
        ErrorHandlingFileSystem.noExitOnFailure(() {
          ErrorHandlingFileSystem.noExitOnFailure(() { });
          file.writeAsStringSync('');
        });
      }, throwsA(isA<Exception>()));

      // Check that state does not leak.
      expect(() => file.writeAsStringSync(''), throwsA(isA<ToolExit>()));
    });

    testWithoutContext('when access is denied', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserPermissionDenied,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The flutter tool cannot access the file';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.openSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when writing to a full device', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kDeviceFull,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The target device is full';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when the file is being used by another program', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserMappedSectionOpened,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The file is being used by another program';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when creating a temporary dir on a full device', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kDeviceFull,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'The target device is full';
      expect(() async => await directory.createTemp('prefix'),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.createTempSync('prefix'),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when creating a directory with permission issues', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserPermissionDenied,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'Flutter failed to create a directory at';
      expect(() => directory.createSync(recursive: true),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when checking for directory existence with permission issues', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserPermissionDenied,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'Flutter failed to check for directory existence at';
      expect(() => directory.existsSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('When reading from a file without permission', () {
      setupReadMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserPermissionDenied,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'Flutter failed to read a file at';
      expect(() => file.readAsStringSync(),
             throwsToolExit(message: expectedMessage));
    });
  });

  group('throws ToolExit on Linux', () {
    const int eperm = 1;
    const int enospc = 28;
    const int eacces = 13;
    MockFileSystem mockFileSystem;
    ErrorHandlingFileSystem fs;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: linuxPlatform,
      );
      when(mockFileSystem.path).thenReturn(MockPathContext());
    });

    testWithoutContext('when access is denied', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eacces,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The flutter tool cannot access the file or directory';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.openSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when access is denied for directories', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eperm,
      );

      final Directory directory = fs.directory('file');

      const String expectedMessage = 'The flutter tool cannot access the file or directory';
      expect(() async => await directory.create(),
             throwsToolExit(message: expectedMessage));
      expect(() async => await directory.delete(),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.createSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.deleteSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when writing to a full device', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: enospc,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The target device is full';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when creating a temporary dir on a full device', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: enospc,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'The target device is full';
      expect(() async => await directory.createTemp('prefix'),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.createTempSync('prefix'),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when checking for directory existence with permission issues', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eacces,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'Flutter failed to check for directory existence at';
      expect(() => directory.existsSync(),
             throwsToolExit(message: expectedMessage));
    });
  });

  group('throws ToolExit on macOS', () {
    const int eperm = 1;
    const int enospc = 28;
    const int eacces = 13;
    MockFileSystem mockFileSystem;
    ErrorHandlingFileSystem fs;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: macOSPlatform,
      );
      when(mockFileSystem.path).thenReturn(MockPathContext());
    });

    testWithoutContext('when access is denied', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eacces,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The flutter tool cannot access the file';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.openSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when access is denied for directories', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eperm,
      );

      final Directory directory = fs.directory('file');

      const String expectedMessage = 'The flutter tool cannot access the file or directory';
      expect(() async => await directory.create(),
             throwsToolExit(message: expectedMessage));
      expect(() async => await directory.delete(),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.createSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.deleteSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when writing to a full device', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: enospc,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'The target device is full';
      expect(() async => await file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => await file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when creating a temporary dir on a full device', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: enospc,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'The target device is full';
      expect(() async => await directory.createTemp('prefix'),
             throwsToolExit(message: expectedMessage));
      expect(() => directory.createTempSync('prefix'),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when checking for directory existence with permission issues', () async {
      setupDirectoryMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eacces,
      );

      final Directory directory = fs.directory('directory');

      const String expectedMessage = 'Flutter failed to check for directory existence at';
      expect(() => directory.existsSync(),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('When reading from a file without permission', () {
      setupReadMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eacces,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'Flutter failed to read a file at';
      expect(() => file.readAsStringSync(),
             throwsToolExit(message: expectedMessage));
    });
  });

  testWithoutContext('Caches path context correctly', () {
    final MockFileSystem mockFileSystem = MockFileSystem();
    final FileSystem fs = ErrorHandlingFileSystem(
      delegate: mockFileSystem,
      platform: const LocalPlatform(),
    );

    expect(identical(fs.path, fs.path), true);
  });

  testWithoutContext('Clears cache when CWD changes', () {
    final MockFileSystem mockFileSystem = MockFileSystem();
    final FileSystem fs = ErrorHandlingFileSystem(
      delegate: mockFileSystem,
      platform: const LocalPlatform(),
    );

    final Object firstPath = fs.path;

    fs.currentDirectory = null;
    when(mockFileSystem.path).thenReturn(MockPathContext());

    expect(identical(firstPath, fs.path), false);
  });

  group('toString() gives toString() of delegate', () {
    testWithoutContext('ErrorHandlingFileSystem', () {
      final MockFileSystem mockFileSystem = MockFileSystem();
      final FileSystem fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: const LocalPlatform(),
      );

      expect(mockFileSystem.toString(), isNotNull);
      expect(fs.toString(), equals(mockFileSystem.toString()));
    });

    testWithoutContext('ErrorHandlingFile', () {
      final MockFileSystem mockFileSystem = MockFileSystem();
      final FileSystem fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: const LocalPlatform(),
      );
      final MockFile mockFile = MockFile();
      when(mockFileSystem.file(any)).thenReturn(mockFile);

      expect(mockFile.toString(), isNotNull);
      expect(fs.file('file').toString(), equals(mockFile.toString()));
    });

    testWithoutContext('ErrorHandlingDirectory', () {
      final MockFileSystem mockFileSystem = MockFileSystem();
      final FileSystem fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: const LocalPlatform(),
      );
      final MockDirectory mockDirectory = MockDirectory();
      when(mockFileSystem.directory(any)).thenReturn(mockDirectory);

      expect(mockDirectory.toString(), isNotNull);
      expect(fs.directory('directory').toString(), equals(mockDirectory.toString()));

      when(mockFileSystem.currentDirectory).thenReturn(mockDirectory);

      expect(fs.currentDirectory.toString(), equals(mockDirectory.toString()));
      expect(fs.currentDirectory, isA<ErrorHandlingDirectory>());
    });
  });

  group('ProcessManager on windows throws tool exit', () {
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    const int kUserPermissionDenied = 5;

    test('when the device is full', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        windowsPlatform,
        kDeviceFull,
      );

      const String expectedMessage = 'The target device is full';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when the file is being used by another program', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        windowsPlatform,
        kUserMappedSectionOpened,
      );

      const String expectedMessage = 'The file is being used by another program';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when permissions are denied', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        windowsPlatform,
        kUserPermissionDenied,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });
  });

  group('ProcessManager on linux throws tool exit', () {
    const int enospc = 28;
    const int eacces = 13;

    test('when writing to a full device', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        linuxPlatform,
        enospc,
      );

      const String expectedMessage = 'The target device is full';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when permissions are denied', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        linuxPlatform,
        eacces,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });
  });

  group('ProcessManager on macOS throws tool exit', () {
    const int enospc = 28;
    const int eacces = 13;

    test('when writing to a full device', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        macOSPlatform,
        enospc,
      );

      const String expectedMessage = 'The target device is full';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when permissions are denied', () {
      final ProcessManager processManager = setUpCrashingProcessManager(
        macOSPlatform,
        eacces,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';

      expect(() => processManager.killPid(1),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => await processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });
  });

  testWithoutContext('Process manager uses which on Linux to resolve executables', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        if (executable == 'which') {
          return ProcessResult(0, 0, 'fizz/foo\n', '');
        }
        if (executable == 'fizz/foo') {
          return ProcessResult(0, 0, '', '');
        }
        throw ProcessException(executable, arguments, '', 2);
     },
    );
    fileSystem.file('fizz/foo').createSync(recursive: true);

    final ProcessResult result = processManager.runSync(<String>['foo']);

    expect(result.exitCode, 0);
  });

  testWithoutContext('Process manager uses which on macOS to resolve executables', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      macOSPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        if (executable == 'which') {
          return ProcessResult(0, 0, 'fizz/foo\n', '');
        }
        if (executable == 'fizz/foo') {
          return ProcessResult(0, 0, '', '');
        }
        throw ProcessException(executable, arguments, '', 2);
     },
    );
    fileSystem.file('fizz/foo').createSync(recursive: true);

    final ProcessResult result = processManager.runSync(<String>['foo']);

    expect(result.exitCode, 0);
  });

  testWithoutContext('Process manager uses where on Windows to resolve executables', () {
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final ProcessManager processManager = setUpProcessManager(
      windowsPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        if (executable == 'where') {
          return ProcessResult(0, 0, 'C:\\fizz\\foo.exe\n', '');
        }
        if (executable == 'C:\\fizz\\foo.exe') {
          return ProcessResult(0, 0, '', '');
        }
        throw ProcessException(executable, arguments, '', 2);
     },
    );

    fileSystem.file('C:\\fizz\\foo.exe').createSync(recursive: true);

    final ProcessResult result = processManager.runSync(<String>['foo']);

    expect(result.exitCode, 0);
  });

  testWithoutContext('Process manager will exit if where returns exit code 2 on Windows', () {
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final ProcessManager processManager = setUpProcessManager(
      windowsPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        throw ProcessException(executable, arguments, '', 2);
     },
    );

    expect(() => processManager.runSync(<String>['any']), throwsToolExit());
  });

  testWithoutContext('Process manager will rethrow process exception if exit code on Linux', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
      throw ProcessException(executable, arguments, '', 2);
     },
    );

    expect(() => processManager.runSync(<String>['any']), throwsA(isA<ProcessException>()));
  });

  testWithoutContext('Process manager will return first executable that exists', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        if (executable == 'which') {
          return ProcessResult(0, 0, 'fizz/foo\nbar/foo\n', '');
        }
        if (executable == 'bar/foo') {
          return ProcessResult(0, 0, '', '');
        }
        throw ProcessException(executable, arguments, '', 2);
     },
    );
    fileSystem.file('bar/foo').createSync(recursive: true);

    final ProcessResult result = processManager.runSync(<String>['foo']);

    expect(result.exitCode, 0);
  });

  testWithoutContext('Process manager will cache executable resolution', () {
    int whichCalled = 0;
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        if (executable == 'which') {
          whichCalled += 1;
          return ProcessResult(0, 0, 'fizz/foo\n', '');
        }
        if (executable == 'fizz/foo') {
          return ProcessResult(0, 0, '', '');
        }
        throw ProcessException(executable, arguments, '', 2);
     },
    );
    fileSystem.file('fizz/foo').createSync(recursive: true);

    processManager.runSync(<String>['foo']);
    processManager.runSync(<String>['foo']);

    expect(whichCalled, 1);
  });

  testWithoutContext('Process manager will not cache executable resolution if the process fails', () {
    int whichCalled = 0;
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
      (String executable,
       List<String> arguments, {
       Map<String, String> environment,
       bool includeParentEnvironment,
       bool runInShell,
       Encoding stderrEncoding,
       Encoding stdoutEncoding,
       String workingDirectory,
      }) {
        if (executable == 'which') {
          whichCalled += 1;
          return ProcessResult(0, 0, '', '');
        }
        if (executable == 'foo') {
          return ProcessResult(0, 0, '', '');
        }
        throw ProcessException(executable, arguments, '', 2);
     },
    );

    processManager.runSync(<String>['foo']);
    processManager.runSync(<String>['foo']);

    expect(whichCalled, 2);
  });

  testWithoutContext('Process manager can run will return false if the executable does not exist', () {
    int whichCalled = 0;
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
       (String executable,
        List<String> arguments, {
        Map<String, String> environment,
        bool includeParentEnvironment,
        bool runInShell,
        Encoding stderrEncoding,
        Encoding stdoutEncoding,
        String workingDirectory,
      }) {
        if (executable == 'which') {
          whichCalled += 1;
          return ProcessResult(0, 0, 'bar/foo\n', '');
        }
        throw ProcessException(executable, arguments, '', 2);
      },
    );

    expect(processManager.canRun('foo'), false);
  });

  testWithoutContext('Process manager can run will return true if the executable does exist', () {
    int whichCalled = 0;
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('bar/foo').createSync(recursive: true);
    final ProcessManager processManager = setUpProcessManager(
      linuxPlatform,
      fileSystem,
       (String executable,
        List<String> arguments, {
        Map<String, String> environment,
        bool includeParentEnvironment,
        bool runInShell,
        Encoding stderrEncoding,
        Encoding stdoutEncoding,
        String workingDirectory,
      }) {
        if (executable == 'which') {
          whichCalled += 1;
          return ProcessResult(0, 0, 'bar/foo\n', '');
        }
        throw ProcessException(executable, arguments, '', 2);
      },
    );

    expect(processManager.canRun('foo'), true);
  });
}

ProcessManager setUpProcessManager(
  Platform platform,
  FileSystem fileSystem,
  ProcessRunSync processRunSync,
) {
  return ErrorHandlingProcessManager(
    fileSystem: fileSystem,
    logger: BufferLogger.test(),
    platform: platform,
    runSync: processRunSync,
  );
}

ProcessManager setUpCrashingProcessManager(
  Platform platform,
  int osError,
) {
  return ErrorHandlingProcessManager(
    fileSystem: MemoryFileSystem.test(
      style: platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    ),
    logger: BufferLogger.test(),
    platform: platform,
    killPid: (int pid, [io.ProcessSignal signal]) {
      throw ProcessException('executable', <String>[], '', osError);
    },
    run: (
      String executable,
      List<String> arguments, {
      Map<String, String> environment,
      bool includeParentEnvironment,
      bool runInShell,
      Encoding stderrEncoding,
      Encoding stdoutEncoding,
      String workingDirectory,
    }) {
      throw ProcessException(executable, arguments, '', osError);
    },
    runSync: (
      String executable,
      List<String> arguments, {
      Map<String, String> environment,
      bool includeParentEnvironment,
      bool runInShell,
      Encoding stderrEncoding,
      Encoding stdoutEncoding,
      String workingDirectory,
    }) {
      throw ProcessException(executable, arguments, '', osError);
    },
    start: (
      String executable,
      List<String> arguments, {
      Map<String, String> environment,
      bool includeParentEnvironment,
      bool runInShell,
      String workingDirectory,
      ProcessStartMode mode,
    }) {
      throw ProcessException(executable, arguments, '', osError);
    },
  );
}
