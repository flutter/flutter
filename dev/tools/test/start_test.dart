// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert' show jsonDecode;

import 'package:args/command_runner.dart';
import 'package:dev_tools/proto/conductor_state.pb.dart' as pb;
import 'package:dev_tools/proto/conductor_state.pbenum.dart' show ReleasePhase;
import 'package:dev_tools/repository.dart';
import 'package:dev_tools/start.dart';
import 'package:dev_tools/state.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import './common.dart';

void main() {
  group('start command', () {
    const String flutterRoot = '/flutter';
    const String checkoutsParentDirectory = '$flutterRoot/dev/tools/';
    const String frameworkMirror = 'https://github.com/user/flutter.git';
    const String engineMirror = 'https://github.com/user/engine.git';
    const String candidateBranch = 'flutter-1.2-candidate.3';
    const String releaseChannel = 'stable';
    const String revision = 'abcd1234';
    Checkouts checkouts;
    MemoryFileSystem fileSystem;
    FakePlatform platform;
    TestStdio stdio;
    FakeProcessManager processManager;

    setUp(() {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
    });

    CommandRunner<void> createRunner({
      Map<String, String> environment,
      String operatingSystem,
      List<FakeCommand> commands,
    }) {
      operatingSystem ??= const LocalPlatform().operatingSystem;
      final String pathSeparator = operatingSystem == 'windows' ? r'\' : '/';
      environment ??= <String, String>{
        'HOME': '/path/to/user/home',
      };
      final Directory homeDir = fileSystem.directory(
        environment['HOME'],
      );
      // Tool assumes this exists
      homeDir.createSync(recursive: true);
      platform = FakePlatform(
        environment: environment,
        operatingSystem: operatingSystem,
        pathSeparator: pathSeparator,
      );
      processManager = FakeProcessManager.list(commands ?? <FakeCommand>[]);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final StartCommand command = StartCommand(
        checkouts: checkouts,
        flutterRoot: fileSystem.directory(flutterRoot),
      );
      return CommandRunner<void>('codesign-test', '')..addCommand(command);
    }

    tearDown(() {
      // Ensure we don't re-use these between tests.
      processManager = null;
      checkouts = null;
      platform = null;
    });

    test('throws exception if run from Windows', () async {
      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'rev-parse', 'HEAD'],
            stdout: revision,
          ),
        ],
        operatingSystem: 'windows',
      );
      await expectLater(
        () async => runner.run(<String>['start']),
        throwsExceptionWith(
          'Error! This tool is only supported on macOS and Linux',
        ),
      );
    });

    test('throws if --$kFrameworkMirrorOption not provided', () async {
      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'rev-parse', 'HEAD'],
            stdout: revision,
          ),
        ],
      );

      await expectLater(
        () async => runner.run(<String>['start']),
        throwsExceptionWith(
          'Expected either the CLI arg --$kFrameworkMirrorOption or the environment variable FRAMEWORK_MIRROR to be provided',
        ),
      );
    });

    test('creates state file if provided correct inputs', () async {
      const String revision2 = 'def789';
      const String revision3 = '123abc';

      final List<FakeCommand> engineCommands = <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            EngineRepository.defaultUpstream,
            fileSystem.path.join(
              checkoutsParentDirectory,
              'flutter_conductor_checkouts',
              'engine',
            ),
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', engineMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', 'upstream/$candidateBranch'],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
      ];
      final List<FakeCommand> frameworkCommands = <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            fileSystem.path.join(
              checkoutsParentDirectory,
              'flutter_conductor_checkouts',
              'framework',
            ),
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', frameworkMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', 'upstream/$candidateBranch'],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
      ];
      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'rev-parse', 'HEAD'],
            stdout: revision,
          ),
          ...engineCommands,
          ...frameworkCommands,
        ],
      );

      final String stateFilePath = fileSystem.path.join(
        platform.environment['HOME'],
        kStateFileName,
      );

      await runner.run(<String>[
        'start',
        '--$kFrameworkMirrorOption',
        frameworkMirror,
        '--$kEngineMirrorOption',
        engineMirror,
        '--$kCandidateOption',
        candidateBranch,
        '--$kReleaseOption',
        releaseChannel,
        '--$kStateOption',
        stateFilePath,
      ]);

      final File stateFile = fileSystem.file(stateFilePath);

      final pb.ConductorState state = pb.ConductorState();
      state.mergeFromProto3Json(
        jsonDecode(stateFile.readAsStringSync()),
      );

      expect(state.isInitialized(), true);
      expect(state.releaseChannel, releaseChannel);
      expect(state.engine.candidateBranch, candidateBranch);
      expect(state.engine.startingGitHead, revision2);
      expect(state.framework.candidateBranch, candidateBranch);
      expect(state.framework.startingGitHead, revision3);
      expect(state.lastPhase, ReleasePhase.INITIALIZE);
      expect(state.conductorVersion, revision);
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
