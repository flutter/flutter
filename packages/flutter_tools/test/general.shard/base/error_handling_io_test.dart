// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io' as io; // flutter_ignore: dart_io_import;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path; // flutter_ignore: package_path_import
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockFile extends Mock implements File {}
class MockFileSystem extends Mock implements FileSystem {}
class MockPathContext extends Mock implements path.Context {}
class MockDirectory extends Mock implements Directory {}
class MockRandomAccessFile extends Mock implements RandomAccessFile {}

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{}
);

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{}
);

final Platform macOSPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{}
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
  when(mockFile.createSync(recursive: anyNamed('recursive')))
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
}

void setupReadMocks({
  FileSystem mockFileSystem,
  ErrorHandlingFileSystem fs,
  int errorCode,
}) {
  final MockFile mockFile = MockFile();
  when(mockFileSystem.file(any)).thenReturn(mockFile);
  when(mockFileSystem.currentDirectory).thenThrow(FileSystemException('', '', OSError('', errorCode)));
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
    const int kFatalDeviceHardwareError =  483;
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.openSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => file.createSync(),
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when the device driver has a fatal error', () async {
      setupWriteMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kFatalDeviceHardwareError,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'There is a problem with the device driver '
        'that this file or directory is stored on';
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.openSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => file.createSync(),
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
      expect(() async => directory.createTemp('prefix'),
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

    testWithoutContext('When reading from a file or directory without permission', () {
      setupReadMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kUserPermissionDenied,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'Flutter failed to read a file at';
      expect(() => file.readAsStringSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => fs.currentDirectory,
             throwsToolExit(message: 'The flutter tool cannot access the file or directory'));
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsBytesSync(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() => file.writeAsStringSync(''),
             throwsToolExit(message: expectedMessage));
      expect(() => file.openSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => file.createSync(),
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
      expect(() async => directory.create(),
             throwsToolExit(message: expectedMessage));
      expect(() async => directory.delete(),
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
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
      expect(() async => directory.createTemp('prefix'),
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

    testWithoutContext('When the current working directory disappears', () async {
      setupReadMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: kSystemCannotFindFile,
      );

      expect(() => fs.currentDirectory, throwsToolExit(message: 'Unable to read current working directory'));

      // Error is not caught by other operations.
      expect(() => fs.file('foo').readAsStringSync(), throwsFileSystemException(kSystemCannotFindFile));
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
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
      expect(() async => directory.create(),
             throwsToolExit(message: expectedMessage));
      expect(() async => directory.delete(),
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
      expect(() async => file.writeAsBytes(<int>[0]),
             throwsToolExit(message: expectedMessage));
      expect(() async => file.writeAsString(''),
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
      expect(() async => directory.createTemp('prefix'),
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

    testWithoutContext('When reading from a file or directory without permission', () {
      setupReadMocks(
        mockFileSystem: mockFileSystem,
        fs: fs,
        errorCode: eacces,
      );

      final File file = fs.file('file');

      const String expectedMessage = 'Flutter failed to read a file at';
      expect(() => file.readAsStringSync(),
             throwsToolExit(message: expectedMessage));
      expect(() => fs.currentDirectory,
             throwsToolExit(message: 'The flutter tool cannot access the file or directory'));
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

    test('when PackageProcess throws an exception containg non-executable bits', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessPackageExecutableNotFoundException('', candidates: <String>['not-empty'])),
        const FakeCommand(command: <String>['foo'], exception: ProcessPackageExecutableNotFoundException('', candidates: <String>['not-empty'])),
      ]);

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: windowsPlatform,
      );

      const String expectedMessage = 'The Flutter tool could not locate an executable with suitable permissions';

      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when PackageProcess throws an exception without containing non-executable bits', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessPackageExecutableNotFoundException('', candidates: <String>[])),
        const FakeCommand(command: <String>['foo'], exception: ProcessPackageExecutableNotFoundException('', candidates: <String>[])),
      ]);

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: windowsPlatform,
      );

      // If there were no located executables treat this as a programming error and rethrow the original
      // exception.
      expect(() async => processManager.start(<String>['foo']), throwsProcessException());
      expect(() async => processManager.runSync(<String>['foo']), throwsProcessException());
    });

    test('when the device is full', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kDeviceFull)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kDeviceFull)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kDeviceFull)),
      ]);

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: windowsPlatform,
      );

      const String expectedMessage = 'The target device is full';

      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when the file is being used by another program', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kUserMappedSectionOpened)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kUserMappedSectionOpened)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kUserMappedSectionOpened)),
      ]);

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: windowsPlatform,
      );

      const String expectedMessage = 'The file is being used by another program';
      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when permissions are denied', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kUserPermissionDenied)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kUserPermissionDenied)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', kUserPermissionDenied)),
      ]);

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: windowsPlatform,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';
      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });
  });

  group('ProcessManager on linux throws tool exit', () {
    const int enospc = 28;
    const int eacces = 13;

    test('when writing to a full device', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', enospc)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', enospc)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', enospc)),
      ]);

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: linuxPlatform,
      );

      const String expectedMessage = 'The target device is full';
      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when permissions are denied', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
      ]);
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: linuxPlatform,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';

      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });
  });

  group('ProcessManager on macOS throws tool exit', () {
    const int enospc = 28;
    const int eacces = 13;

    test('when writing to a full device', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', enospc)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', enospc)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', enospc)),
      ]);
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: macOSPlatform,
      );

      const String expectedMessage = 'The target device is full';

      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    test('when permissions are denied', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
      ]);
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: linuxPlatform,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';

      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });
  });

  testWithoutContext('ErrorHandlingProcessManager delegates killPid correctly', () async {
    final FakeSignalProcessManager fakeProcessManager = FakeSignalProcessManager();
    final ProcessManager processManager = ErrorHandlingProcessManager(
      delegate: fakeProcessManager,
      platform: linuxPlatform,
    );

    expect(processManager.killPid(1, io.ProcessSignal.sigterm), true);
    expect(processManager.killPid(3, io.ProcessSignal.sigkill), true);
    expect(fakeProcessManager.killedProcesses, <int, io.ProcessSignal>{
      1: io.ProcessSignal.sigterm,
      3: io.ProcessSignal.sigkill,
    });
  });

  group('CopySync' , () {
    const int eaccess = 13;
    MockFileSystem mockFileSystem;
    ErrorHandlingFileSystem fileSystem;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fileSystem = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: linuxPlatform,
      );
      when(mockFileSystem.path).thenReturn(MockPathContext());
    });

    testWithoutContext('copySync handles error if openSync on source file fails', () {
      final MockFile source = MockFile();
      when(source.openSync(mode: anyNamed('mode')))
        .thenThrow(const FileSystemException('', '', OSError('', eaccess)));
      when(mockFileSystem.file('source')).thenReturn(source);

      expect(() => fileSystem.file('source').copySync('dest'), throwsToolExit());
    });

    testWithoutContext('copySync handles error if createSync on destination file fails', () {
      final MockFile source = MockFile();
      final MockFile dest = MockFile();
      when(source.openSync(mode: anyNamed('mode')))
        .thenReturn(MockRandomAccessFile());
      when(dest.createSync(recursive: anyNamed('recursive')))
        .thenThrow(const FileSystemException('', '', OSError('', eaccess)));
      when(mockFileSystem.file('source')).thenReturn(source);
      when(mockFileSystem.file('dest')).thenReturn(dest);

      expect(() => fileSystem.file('source').copySync('dest'), throwsToolExit());
    });

    // dart:io is able to clobber read-only files.
    testWithoutContext('copySync will copySync even if the destination is not writable', () {
      final MockFile source = MockFile();
      final MockFile dest = MockFile();

      when(source.copySync(any)).thenReturn(dest);
      when(mockFileSystem.file('source')).thenReturn(source);
      when(source.openSync(mode: anyNamed('mode')))
        .thenReturn(MockRandomAccessFile());
      when(mockFileSystem.file('dest')).thenReturn(dest);
      when(dest.openSync(mode: FileMode.writeOnly))
        .thenThrow(const FileSystemException('', '', OSError('', eaccess)));

      fileSystem.file('source').copySync('dest');

      verify(source.copySync('dest')).called(1);
    });

    testWithoutContext('copySync will copySync if there are no exceptions', () {
      final MockFile source = MockFile();
      final MockFile dest = MockFile();

      when(source.copySync(any)).thenReturn(dest);
      when(mockFileSystem.file('source')).thenReturn(source);
      when(source.openSync(mode: anyNamed('mode')))
        .thenReturn(MockRandomAccessFile());
      when(mockFileSystem.file('dest')).thenReturn(dest);
      when(dest.openSync(mode: anyNamed('mode')))
        .thenReturn(MockRandomAccessFile());

      fileSystem.file('source').copySync('dest');

      verify(source.copySync('dest')).called(1);
    });

    testWithoutContext('copySync can directly copy bytes if both files can be opened but copySync fails', () {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem.test();
      final MockFile source = MockFile();
      final MockFile dest = MockFile();
      final List<int> expectedBytes = List<int>.generate(64 * 1024 + 3, (int i) => i.isEven ? 0 : 1);
      final File memorySource = memoryFileSystem.file('source')
        ..writeAsBytesSync(expectedBytes);
      final File memoryDest = memoryFileSystem.file('dest')
        ..createSync();

      when(source.copySync(any))
        .thenThrow(const FileSystemException('', '', OSError('', eaccess)));
      when(source.openSync(mode: anyNamed('mode')))
        .thenAnswer((Invocation invocation) => memorySource.openSync(mode: invocation.namedArguments[#mode] as FileMode));
      when(dest.openSync(mode: anyNamed('mode')))
        .thenAnswer((Invocation invocation) => memoryDest.openSync(mode: invocation.namedArguments[#mode] as FileMode));
      when(mockFileSystem.file('source')).thenReturn(source);
      when(mockFileSystem.file('dest')).thenReturn(dest);

      fileSystem.file('source').copySync('dest');

      expect(memoryDest.readAsBytesSync(), expectedBytes);
    });

    testWithoutContext('copySync deletes the result file if the fallback fails', () {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem.test();
      final MockFile source = MockFile();
      final MockFile dest = MockFile();
      final File memorySource = memoryFileSystem.file('source')
        ..createSync();
      final File memoryDest = memoryFileSystem.file('dest')
        ..createSync();
      int calledCount = 0;

      when(dest.existsSync()).thenReturn(true);
      when(source.copySync(any))
        .thenThrow(const FileSystemException('', '', OSError('', eaccess)));
      when(source.openSync(mode: anyNamed('mode')))
        .thenAnswer((Invocation invocation) {
          if (calledCount == 1) {
            throw const FileSystemException('', '', OSError('', eaccess));
          }
          calledCount +=  1;
          return memorySource.openSync(mode: invocation.namedArguments[#mode] as FileMode);
        });
      when(dest.openSync(mode: anyNamed('mode')))
        .thenAnswer((Invocation invocation) => memoryDest.openSync(mode: invocation.namedArguments[#mode] as FileMode));
      when(mockFileSystem.file('source')).thenReturn(source);
      when(mockFileSystem.file('dest')).thenReturn(dest);

      expect(() => fileSystem.file('source').copySync('dest'), throwsToolExit());

      verify(dest.deleteSync(recursive: true)).called(1);
    });
  });
}

class FakeSignalProcessManager extends Fake implements ProcessManager {
  final Map<int, io.ProcessSignal> killedProcesses = <int, io.ProcessSignal>{};

  @override
  bool killPid(int pid, [io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    killedProcesses[pid] = signal;
    return true;
  }
}
