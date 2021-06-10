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
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

class MockFile extends Mock implements File {}
class MockFileSystem extends Mock implements FileSystem {}
class MockDirectory extends Mock implements Directory {}

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

void setupReadMocks({
  FileSystem mockFileSystem,
  ErrorHandlingFileSystem fs,
  int errorCode,
}) {
  final MockFile mockFile = MockFile();
  final MockDirectory mockParentDirectory = MockDirectory();
  when(mockFileSystem.file(any)).thenReturn(mockFile);
  when(mockFile.path).thenReturn('parent/file');
  when(mockFile.parent).thenReturn(mockParentDirectory);
  when(mockParentDirectory.path).thenReturn('parent');
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
  final MockDirectory mockParentDirectory = MockDirectory();
  when(mockDirectory.parent).thenReturn(mockParentDirectory);
  when(mockFileSystem.directory(any)).thenReturn(mockDirectory);
  when(mockDirectory.path).thenReturn('parent/directory');
  when(mockDirectory.parent).thenReturn(mockParentDirectory);
  when(mockParentDirectory.path).thenReturn('parent');
  when(mockDirectory.createTemp(any)).thenAnswer((_) async {
    throw FileSystemException('', '', OSError('', errorCode));
  });
  when(mockDirectory.createTempSync(any))
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
  when(mockDirectory.existsSync())
    .thenThrow(FileSystemException('', '', OSError('', errorCode)));
}

