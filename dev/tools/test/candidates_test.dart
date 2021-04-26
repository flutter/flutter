// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dev_tools/candidates.dart';
import 'package:dev_tools/repository.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import './common.dart';

void main() {
  group('candidates command', () {
    const String flutterRoot = '/flutter';
    const String flutterBinPath = '$flutterRoot/bin/flutter';
    const String checkoutsParentDirectory = '$flutterRoot/dev/tools/';
    const String remoteName = 'origin';

    late MemoryFileSystem fileSystem;
    FakePlatform? platform;
    late TestStdio stdio;
    FakeProcessManager? processManager;

    setUp(() {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
    });

    tearDown(() {
      // Ensure these don't get re-used between tests
      processManager = null;
      platform = null;
    });

    CommandRunner<void> createRunner({
      required List<FakeCommand> commands,
      String? operatingSystem,
    }) {
      operatingSystem ??= const LocalPlatform().operatingSystem;
      final String pathSeparator = operatingSystem == 'windows' ? r'\' : '/';

      processManager = FakeProcessManager.list(commands);
      platform = FakePlatform(
        environment: <String, String>{'HOME': '/path/to/user/home'},
        pathSeparator: pathSeparator,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform!,
        processManager: processManager!,
        stdio: stdio,
      );
      final CandidatesCommand command = CandidatesCommand(
        checkouts: checkouts,
        flutterRoot: fileSystem.directory(flutterRoot),
      );
      return CommandRunner<void>('clean-test', '')..addCommand(command);
    }

    test('prints only branches from targeted remote', () async {
      const String currentVersion = '1.2.3';
      const String branch = 'flutter-1.2-candidate.0';

      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'fetch', remoteName],
          ),
          const FakeCommand(
            command: <String>[flutterBinPath, 'help'],
          ),
          const FakeCommand(
            command: <String>[flutterBinPath, '--version', '--machine'],
            stdout: '{"frameworkVersion": "$currentVersion"}',
          ),
          FakeCommand(
            command: const <String>[
              'git',
              'branch',
              '--no-color',
              '--remotes',
              '--list',
              '$remoteName/*',
            ],
            stdout: <String>[
              'other-remote/branch1',
              '$remoteName/$branch',
            ].join('\n'),
          ),
        ],
      );
      await runner.run(<String>['candidates', '--$kRemote', remoteName]);
      expect(stdio.stdout.contains('currentVersion = $currentVersion'), true);
      expect(stdio.stdout.contains(branch), true);
      expect(stdio.stdout.contains('branch1'), false);
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
