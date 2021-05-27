// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:conductor/clean.dart';
import 'package:conductor/repository.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import './common.dart';

void main() {
  group('clean command', () {
    const String flutterRoot = '/flutter';
    const String checkoutsParentDirectory = '$flutterRoot/dev/tools/';

    MemoryFileSystem fileSystem;
    FakePlatform platform;
    TestStdio stdio;
    FakeProcessManager processManager;

    setUp(() {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
    });

    tearDown(() {
      // Ensure these don't get re-used between tests
      stdio = null;
      fileSystem = null;
      processManager = null;
      platform = null;
    });

    CommandRunner<void> createRunner({
      List<FakeCommand> commands,
      String operatingSystem,
    }) {
      operatingSystem ??= const LocalPlatform().operatingSystem;
      final String pathSeparator = operatingSystem == 'windows' ? r'\' : '/';

      processManager = FakeProcessManager.list(commands ?? <FakeCommand>[]);
      platform = FakePlatform(
        environment: <String, String>{'HOME': '/path/to/user/home'},
        pathSeparator: pathSeparator,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CleanCommand command = CleanCommand(
        checkouts: checkouts,
      );
      return CommandRunner<void>('clean-test', '')..addCommand(command);
    }

    test('throws if no state file found', () async {
      final CommandRunner<void> runner = createRunner();
      const String stateFile = '/state-file.json';

      await expectLater(
        () async => runner.run(<String>[
          'clean',
          '--$kStateOption',
          stateFile,
          '--$kYesFlag',
        ]),
        throwsExceptionWith(
          'No persistent state file found at $stateFile',
        ),
      );
    });

    test('deletes state file', () async {
      final CommandRunner<void> runner = createRunner();
      final File stateFile = fileSystem.file('/state-file.json');
      stateFile.writeAsStringSync('{}');

      await runner.run(<String>[
        'clean',
        '--$kStateOption',
        stateFile.path,
        '--$kYesFlag',
      ]);

      expect(stateFile.existsSync(), false);
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
