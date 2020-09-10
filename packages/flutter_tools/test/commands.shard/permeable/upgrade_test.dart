// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/mocks.dart';

void main() {
  group('UpgradeCommandRunner', () {
    FakeUpgradeCommandRunner fakeCommandRunner;
    UpgradeCommandRunner realCommandRunner;
    MockProcessManager processManager;
    FakePlatform fakePlatform;
    final MockFlutterVersion flutterVersion = MockFlutterVersion();
    const GitTagVersion gitTagVersion = GitTagVersion(
      x: 1,
      y: 2,
      z: 3,
      hotfix: 4,
      commits: 5,
      hash: 'asd',
    );
    when(flutterVersion.channel).thenReturn('dev');

    setUp(() {
      fakeCommandRunner = FakeUpgradeCommandRunner();
      realCommandRunner = UpgradeCommandRunner();
      processManager = MockProcessManager();
      when(processManager.start(
        <String>[
          globals.fs.path.join('bin', 'flutter'),
          'upgrade',
          '--continue',
          '--no-version-check',
        ],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) async {
        return Future<Process>.value(createMockProcess());
      });
      fakeCommandRunner.willHaveUncomittedChanges = false;
      fakePlatform = FakePlatform()..environment = Map<String, String>.unmodifiable(<String, String>{
        'ENV1': 'irrelevant',
        'ENV2': 'irrelevant',
      });
    });

    testUsingContext('throws on unknown tag, official branch,  noforce', () async {
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: false,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: const GitTagVersion.unknown(),
        flutterVersion: flutterVersion,
      );
      expect(result, throwsToolExit());
    }, overrides: <Type, Generator>{
      Platform: () => fakePlatform,
    });

    testUsingContext('does not throw on unknown tag, official branch, force', () async {
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: true,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: const GitTagVersion.unknown(),
        flutterVersion: flutterVersion,
      );
      expect(await result, FlutterCommandResult.success());
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('throws tool exit with uncommitted changes', () async {
      fakeCommandRunner.willHaveUncomittedChanges = true;
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: false,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: gitTagVersion,
        flutterVersion: flutterVersion,
      );
      expect(result, throwsToolExit());
    }, overrides: <Type, Generator>{
      Platform: () => fakePlatform,
    });

    testUsingContext('does not throw tool exit with uncommitted changes and force', () async {
      fakeCommandRunner.willHaveUncomittedChanges = true;

      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: true,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: gitTagVersion,
        flutterVersion: flutterVersion,
      );
      expect(await result, FlutterCommandResult.success());
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext("Doesn't throw on known tag, dev branch, no force", () async {
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: false,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: gitTagVersion,
        flutterVersion: flutterVersion,
      );
      expect(await result, FlutterCommandResult.success());
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext("Doesn't continue on known tag, dev branch, no force, already up-to-date", () async {
      const String revision = 'abc123';
      when(flutterVersion.frameworkRevision).thenReturn(revision);
      fakeCommandRunner.alreadyUpToDate = true;
      fakeCommandRunner.remoteRevision = revision;
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: false,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: gitTagVersion,
        flutterVersion: flutterVersion,
      );
      expect(await result, FlutterCommandResult.success());
      verifyNever(globals.processManager.start(
        <String>[
          globals.fs.path.join('bin', 'flutter'),
          'upgrade',
          '--continue',
          '--no-version-check',
        ],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      ));
      expect(testLogger.statusText, contains('Flutter is already up to date'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('fetchRemoteRevision returns revision if git succeeds', () async {
      const String revision = 'abc123';
      when(processManager.run(
        <String>['git', 'fetch', '--tags'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((Invocation invocation) async {
        return FakeProcessResult()
          ..exitCode = 0;
      });
      when(processManager.run(
        <String>['git', 'rev-parse', '--verify', '@{u}'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((Invocation invocation) async {
        return FakeProcessResult()
          ..exitCode = 0
          ..stdout = revision;
      });
      expect(await realCommandRunner.fetchRemoteRevision(), revision);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('fetchRemoteRevision throws toolExit if HEAD is detached', () async {
      when(processManager.run(
        <String>['git', 'fetch', '--tags'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((Invocation invocation) async {
        return FakeProcessResult()..exitCode = 0;
      });
      when(processManager.run(
        <String>['git', 'rev-parse', '--verify', '@{u}'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenThrow(const ProcessException(
        'git',
        <String>['rev-parse', '--verify', '@{u}'],
        'fatal: HEAD does not point to a branch',
      ));
      expect(
        () async => await realCommandRunner.fetchRemoteRevision(),
        throwsToolExit(message: 'You are not currently on a release branch.'),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('fetchRemoteRevision throws toolExit if no upstream configured', () async {
      when(processManager.run(
        <String>['git', 'fetch', '--tags'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((Invocation invocation) async {
        return FakeProcessResult()..exitCode = 0;
      });
      when(processManager.run(
        <String>['git', 'rev-parse', '--verify', '@{u}'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenThrow(const ProcessException(
        'git',
        <String>['rev-parse', '--verify', '@{u}'],
        'fatal: no upstream configured for branch',
      ));
      expect(
        () async => await realCommandRunner.fetchRemoteRevision(),
        throwsToolExit(
          message: 'Unable to upgrade Flutter: no origin repository configured\.',
        ),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('git exception during attemptReset throwsToolExit', () async {
      const String revision = 'abc123';
      const String errorMessage = 'fatal: Could not parse object ´$revision´';
      when(processManager.run(
        <String>['git', 'reset', '--hard', revision]
      )).thenThrow(const ProcessException(
        'git',
        <String>['reset', '--hard', revision],
        errorMessage,
      ));

      expect(
        () async => await realCommandRunner.attemptReset(revision),
        throwsToolExit(message: errorMessage),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('flutterUpgradeContinue passes env variables to child process', () async {
      await realCommandRunner.flutterUpgradeContinue();

      final VerificationResult result = verify(globals.processManager.start(
        <String>[
          globals.fs.path.join('bin', 'flutter'),
          'upgrade',
          '--continue',
          '--no-version-check',
        ],
        environment: captureAnyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      ));

      expect(result.captured.first,
          <String, String>{ 'FLUTTER_ALREADY_LOCKED': 'true', ...fakePlatform.environment });
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('precacheArtifacts passes env variables to child process', () async {
      final List<String> precacheCommand = <String>[
        globals.fs.path.join('bin', 'flutter'),
        '--no-color',
        '--no-version-check',
        'precache',
      ];

      when(globals.processManager.start(
        precacheCommand,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) async {
        return Future<Process>.value(createMockProcess());
      });

      await realCommandRunner.precacheArtifacts();

      final VerificationResult result = verify(globals.processManager.start(
        precacheCommand,
        environment: captureAnyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      ));

      expect(result.captured.first,
          <String, String>{ 'FLUTTER_ALREADY_LOCKED': 'true', ...fakePlatform.environment });
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    group('full command', () {
      FakeProcessManager fakeProcessManager;
      Directory tempDir;
      File flutterToolState;

      FlutterVersion mockFlutterVersion;

      setUp(() {
        Cache.disableLocking();
        fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>[
              'git', 'tag', '--points-at', 'HEAD',
            ],
            stdout: '',
          ),
          const FakeCommand(
            command: <String>[
              'git', 'describe', '--match', '*.*.*', '--first-parent', '--long', '--tags',
            ],
            stdout: 'v1.12.16-19-gb45b676af',
          ),
        ]);
        tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_upgrade_test.');
        flutterToolState = tempDir.childFile('.flutter_tool_state');
        mockFlutterVersion = MockFlutterVersion(isStable: true);
      });

      tearDown(() {
        Cache.enableLocking();
        tryToDelete(tempDir);
      });

      testUsingContext('upgrade continue prints welcome message', () async {
        final UpgradeCommand upgradeCommand = UpgradeCommand(fakeCommandRunner);
        applyMocksToCommand(upgradeCommand);

        await createTestCommandRunner(upgradeCommand).run(
          <String>[
            'upgrade',
            '--continue',
          ],
        );

        expect(
          json.decode(flutterToolState.readAsStringSync()),
          containsPair('redisplay-welcome-message', true),
        );
      }, overrides: <Type, Generator>{
        FlutterVersion: () => mockFlutterVersion,
        ProcessManager: () => fakeProcessManager,
        PersistentToolState: () => PersistentToolState.test(
          directory: tempDir,
          logger: testLogger,
        ),
      });
    });
  });
}

class FakeUpgradeCommandRunner extends UpgradeCommandRunner {
  bool willHaveUncomittedChanges = false;

  bool alreadyUpToDate = false;

  String remoteRevision = '';

  @override
  Future<String> fetchRemoteRevision() async => remoteRevision;

  @override
  Future<bool> hasUncomittedChanges() async => willHaveUncomittedChanges;

  @override
  Future<void> upgradeChannel(FlutterVersion flutterVersion) async {}

  @override
  Future<void> attemptReset(String newRevision) async {}

  @override
  Future<void> precacheArtifacts() async {}

  @override
  Future<void> updatePackages(FlutterVersion flutterVersion) async {}

  @override
  Future<void> runDoctor() async {}
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
class FakeProcessResult implements ProcessResult {
  @override
  int exitCode;

  @override
  int pid = 0;

  @override
  String stderr = '';

  @override
  String stdout = '';
}