void main() {
  testWithoutContext('deleteIfExists does not delete if file does not exist', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('file');

    expect(ErrorHandlingFileSystem.deleteIfExists(file), false);
  });

  testWithoutContext('deleteIfExists deletes if file exists', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('file')..createSync();

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
    final FileExceptionHandler exceptionHandler = FileExceptionHandler();
    final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
      delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
      platform: linuxPlatform,
    );
    final File file = fileSystem.file('file')..createSync();

    exceptionHandler.addError(
      file,
      FileSystemOp.delete,
      FileSystemException('', file.path, const OSError('', 2)),
    );

    expect(() => ErrorHandlingFileSystem.deleteIfExists(file), throwsToolExit());
  });

  testWithoutContext('deleteIfExists does not tool exit if file exists on read-only '
    'volume and it is run under noExitOnFailure', () {
    final FileExceptionHandler exceptionHandler = FileExceptionHandler();
    final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
      delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
      platform: linuxPlatform,
    );
    final File file = fileSystem.file('file')..createSync();

    exceptionHandler.addError(
      file,
      FileSystemOp.delete,
      FileSystemException('', file.path, const OSError('', 2)),
    );

    expect(() {
      ErrorHandlingFileSystem.noExitOnFailure(() {
        ErrorHandlingFileSystem.deleteIfExists(file);
      });
    }, throwsFileSystemException());
  });

  group('throws ToolExit on Windows', () {
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    const int kUserPermissionDenied = 5;
    const int kFatalDeviceHardwareError =  483;
    MockFileSystem mockFileSystem;
    ErrorHandlingFileSystem fs;
    FileExceptionHandler exceptionHandler;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: windowsPlatform,
      );
      // For fs.path.absolute usage.
      when(mockFileSystem.path).thenReturn(MemoryFileSystem.test().path);
      exceptionHandler = FileExceptionHandler();
    });

    testWithoutContext('bypasses error handling when withAllowedFailure is used', () {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: windowsPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', kUserPermissionDenied)),
      );

      expect(() => ErrorHandlingFileSystem.noExitOnFailure(
        () => file.writeAsStringSync('')), throwsException);

      // nesting does not unconditionally re-enable errors.
      expect(() {
        ErrorHandlingFileSystem.noExitOnFailure(() {
          ErrorHandlingFileSystem.noExitOnFailure(() { });
          file.writeAsStringSync('');
        });
      }, throwsException);

      // Check that state does not leak.
      expect(() => file.writeAsStringSync(''), throwsToolExit());
    });

    testWithoutContext('when access is denied', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: windowsPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', kUserPermissionDenied)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.open,
        FileSystemException('', file.path, const OSError('', kUserPermissionDenied)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.create,
        FileSystemException('', file.path, const OSError('', kUserPermissionDenied)),
      );

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
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: windowsPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', kDeviceFull)),
      );

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
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: windowsPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', kUserMappedSectionOpened)),
      );

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
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: windowsPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', kFatalDeviceHardwareError)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.open,
        FileSystemException('', file.path, const OSError('', kFatalDeviceHardwareError)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.create,
        FileSystemException('', file.path, const OSError('', kFatalDeviceHardwareError)),
      );

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
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: windowsPlatform,
      );
      final Directory directory = fileSystem.directory('directory');

      exceptionHandler.addError(
        directory,
        FileSystemOp.create,
        FileSystemException('', directory.path, const OSError('', kUserPermissionDenied)),
      );

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
    FileExceptionHandler exceptionHandler;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: linuxPlatform,
      );
      // For fs.path.absolute usage.
      when(mockFileSystem.path).thenReturn(MemoryFileSystem.test().path);
      exceptionHandler = FileExceptionHandler();
    });

    testWithoutContext('when access is denied', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: linuxPlatform,
      );
      final Directory directory = fileSystem.directory('dir')..createSync();
      final File file = directory.childFile('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.create,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.read,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.delete,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      const String writeMessage =
          'Flutter failed to write to a file at "dir/file".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /dir/file';
      expect(() async => file.writeAsBytes(<int>[0]), throwsToolExit(message: writeMessage));
      expect(() async => file.writeAsString(''), throwsToolExit(message: writeMessage));
      expect(() => file.writeAsBytesSync(<int>[0]), throwsToolExit(message: writeMessage));
      expect(() => file.writeAsStringSync(''), throwsToolExit(message: writeMessage));

      const String createMessage =
          'Flutter failed to create file at "dir/file".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /dir';
      expect(() => file.createSync(), throwsToolExit(message: createMessage));
      // Recursive does not contain the "sudo chown" suggestion.
      expect(() async => file.createSync(recursive: true),
          throwsA(isA<ToolExit>().having((ToolExit e) => e.message, 'message', isNot(contains('sudo chown')))));

      const String readMessage =
          'Flutter failed to read a file at "dir/file".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /dir/file';
      expect(() => file.readAsStringSync(), throwsToolExit(message: readMessage));
    });

    testWithoutContext('when access is denied for directories', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: linuxPlatform,
      );
      final Directory parent = fileSystem.directory('parent')..createSync();
      final Directory directory = parent.childDirectory('childDir');

      exceptionHandler.addError(
        directory,
        FileSystemOp.create,
        FileSystemException('', directory.path, const OSError('', eperm)),
      );
      exceptionHandler.addError(
        directory,
        FileSystemOp.delete,
        FileSystemException('', directory.path, const OSError('', eperm)),
      );

      const String createMessage =
          'Flutter failed to create a directory at "parent/childDir".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /parent';
      expect(() async => directory.create(),
             throwsToolExit(message: createMessage));
      expect(() => directory.createSync(),
             throwsToolExit(message: createMessage));

      // Recursive does not contain the "sudo chown" suggestion.
      expect(() async => directory.createSync(recursive: true),
          throwsA(isA<ToolExit>().having((ToolExit e) => e.message, 'message', isNot(contains('sudo chown')))));

      const String deleteMessage =
          'Flutter failed to delete a directory at "parent/childDir".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /parent';
      expect(() => directory.deleteSync(),
             throwsToolExit(message: deleteMessage));
      expect(() async => directory.delete(),
          throwsToolExit(message: deleteMessage));

      // Recursive does not contain the "sudo chown" suggestion.
      expect(() async => directory.deleteSync(recursive: true),
          throwsA(isA<ToolExit>().having((ToolExit e) => e.message, 'message', isNot(contains('sudo chown')))));
    });

    testWithoutContext('when writing to a full device', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: linuxPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', enospc)),
      );

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
    FileExceptionHandler exceptionHandler;

    setUp(() {
      mockFileSystem = MockFileSystem();
      fs = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: macOSPlatform,
      );
      // For fs.path.absolute usage.
      when(mockFileSystem.path).thenReturn(MemoryFileSystem.test().path);
      exceptionHandler = FileExceptionHandler();
    });

    testWithoutContext('when access is denied', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: macOSPlatform,
      );
      final Directory directory = fileSystem.directory('dir')..createSync();
      final File file = directory.childFile('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.create,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.read,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      exceptionHandler.addError(
        file,
        FileSystemOp.delete,
        FileSystemException('', file.path, const OSError('', eacces)),
      );
      const String writeMessage =
          'Flutter failed to write to a file at "dir/file".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /dir/file';
      expect(() async => file.writeAsBytes(<int>[0]), throwsToolExit(message: writeMessage));
      expect(() async => file.writeAsString(''), throwsToolExit(message: writeMessage));
      expect(() => file.writeAsBytesSync(<int>[0]), throwsToolExit(message: writeMessage));
      expect(() => file.writeAsStringSync(''), throwsToolExit(message: writeMessage));

      const String createMessage =
          'Flutter failed to create file at "dir/file".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /dir';
      expect(() => file.createSync(), throwsToolExit(message: createMessage));

      // Recursive does not contain the "sudo chown" suggestion.
      expect(() async => file.createSync(recursive: true),
          throwsA(isA<ToolExit>().having((ToolExit e) => e.message, 'message', isNot(contains('sudo chown')))));

      const String readMessage =
          'Flutter failed to read a file at "dir/file".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /dir/file';
      expect(() => file.readAsStringSync(), throwsToolExit(message: readMessage));
    });

    testWithoutContext('when access is denied for directories', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: macOSPlatform,
      );
      final Directory parent = fileSystem.directory('parent')..createSync();
      final Directory directory = parent.childDirectory('childDir');

      exceptionHandler.addError(
        directory,
        FileSystemOp.create,
        FileSystemException('', directory.path, const OSError('', eperm)),
      );
      exceptionHandler.addError(
        directory,
        FileSystemOp.delete,
        FileSystemException('', directory.path, const OSError('', eperm)),
      );

      const String createMessage =
          'Flutter failed to create a directory at "parent/childDir".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /parent';
      expect(() async => directory.create(),
          throwsToolExit(message: createMessage));
      expect(() => directory.createSync(), throwsToolExit(message: createMessage));

      // Recursive does not contain the "sudo chown" suggestion.
      expect(() async => directory.createSync(recursive: true),
          throwsA(isA<ToolExit>().having((ToolExit e) => e.message, 'message', isNot(contains('sudo chown')))));

      const String deleteMessage =
          'Flutter failed to delete a directory at "parent/childDir".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /parent';
      expect(() => directory.deleteSync(),
          throwsToolExit(message: deleteMessage));
      expect(() async => directory.delete(),
          throwsToolExit(message: deleteMessage));

      // Recursive does not contain the "sudo chown" suggestion.
      expect(() async => directory.deleteSync(recursive: true),
          throwsA(isA<ToolExit>().having((ToolExit e) => e.message, 'message', isNot(contains('sudo chown')))));
    });

    testWithoutContext('when writing to a full device', () async {
      final ErrorHandlingFileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: macOSPlatform,
      );
      final File file = fileSystem.file('file');

      exceptionHandler.addError(
        file,
        FileSystemOp.write,
        FileSystemException('', file.path, const OSError('', enospc)),
      );

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
    // For fs.path.absolute usage.
    when(mockFileSystem.path).thenReturn(MemoryFileSystem.test().path);

    expect(identical(firstPath, fs.path), false);
  });

  group('toString() gives toString() of delegate', () {
    testWithoutContext('ErrorHandlingFileSystem', () {
      final MemoryFileSystem delegate = MemoryFileSystem.test();
      final FileSystem fs = ErrorHandlingFileSystem(
        delegate: delegate,
        platform: const LocalPlatform(),
      );

      expect(delegate.toString(), isNotNull);
      expect(fs.toString(), delegate.toString());
    });

    testWithoutContext('ErrorHandlingFile', () {
      final MemoryFileSystem delegate = MemoryFileSystem.test();
      final FileSystem fs = ErrorHandlingFileSystem(
        delegate: delegate,
        platform: const LocalPlatform(),
      );
      final File file = delegate.file('file');

      expect(file.toString(), isNotNull);
      expect(fs.file('file').toString(), file.toString());
    });

    testWithoutContext('ErrorHandlingDirectory', () {
      final MemoryFileSystem delegate = MemoryFileSystem.test();
      final FileSystem fs = ErrorHandlingFileSystem(
        delegate: delegate,
        platform: const LocalPlatform(),
      );
      final Directory directory = delegate.directory('directory')..createSync();
      expect(fs.directory('directory').toString(), directory.toString());
      delegate.currentDirectory = directory;

      expect(fs.currentDirectory.toString(), delegate.currentDirectory.toString());
      expect(fs.currentDirectory, isA<ErrorHandlingDirectory>());
    });
  });

  group('ProcessManager on windows throws tool exit', () {
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    const int kUserPermissionDenied = 5;

    testWithoutContext('when PackageProcess throws an exception containg non-executable bits', () {
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

    testWithoutContext('when PackageProcess throws an exception without containing non-executable bits', () {
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

    testWithoutContext('when the device is full', () {
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

    testWithoutContext('when the file is being used by another program', () {
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

    testWithoutContext('when permissions are denied', () {
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

    testWithoutContext('when cannot run executable', () {
      final ThrowingFakeProcessManager throwingFakeProcessManager = ThrowingFakeProcessManager(const ProcessException('', <String>[], '', kUserPermissionDenied));

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: throwingFakeProcessManager,
        platform: windowsPlatform,
      );

      const String expectedMessage = r'Flutter failed to run "C:\path\to\dart". The flutter tool cannot access the file or directory.';
      expect(() async => processManager.canRun(r'C:\path\to\dart'), throwsToolExit(message: expectedMessage));
    });
  });

  group('ProcessManager on linux throws tool exit', () {
    const int enospc = 28;
    const int eacces = 13;

    testWithoutContext('when writing to a full device', () {
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

    testWithoutContext('when permissions are denied', () {
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

    testWithoutContext('when cannot run executable', () {
      final ThrowingFakeProcessManager throwingFakeProcessManager = ThrowingFakeProcessManager(const ProcessException('', <String>[], '', eacces));

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: throwingFakeProcessManager,
        platform: linuxPlatform,
      );

      const String expectedMessage = 'Flutter failed to run "/path/to/dart".\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /path/to/dart && chmod u+rx /path/to/dart';

      expect(() async => processManager.canRun('/path/to/dart'), throwsToolExit(message: expectedMessage));
    });
  });

  group('ProcessManager on macOS throws tool exit', () {
    const int enospc = 28;
    const int eacces = 13;

    testWithoutContext('when writing to a full device', () {
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

    testWithoutContext('when permissions are denied', () {
      final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
        const FakeCommand(command: <String>['foo'], exception: ProcessException('', <String>[], '', eacces)),
      ]);
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: fakeProcessManager,
        platform: macOSPlatform,
      );

      const String expectedMessage = 'The flutter tool cannot access the file';

      expect(() async => processManager.start(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() async => processManager.run(<String>['foo']),
             throwsToolExit(message: expectedMessage));
      expect(() => processManager.runSync(<String>['foo']),
             throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('when cannot run executable', () {
      final ThrowingFakeProcessManager throwingFakeProcessManager = ThrowingFakeProcessManager(const ProcessException('', <String>[], '', eacces));

      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: throwingFakeProcessManager,
        platform: macOSPlatform,
      );

      const String expectedMessage = 'Flutter failed to run "/path/to/dart".\n'
      'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
      'Try running:\n'
      r'  sudo chown -R $(whoami) /path/to/dart && chmod u+rx /path/to/dart';

      expect(() async => processManager.canRun('/path/to/dart'), throwsToolExit(message: expectedMessage));
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
    FileExceptionHandler exceptionHandler;
    ErrorHandlingFileSystem fileSystem;

    setUp(() {
      exceptionHandler = FileExceptionHandler();
      fileSystem = ErrorHandlingFileSystem(
        delegate: MemoryFileSystem.test(opHandle: exceptionHandler.opHandle),
        platform: linuxPlatform,
      );
    });

    testWithoutContext('copySync handles error if openSync on source file fails', () {
      final File source = fileSystem.file('source');

      exceptionHandler.addError(
        source,
        FileSystemOp.open,
        FileSystemException('', source.path, const OSError('', eaccess)),
      );

      const String expectedMessage =
          'Flutter failed to copy source to dest due to source location error.\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /source';
      expect(() => fileSystem.file('source').copySync('dest'), throwsToolExit(message: expectedMessage));
    });

    testWithoutContext('copySync handles error if createSync on destination file fails', () {
      fileSystem.file('source').createSync();
      final File dest = fileSystem.file('dest');

      exceptionHandler.addError(
        dest,
        FileSystemOp.create,
        FileSystemException('', dest.path, const OSError('', eaccess)),
      );

      const String expectedMessage =
          'Flutter failed to copy source to dest due to destination location error.\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.';
      expect(() => fileSystem.file('source').copySync('dest'), throwsToolExit(message: expectedMessage));
    });

    // dart:io is able to clobber read-only files.
    testWithoutContext('copySync will copySync even if the destination is not writable', () {
      fileSystem.file('source').createSync();
      final File dest = fileSystem.file('dest');

      exceptionHandler.addError(
        dest,
        FileSystemOp.open,
        FileSystemException('', dest.path, const OSError('', eaccess)),
      );

      expect(dest, isNot(exists));
      fileSystem.file('source').copySync('dest');
      expect(dest, exists);
    });

    testWithoutContext('copySync will copySync if there are no exceptions', () {
      fileSystem.file('source').createSync();
      final File dest = fileSystem.file('dest');

      expect(dest, isNot(exists));
      fileSystem.file('source').copySync('dest');
      expect(dest, exists);
    });

    testWithoutContext('copySync can directly copy bytes if both files can be opened but copySync fails', () {
      final List<int> expectedBytes = List<int>.generate(64 * 1024 + 3, (int i) => i.isEven ? 0 : 1);
      fileSystem.file('source').writeAsBytesSync(expectedBytes);
      final File dest = fileSystem.file('dest');

      exceptionHandler.addError(
        dest,
        FileSystemOp.copy,
        FileSystemException('', dest.path, const OSError('', eaccess)),
      );

      fileSystem.file('source').copySync('dest');
      expect(dest.readAsBytesSync(), expectedBytes);
    });

    testWithoutContext('copySync deletes the result file if the fallback fails', () {
      final MockFileSystem mockFileSystem = MockFileSystem();
      // For fs.path.absolute usage.
      when(mockFileSystem.path).thenReturn(MemoryFileSystem.test().path);

      final FileSystem fileSystem = ErrorHandlingFileSystem(
        delegate: mockFileSystem,
        platform: linuxPlatform,
      );
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem.test();
      final MockFile source = MockFile();
      when(source.path).thenReturn('source');
      final MockDirectory parent = MockDirectory();
      when(parent.path).thenReturn('destParent');
      final MockFile dest = MockFile();
      when(dest.parent).thenReturn(parent);
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

      const String expectedMessage =
          'Flutter failed to copy source to dest due to unknown error.\n'
          'Please ensure that the SDK and/or project is installed in a location that has read/write permissions for the current user.\n'
          'Try running:\n'
          r'  sudo chown -R $(whoami) /source /destParent';
      expect(() => fileSystem.file('source').copySync('dest'), throwsToolExit(message: expectedMessage));

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

class ThrowingFakeProcessManager extends Fake implements ProcessManager {
  ThrowingFakeProcessManager(Exception exception) : _exception = exception;

  final Exception _exception;

  @override
  bool canRun(dynamic executable, {String workingDirectory}) {
    throw _exception;
  }
}
