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

void main() {
  group('UpgradeCommandRunner', () {
    FakeUpgradeCommandRunner fakeCommandRunner;
    UpgradeCommandRunner realCommandRunner;
    FakeProcessManager processManager;
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
      processManager = FakeProcessManager.list(<FakeCommand>[]);
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
        verifyOnly: false,
      );
      expect(result, throwsToolExit());
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
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
        verifyOnly: false,
      );
      expect(result, throwsToolExit());
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
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
        verifyOnly: false,
      );
      expect(await result, FlutterCommandResult.success());
      expect(testLogger.statusText, contains('Flutter is already up to date'));
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('Correctly provides upgrade version on verify only', () async {
      const String revision = 'abc123';
      when(flutterVersion.frameworkRevision).thenReturn(revision);
      fakeCommandRunner.alreadyUpToDate = false;
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        force: false,
        continueFlow: false,
        testFlow: false,
        gitTagVersion: gitTagVersion,
        flutterVersion: flutterVersion,
        verifyOnly: true,
      );
      expect(await result, FlutterCommandResult.success());
      expect(testLogger.statusText, contains('A new version of Flutter is available'));
      expect(testLogger.statusText, contains(fakeCommandRunner.remoteRevision));
      expect(testLogger.statusText, contains(revision));
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('fetchRemoteRevision returns revision if git succeeds', () async {
      const String revision = 'abc123';

      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git', 'fetch', '--tags'
        ]),
        const FakeCommand(command: <String>[
          'git', 'rev-parse', '--verify', '@{u}',
        ],
        stdout: revision),
      ]);

      expect(await realCommandRunner.fetchRemoteRevision(), revision);
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('fetchRemoteRevision throws toolExit if HEAD is detached', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git', 'fetch', '--tags'
        ]),
        FakeCommand(
          command: const <String>['git', 'rev-parse', '--verify', '@{u}'],
          onRun: () {
            throw const ProcessException(
              'git',
              <String>['rev-parse', '--verify', '@{u}'],
              'fatal: HEAD does not point to a branch',
            );
          }
        ),
      ]);

      await expectLater(
            () async => await realCommandRunner.fetchRemoteRevision(),
        throwsToolExit(message: 'You are not currently on a release branch.'),
      );
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('fetchRemoteRevision throws toolExit if no upstream configured', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git', 'fetch', '--tags'
        ]),
        FakeCommand(
          command: const <String>['git', 'rev-parse', '--verify', '@{u}'],
          onRun: () {
            throw const ProcessException(
              'git',
              <String>['rev-parse', '--verify', '@{u}'],
              'fatal: no upstream configured for branch',
            );
          },
        ),
      ]);

      await expectLater(
            () async => await realCommandRunner.fetchRemoteRevision(),
        throwsToolExit(
          message: 'Unable to upgrade Flutter: no origin repository configured.',
        ),
      );
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('git exception during attemptReset throwsToolExit', () async {
      const String revision = 'abc123';
      const String errorMessage = 'fatal: Could not parse object ´$revision´';
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: const <String>['git', 'reset', '--hard', revision],
          onRun: () {
            throw const ProcessException(
              'git',
              <String>['reset', '--hard', revision],
              errorMessage,
            );
          },
        ),
      ]);

      await expectLater(
            () async => await realCommandRunner.attemptReset(revision),
        throwsToolExit(message: errorMessage),
      );
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('flutterUpgradeContinue passes env variables to child process', () async {
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            globals.fs.path.join('bin', 'flutter'),
            'upgrade',
            '--continue',
            '--no-version-check',
          ],
          environment: <String, String>{'FLUTTER_ALREADY_LOCKED': 'true', ...fakePlatform.environment}
        ),
      );
      await realCommandRunner.flutterUpgradeContinue();
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    testUsingContext('precacheArtifacts passes env variables to child process', () async {
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            globals.fs.path.join('bin', 'flutter'),
            '--no-color',
            '--no-version-check',
            'precache',
          ],
          environment: <String, String>{'FLUTTER_ALREADY_LOCKED': 'true', ...fakePlatform.environment}
        ),
      );
      await realCommandRunner.precacheArtifacts();
      expect(processManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
      Platform: () => fakePlatform,
    });

    group('runs upgrade', () {
      setUp(() {
        processManager.addCommand(
          FakeCommand(command: <String>[
            globals.fs.path.join('bin', 'flutter'),
            'upgrade',
            '--continue',
            '--no-version-check',
          ]),
        );
      });

      testUsingContext('does not throw on unknown tag, official branch, force', () async {
        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          force: true,
          continueFlow: false,
          testFlow: false,
          gitTagVersion: const GitTagVersion.unknown(),
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(processManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        ProcessManager: () => processManager,
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
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(processManager.hasRemainingExpectations, isFalse);
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
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(processManager.hasRemainingExpectations, isFalse);
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
                'git', 'describe', '--match', '*.*.*', '--long', '--tags',
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

  });
}

class FakeUpgradeCommandRunner extends UpgradeCommandRunner {
  bool willHaveUncomittedChanges = false;

  bool alreadyUpToDate = false;

  String remoteRevision = '';

  @override
  Future<String> fetchRemoteRevision() async => remoteRevision;

  @override
  Future<bool> hasUncommittedChanges() async => willHaveUncomittedChanges;

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
