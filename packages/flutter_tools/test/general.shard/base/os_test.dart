// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String kExecutable = 'foo';
const String kPath1 = '/bar/bin/$kExecutable';
const String kPath2 = '/another/bin/$kExecutable';

void main() {
  FakeProcessManager fakeProcessManager;

  setUp(() {
    fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
  });

  OperatingSystemUtils createOSUtils(Platform platform) {
    return OperatingSystemUtils(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      platform: platform,
      processManager: fakeProcessManager,
    );
  }

  group('which on POSIX', () {
    testWithoutContext('returns null when executable does not exist', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'which',
            kExecutable,
          ],
          exitCode: 1,
        ),
      );
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'linux'));
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'which',
            'foo',
          ],
          stdout: kPath1,
        ),
      );
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'linux'));
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'which',
            '-a',
            kExecutable,
          ],
          stdout: '$kPath1\n$kPath2',
        ),
      );
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'linux'));
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  group('which on Windows', () {
    testWithoutContext('throws tool exit if where throws an argument error', () async {
      fakeProcessManager.addCommand(
        FakeCommand(
          command: const <String>[
            'where',
            kExecutable,
          ],
          exception: ArgumentError('Cannot find executable for where'),
        ),
      );

      final OperatingSystemUtils utils = OperatingSystemUtils(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'windows'),
        processManager: fakeProcessManager,
      );

      expect(() => utils.which(kExecutable), throwsA(isA<ToolExit>()));
    });

    testWithoutContext('returns null when executable does not exist', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'where',
            kExecutable,
          ],
          exitCode: 1,
        ),
      );

      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'where',
            'foo',
          ],
          stdout: '$kPath1\n$kPath2',
        ),
      );
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'where',
            kExecutable,
          ],
          stdout: '$kPath1\n$kPath2',
        ),
      );
      final OperatingSystemUtils utils = createOSUtils(FakePlatform(operatingSystem: 'windows'));
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  group('host platform', () {
    testWithoutContext('unknown defaults to Linux', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'uname',
            '-m',
          ],
          stdout: 'x86_64',
        ),
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'fuchsia'));
      expect(utils.hostPlatform, HostPlatform.linux_x64);
    });

    testWithoutContext('Windows', () async {
      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'windows'));
      expect(utils.hostPlatform, HostPlatform.windows_x64);
    });

    testWithoutContext('Linux x64', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'uname',
            '-m',
          ],
          stdout: 'x86_64',
        ),
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'linux'));
      expect(utils.hostPlatform, HostPlatform.linux_x64);
    });

    testWithoutContext('Linux ARM', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>[
            'uname',
            '-m',
          ],
          stdout: 'aarch64',
        ),
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'linux'));
      expect(utils.hostPlatform, HostPlatform.linux_arm64);
    });

    testWithoutContext('macOS ARM', () async {
      fakeProcessManager.addCommands(
        <FakeCommand>[
          const FakeCommand(
            command: <String>[
              'which',
              'sysctl',
            ],
          ),
          const FakeCommand(
            command: <String>[
              'sysctl',
              'hw.optional.arm64',
            ],
            stdout: 'hw.optional.arm64: 1',
          ),
        ],
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'macos'));
      expect(utils.hostPlatform, HostPlatform.darwin_arm);
    });

    testWithoutContext('macOS 11 x86', () async {
      fakeProcessManager.addCommands(
        <FakeCommand>[
          const FakeCommand(
            command: <String>[
              'which',
              'sysctl',
            ],
          ),
          const FakeCommand(
            command: <String>[
              'sysctl',
              'hw.optional.arm64',
            ],
            stdout: 'hw.optional.arm64: 0',
          ),
        ],
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'macos'));
      expect(utils.hostPlatform, HostPlatform.darwin_x64);
    });

    testWithoutContext('sysctl not found', () async {
      fakeProcessManager.addCommands(
        <FakeCommand>[
          const FakeCommand(
            command: <String>[
              'which',
              'sysctl',
            ],
            exitCode: 1,
          ),
        ],
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'macos'));
      expect(() => utils.hostPlatform, throwsToolExit(message: 'sysctl'));
    });

    testWithoutContext('macOS 10 x86', () async {
      fakeProcessManager.addCommands(
        <FakeCommand>[
          const FakeCommand(
            command: <String>[
              'which',
              'sysctl',
            ],
          ),
          const FakeCommand(
            command: <String>[
              'sysctl',
              'hw.optional.arm64',
            ],
            exitCode: 1,
          ),
        ],
      );

      final OperatingSystemUtils utils =
      createOSUtils(FakePlatform(operatingSystem: 'macos'));
      expect(utils.hostPlatform, HostPlatform.darwin_x64);
    });

    testWithoutContext('macOS ARM name', () async {
      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'sw_vers',
            '-productName',
          ],
          stdout: 'product',
        ),
        const FakeCommand(
          command: <String>[
            'sw_vers',
            '-productVersion',
          ],
          stdout: 'version',
        ),
        const FakeCommand(
          command: <String>[
            'sw_vers',
            '-buildVersion',
          ],
          stdout: 'build',
        ),
        const FakeCommand(
          command: <String>[
            'which',
            'sysctl',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'sysctl',
            'hw.optional.arm64',
          ],
          stdout: 'hw.optional.arm64: 1',
        ),
      ]);

      final OperatingSystemUtils utils =
          createOSUtils(FakePlatform(operatingSystem: 'macos'));
      expect(utils.name, 'product version build darwin-arm');
    });

    testWithoutContext('macOS x86 name', () async {
      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'sw_vers',
            '-productName',
          ],
          stdout: 'product',
        ),
        const FakeCommand(
          command: <String>[
            'sw_vers',
            '-productVersion',
          ],
          stdout: 'version',
        ),
        const FakeCommand(
          command: <String>[
            'sw_vers',
            '-buildVersion',
          ],
          stdout: 'build',
        ),
        const FakeCommand(
          command: <String>[
            'which',
            'sysctl',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'sysctl',
            'hw.optional.arm64',
          ],
          exitCode: 1,
        ),
      ]);

      final OperatingSystemUtils utils =
          createOSUtils(FakePlatform(operatingSystem: 'macos'));
      expect(utils.name, 'product version build darwin-x64');
    });
  });

  testWithoutContext('If unzip fails, include stderr in exception text', () {
    const String exceptionMessage = 'Something really bad happened.';
    final FileExceptionHandler handler = FileExceptionHandler();
    final FileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);

    fakeProcessManager.addCommand(
      const FakeCommand(command: <String>[
        'unzip',
        '-o',
        '-q',
        'bar.zip',
        '-d',
        'foo',
      ], exitCode: 1, stderr: exceptionMessage),
    );

    final Directory foo = fileSystem.directory('foo')
      ..createSync();
    final File bar = fileSystem.file('bar.zip')
      ..createSync();
    handler.addError(bar, FileSystemOp.read, const FileSystemException(exceptionMessage));

    final OperatingSystemUtils osUtils = OperatingSystemUtils(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(operatingSystem: 'linux'),
      processManager: fakeProcessManager,
    );

    expect(
      () => osUtils.unzip(bar, foo),
      throwsProcessException(message: exceptionMessage),
    );
  });

  group('display an install message when unzip throws an ArgumentError', () {
    testWithoutContext('Linux', () {
      final FileSystem fileSystem = MemoryFileSystem.test();
      fakeProcessManager.addCommand(
        FakeCommand(
          command: <String>[
            'unzip', '-o', '-q', 'foo.zip', '-d', fileSystem.currentDirectory.path,
          ],
          exception: ArgumentError(),
        ),
      );

      final OperatingSystemUtils linuxOsUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'linux'),
        processManager: fakeProcessManager,
      );

      expect(
        () => linuxOsUtils.unzip(fileSystem.file('foo.zip'), fileSystem.currentDirectory),
        throwsToolExit(
          message: 'Missing "unzip" tool. Unable to extract foo.zip.\n'
          'Consider running "sudo apt-get install unzip".'),
      );
    });

    testWithoutContext('macOS', () {
      final FileSystem fileSystem = MemoryFileSystem.test();
      fakeProcessManager.addCommand(
        FakeCommand(
          command: <String>[
            'unzip', '-o', '-q', 'foo.zip', '-d', fileSystem.currentDirectory.path,
          ],
          exception: ArgumentError(),
        ),
      );

      final OperatingSystemUtils macOSUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'macos'),
        processManager: fakeProcessManager,
      );

      expect(
            () => macOSUtils.unzip(fileSystem.file('foo.zip'), fileSystem.currentDirectory),
        throwsToolExit
          (message: 'Missing "unzip" tool. Unable to extract foo.zip.\n'
            'Consider running "brew install unzip".'),
      );
    });

    testWithoutContext('unknown OS', () {
      final FileSystem fileSystem = MemoryFileSystem.test();
      fakeProcessManager.addCommand(
        FakeCommand(
          command: <String>[
            'unzip', '-o', '-q', 'foo.zip', '-d', fileSystem.currentDirectory.path,
          ],
          exception: ArgumentError(),
        ),
      );

      final OperatingSystemUtils unknownOsUtils = OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(operatingSystem: 'fuchsia'),
        processManager: fakeProcessManager,
      );

      expect(
            () => unknownOsUtils.unzip(fileSystem.file('foo.zip'), fileSystem.currentDirectory),
        throwsToolExit
          (message: 'Missing "unzip" tool. Unable to extract foo.zip.\n'
            'Please install unzip.'),
      );
    });
  });

  testWithoutContext('stream compression level', () {
    expect(OperatingSystemUtils.gzipLevel1.level, equals(1));
  });
}
