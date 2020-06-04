// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
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

const String kPowershellException = r'''
New-Object : Exception calling ".ctor" with "3" argument(s): "End of Central Directory record could not be found."
At
C:\Windows\system32\WindowsPowerShell\v1.0\Modules\Microsoft.PowerShell.Archive\Microsoft.PowerShell.Archive.psm1:934
char:23
+ ... ipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -Ar ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [New-Object], MethodInvocationException
    + FullyQualifiedErrorId : ConstructorInvokedThrowException,Microsoft.PowerShell.Commands.NewObjectCommand
''';

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
    testWithoutContext('returns null when executable does not exist', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenReturn(ProcessResult(0, 1, null, null));
      when(mockProcessManager.canRun('pwsh.exe')).thenReturn(true);
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      when(mockProcessManager.runSync(<String>['where', 'foo']))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      when(mockProcessManager.canRun('pwsh.exe')).thenReturn(true);
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      when(mockProcessManager.runSync(<String>['where', kExecutable]))
          .thenReturn(ProcessResult(0, 0, '$kPath1\n$kPath2', null));
      when(mockProcessManager.canRun('pwsh.exe')).thenReturn(true);
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  group('gzip on Windows:', () {
    testWithoutContext('verifyGzip returns false on a FileSystemException', () {
      final MockFileSystem fileSystem = MockFileSystem();
      final MockFile mockFile = MockFile();
      when(fileSystem.file(any)).thenReturn(mockFile);
      when(mockFile.readAsBytesSync()).thenThrow(
        const FileSystemException('error'),
      );
      when(mockProcessManager.canRun('pwsh.exe')).thenReturn(true);
      final OperatingSystemUtils osUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: mockProcessManager,
      );

      expect(osUtils.verifyGzip(mockFile), isFalse);
    });

    testWithoutContext('verifyGzip returns false on an ArchiveException', () {
      final MockFileSystem fileSystem = MockFileSystem();
      final MockFile mockFile = MockFile();
      when(fileSystem.file(any)).thenReturn(mockFile);
      when(mockFile.readAsBytesSync()).thenReturn(Uint8List.fromList(<int>[
        // Anything other than the magic header: 0x1f, 0x8b.
        0x01,
        0x02,
      ]));
      when(mockProcessManager.canRun('pwsh.exe')).thenReturn(true);
      final OperatingSystemUtils osUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: mockProcessManager,
      );

      expect(osUtils.verifyGzip(mockFile), isFalse);
    });

    testWithoutContext('verifyGzip returns false on an empty file', () {
      final MockFileSystem fileSystem = MockFileSystem();
      final MockFile mockFile = MockFile();
      when(fileSystem.file(any)).thenReturn(mockFile);
      when(mockFile.readAsBytesSync()).thenReturn(Uint8List(0));
      when(mockProcessManager.canRun('pwsh.exe')).thenReturn(true);
      final OperatingSystemUtils osUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: mockProcessManager,
      );

      expect(osUtils.verifyGzip(mockFile), isFalse);
    });
  });

  testWithoutContext('Windows PowerShell Expand-Archive', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'pwsh.exe',
          '-command',
          '"Expand-Archive a -DestinationPath b"',
        ],
      ),
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'windows'),
      processManager: processManager,
    );

    osUtils.unzip(fileSystem.file('a'), fileSystem.directory('b'));

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('Windows PowerShell Expand-Archive with stderr', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'pwsh.exe',
          '-command',
          '"Expand-Archive a -DestinationPath b"',
        ],
        stderr: kPowershellException,
      ),
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'windows'),
      processManager: processManager,
    );

    expect(() => osUtils.unzip(fileSystem.file('a'), fileSystem.directory('b')),
      throwsA(isA<ProcessException>()));

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('Windows PowerShell Compress-Archive', () {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'pwsh.exe',
          '-command',
          '"Compress-Archive b -DestinationPath a"',
        ],
      ),
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'windows'),
      processManager: processManager,
    );

    osUtils.zip(fileSystem.directory('b'), fileSystem.file('a'));

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('Windows PowerShell Compress-Archive with stderr', () {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'pwsh.exe',
          '-command',
          '"Compress-Archive b -DestinationPath a"',
        ],
        stderr: kPowershellException,
      ),
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'windows'),
      processManager: processManager,
    );

    expect(() => osUtils.zip(fileSystem.directory('b'), fileSystem.file('a')),
      throwsA(isA<ProcessException>()));

    expect(processManager.hasRemainingExpectations, false);
  });

   testWithoutContext('Windows PowerShell verifyZip is a no-op', () {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[]);
    final FileSystem fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'windows'),
      processManager: processManager,
    );

    expect(osUtils.verifyZip(fileSystem.file('a')), true);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('stream compression level', () {
    expect(OperatingSystemUtils.gzipLevel1.level, equals(1));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
