// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
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
}

void main() {
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
  });

  group('throws ToolExit on Linux', () {
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
  });


  group('throws ToolExit on macOS', () {
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
  });

  group('ProcessManager on windows throws tool exit', () {
    const int kDeviceFull = 112;
    const int kUserMappedSectionOpened = 1224;
    const int kUserPermissionDenied = 5;

    test('when the device is full', () {
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: windowsPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, kDeviceFull);

      const String expectedMessage = 'The target device is full';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: windowsPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, kUserMappedSectionOpened);

      const String expectedMessage = 'The file is being used by another program';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: windowsPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, kUserPermissionDenied);

      const String expectedMessage = 'The flutter tool cannot access the file';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: linuxPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, enospc);

      const String expectedMessage = 'The target device is full';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: linuxPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, eacces);

      const String expectedMessage = 'The flutter tool cannot access the file';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: macOSPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, enospc);

      const String expectedMessage = 'The target device is full';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
      final MockProcessManager mockProcessManager = MockProcessManager();
      final ProcessManager processManager = ErrorHandlingProcessManager(
        delegate: mockProcessManager,
        platform: linuxPlatform,
      );
      setupProcessManagerMocks(mockProcessManager, eacces);

      const String expectedMessage = 'The flutter tool cannot access the file';
      expect(() => processManager.canRun('foo'),
             throwsToolExit(message: expectedMessage));
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
}

void setupProcessManagerMocks(
  MockProcessManager processManager,
  int errorCode,
) {
  when(processManager.canRun(any, workingDirectory: anyNamed('workingDirectory')))
    .thenThrow(ProcessException('', <String>[], '', errorCode));
  when(processManager.killPid(any, any))
    .thenThrow(ProcessException('', <String>[], '', errorCode));
  when(processManager.runSync(
    any,
    environment: anyNamed('environment'),
    includeParentEnvironment: anyNamed('includeParentEnvironment'),
    runInShell: anyNamed('runInShell'),
    workingDirectory: anyNamed('workingDirectory'),
    stdoutEncoding: anyNamed('stdoutEncoding'),
    stderrEncoding: anyNamed('stderrEncoding'),
  )).thenThrow(ProcessException('', <String>[], '', errorCode));
  when(processManager.run(
    any,
    environment: anyNamed('environment'),
    includeParentEnvironment: anyNamed('includeParentEnvironment'),
    runInShell: anyNamed('runInShell'),
    workingDirectory: anyNamed('workingDirectory'),
    stdoutEncoding: anyNamed('stdoutEncoding'),
    stderrEncoding: anyNamed('stderrEncoding'),
  )).thenThrow(ProcessException('', <String>[], '', errorCode));
  when(processManager.start(
    any,
    environment: anyNamed('environment'),
    includeParentEnvironment: anyNamed('includeParentEnvironment'),
    runInShell: anyNamed('runInShell'),
    workingDirectory: anyNamed('workingDirectory'),
  )).thenThrow(ProcessException('', <String>[], '', errorCode));
}

class MockProcessManager extends Mock implements ProcessManager {}
