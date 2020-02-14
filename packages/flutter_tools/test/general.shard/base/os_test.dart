// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';

const String kExecutable = 'foo';
const String kPath1 = '/bar/bin/$kExecutable';
const String kPath2 = '/another/bin/$kExecutable';

class MockLogger extends Mock implements Logger {}

void main() {
  FakeProcessManager fakeProcessManager;

  OperatingSystemUtils createOSUtils(Platform platform) {
    return OperatingSystemUtils(
      fileSystem: MemoryFileSystem(),
      logger: MockLogger(),
      platform: platform,
      processManager: fakeProcessManager,
    );
  }

  group('which on POSIX', () {
    testWithoutContext('returns null when executable does not exist', () async {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['which', kExecutable], exitCode: 1),
      ]);
      final OperatingSystemUtils utils = createOSUtils(
        FakePlatform(operatingSystem: 'linux'),
      );
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['which', kExecutable],
          stdout: kPath1,
        ),
      ]);
      final OperatingSystemUtils utils = createOSUtils(
        FakePlatform(operatingSystem: 'linux'),
      );
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['which', '-a', kExecutable],
          stdout: '$kPath1\n$kPath2\n',
        ),
      ]);
      final OperatingSystemUtils utils = createOSUtils(
        FakePlatform(operatingSystem: 'linux'),
      );
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  group('which on Windows', () {
    testWithoutContext('returns null when executable does not exist', () async {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['where', kExecutable],
          exitCode: 1,
        ),
      ]);
      final OperatingSystemUtils utils = createOSUtils(
        FakePlatform(operatingSystem: 'windows'),
      );
      expect(utils.which(kExecutable), isNull);
    });

    testWithoutContext('returns exactly one result', () async {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['where', kExecutable],
          stdout: '$kPath1\n$kPath2\n',
        ),
      ]);
      final OperatingSystemUtils utils = createOSUtils(
        FakePlatform(operatingSystem: 'windows'),
      );
      expect(utils.which(kExecutable).path, kPath1);
    });

    testWithoutContext('returns all results for whichAll', () async {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['where', kExecutable],
          stdout: '$kPath1\n$kPath2\n',
        ),
      ]);
      final OperatingSystemUtils utils = createOSUtils(
        FakePlatform(operatingSystem: 'windows'),
      );
      final List<File> result = utils.whichAll(kExecutable);
      expect(result, hasLength(2));
      expect(result[0].path, kPath1);
      expect(result[1].path, kPath2);
    });
  });

  group('name', () {
    testWithoutContext('on Linux', () {
      final FakePlatform platform = FakePlatform(
        operatingSystem: 'linux',
        operatingSystemVersion: 'Linux 5.2.17-amd64 '
                                '#1 SMP Debian 5.2.17 (2019-10-21 > 2018)',
      );
      final OperatingSystemUtils utils = createOSUtils(platform);
      expect(utils.name, 'Linux 5.2.17-amd64');
    });

    testWithoutContext('on Mac', () {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['sw_vers', '-productName'],
          stdout: 'Mac OS X\n',
        ),
        const FakeCommand(
          command: <String>['sw_vers', '-productVersion'],
          stdout: '10.14.6\n',
        ),
        const FakeCommand(
          command: <String>['sw_vers', '-buildVersion'],
          stdout: '16G2128\n',
        ),
      ]);
      final FakePlatform platform = FakePlatform(
        operatingSystem: 'macos',
      );
      final OperatingSystemUtils utils = createOSUtils(platform);
      expect(utils.name, 'Mac OS X 10.14.6 16G2128');
    });

    testWithoutContext('on Windows', () {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['ver'],
          stdout: 'Microsoft Windows [Version 10.0.17763.740]',
        ),
      ]);
      final FakePlatform platform = FakePlatform(
        operatingSystem: 'windows',
      );
      final OperatingSystemUtils utils = createOSUtils(platform);
      expect(utils.name, 'Microsoft Windows [Version 10.0.17763.740]');
    });
  });

  group('makeExecutable', () {
    Directory tempDir;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync(
        'flutter_tools_os_utils_test.',
      );
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('makeExecutable', () async {
      final File file = globals.fs.file(globals.fs.path.join(
        tempDir.path,
        'foo.script',
      ));
      file.writeAsStringSync('hello world');
      globals.os.makeExecutable(file);

      final String mode = file.statSync().modeString();
      // rwxr--r--
      expect(mode.substring(0, 3), endsWith('x'));
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => OperatingSystemUtils(
        fileSystem: globals.fs,
        logger: globals.logger,
        platform: globals.platform,
        processManager: globals.processManager,
      ),
    }, skip: const LocalPlatform().isWindows);
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
