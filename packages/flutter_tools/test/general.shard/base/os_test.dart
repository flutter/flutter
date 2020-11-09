// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String kExecutable = 'foo';
const String kPath1 = '/bar/bin/$kExecutable';
const String kPath2 = '/another/bin/$kExecutable';

void main() {
  MockProcessManager mockProcessManager;

  setUp(() {
    mockProcessManager = MockProcessManager();
  });

  OperatingSystemUtils createOSUtils(Platform platform) {
    return OperatingSystemUtils(
      fileSystem: MemoryFileSystem(),
      logger: BufferLogger.test(),
      platform: platform,
      processManager: mockProcessManager,
    );
  }

  group('which on POSIX', () {
    testWithoutContext('returns null when executable does not exist', () async {
      when(mockProcessManager.runSync(<String>['which', kExecutable]))
          .thenReturn(ProcessResult(0, 1, null, null));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'linux'));
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      when(mockProcessManager.runSync(<String>['which', 'foo']))
          .thenReturn(ProcessResult(0, 0, kPath1, null));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'linux'));
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      when(mockProcessManager.runSync(<String>['which', '-a', kExecutable]))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'linux'));
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  group('which on Windows', () {
    testWithoutContext('throws tool exit if where throws an argument error', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenThrow(ArgumentError('Cannot find executable for where'));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));

      expect(() => utils.which(kExecutable), throwsA(isA<ToolExit>()));
    });
    testWithoutContext('returns null when executable does not exist', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenReturn(ProcessResult(0, 1, null, null));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      when(mockProcessManager.runSync(<String>['where', 'foo']))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  testWithoutContext('If unzip fails, include stderr in exception text', () {
    const String exceptionMessage = 'Something really bad happened.';
    when(mockProcessManager.runSync(
      <String>['unzip', '-o', '-q', null, '-d', null],
    )).thenReturn(ProcessResult(0, 1, '', exceptionMessage));
    final MockFileSystem fileSystem = MockFileSystem();
    final MockFile mockFile = MockFile();
    final MockDirectory mockDirectory = MockDirectory();
    when(fileSystem.file(any)).thenReturn(mockFile);
    when(mockFile.readAsBytesSync()).thenThrow(
      const FileSystemException(exceptionMessage),
    );
    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: mockProcessManager,
    );

    expect(
      () => osUtils.unzip(mockFile, mockDirectory),
      throwsProcessException(message: exceptionMessage),
    );
  });

  testWithoutContext('stream compression level', () {
    expect(OperatingSystemUtils.gzipLevel1.level, equals(1));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockDirectory extends Mock implements Directory {}
class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
