// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('UpgradeCommandRunner', () {
    final jan12026 = DateTime.utc(2026);

    late FakeUpgradeCommandRunner fakeCommandRunner;
    late UpgradeCommandRunner realCommandRunner;
    late FakeProcessManager processManager;
    late FakePlatform fakePlatform;
    const gitTagVersion = GitTagVersion(
      x: 1,
      y: 2,
      z: 3,
      hotfix: 4,
      commits: 5,
      hash: 'asd',
      gitTag: '1.2.3+hotfix.5.pre.5',
    );

    setUp(() {
      fakeCommandRunner = FakeUpgradeCommandRunner()..clock = SystemClock.fixed(jan12026);
      realCommandRunner = UpgradeCommandRunner()
        ..workingDirectory = getFlutterRoot()
        ..clock = SystemClock.fixed(jan12026);
      processManager = FakeProcessManager.empty();
      fakeCommandRunner.willHaveUncommittedChanges = false;
      fakePlatform = FakePlatform()
        ..environment = Map<String, String>.unmodifiable(<String, String>{
          'ENV1': 'irrelevant',
          'ENV2': 'irrelevant',
        });
    });

    testUsingContext(
      'throws on unknown tag, official branch,  noforce',
      () async {
        final flutterVersion = FakeFlutterVersion(branch: 'beta');
        const upstreamRevision = '';
        final latestVersion = FakeFlutterVersion(frameworkRevision: upstreamRevision);
        fakeCommandRunner.remoteVersion = latestVersion;

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: false,
          testFlow: false,
          gitTagVersion: const GitTagVersion.unknown(),
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(result, throwsToolExit());
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{Platform: () => fakePlatform},
    );

    testUsingContext(
      'throws tool exit with uncommitted changes',
      () async {
        final flutterVersion = FakeFlutterVersion(branch: 'beta');
        const upstreamRevision = '';
        final latestVersion = FakeFlutterVersion(frameworkRevision: upstreamRevision);
        fakeCommandRunner.remoteVersion = latestVersion;
        fakeCommandRunner.willHaveUncommittedChanges = true;

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: false,
          testFlow: false,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(result, throwsToolExit());
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{Platform: () => fakePlatform},
    );

    testUsingContext(
      "Doesn't continue on known tag, beta branch, no force, already up-to-date",
      () async {
        const revision = 'abc123';
        final latestVersion = FakeFlutterVersion(frameworkRevision: revision);
        final flutterVersion = FakeFlutterVersion(branch: 'beta', frameworkRevision: revision);
        fakeCommandRunner.alreadyUpToDate = true;
        fakeCommandRunner.remoteVersion = latestVersion;

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: false,
          testFlow: false,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(testLogger.statusText, contains('Flutter is already up to date'));
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'starts the upgrade operation and passes now as --continue-started-at <iso-date>',
      () async {
        const revision = 'abc123';
        const upstreamRevision = 'def456';
        const version = '1.2.3';
        const upstreamVersion = '4.5.6';

        final flutterVersion = FakeFlutterVersion(
          branch: 'beta',
          frameworkRevision: revision,
          frameworkRevisionShort: revision,
          frameworkVersion: version,
        );

        final latestVersion = FakeFlutterVersion(
          frameworkRevision: upstreamRevision,
          frameworkRevisionShort: upstreamRevision,
          frameworkVersion: upstreamVersion,
        );

        final DateTime now = DateTime.now().subtract(const Duration(minutes: 25));
        fakeCommandRunner.remoteVersion = latestVersion;
        fakeCommandRunner.clock = SystemClock.fixed(now);

        processManager.addCommands(<FakeCommand>[
          FakeCommand(
            command: <String>[
              globals.fs.path.join('bin', 'flutter'),
              'upgrade',
              '--continue',
              '--continue-started-at',
              now.toIso8601String(),
              '--no-version-check',
            ],
          ),
        ]);

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: false,
          testFlow: false,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(testLogger.statusText, isNot(contains('Took ')));
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'finishes the upgrade operation and prints minutes the operation took',
      () async {
        const revision = 'abc123';
        const upstreamRevision = 'def456';
        const version = '1.2.3';
        const upstreamVersion = '4.5.6';

        final flutterVersion = FakeFlutterVersion(
          branch: 'beta',
          frameworkRevision: revision,
          frameworkRevisionShort: revision,
          frameworkVersion: version,
        );

        final latestVersion = FakeFlutterVersion(
          frameworkRevision: upstreamRevision,
          frameworkRevisionShort: upstreamRevision,
          frameworkVersion: upstreamVersion,
        );

        fakeCommandRunner.remoteVersion = latestVersion;

        final now = DateTime.now();
        final DateTime before = now.subtract(const Duration(minutes: 25));
        fakeCommandRunner.clock = SystemClock.fixed(now);

        processManager.addCommands(<FakeCommand>[
          FakeCommand(
            command: <String>[
              globals.fs.path.join('bin', 'flutter'),
              '--no-color',
              '--no-version-check',
              'precache',
            ],
          ),
        ]);

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          UpgradePhase.secondHalf(upgradeStartedAt: before),
          force: false,
          testFlow: false,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(testLogger.statusText, contains('Took 25.0m'));
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'correctly provides upgrade version on verify only',
      () async {
        const revision = 'abc123';
        const upstreamRevision = 'def456';
        const version = '1.2.3';
        const upstreamVersion = '4.5.6';

        final flutterVersion = FakeFlutterVersion(
          branch: 'beta',
          frameworkRevision: revision,
          frameworkRevisionShort: revision,
          frameworkVersion: version,
        );

        final latestVersion = FakeFlutterVersion(
          frameworkRevision: upstreamRevision,
          frameworkRevisionShort: upstreamRevision,
          frameworkVersion: upstreamVersion,
        );

        fakeCommandRunner.alreadyUpToDate = false;
        fakeCommandRunner.remoteVersion = latestVersion;

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: false,
          testFlow: false,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: true,
        );
        expect(await result, FlutterCommandResult.success());
        expect(testLogger.statusText, contains('A new version of Flutter is available'));
        expect(testLogger.statusText, contains('The latest version: 4.5.6 (revision def456)'));
        expect(testLogger.statusText, contains('Your current version: 1.2.3 (revision abc123)'));
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'fetchLatestVersion returns version if git succeeds',
      () async {
        const revision = 'abc123';
        const version = '1.2.3';

        processManager.addCommands(<FakeCommand>[
          const FakeCommand(command: <String>['git', 'fetch', '--tags']),
          const FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            stdout: revision,
          ),
          const FakeCommand(
            command: <String>['git', 'tag', '--points-at', revision],
            stdout: version,
          ),
        ]);

        final FlutterVersion updateVersion = await realCommandRunner.fetchLatestVersion(
          localVersion: FakeFlutterVersion(),
        );

        expect(updateVersion.frameworkVersion, version);
        expect(updateVersion.frameworkRevision, revision);
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'fetchLatestVersion returns latest version if the upstream revision has multiple tags',
      () async {
        const latestVersion = '3.4.5';
        const tags = <String>['1.2.3', '1.2.4', latestVersion];
        const revision = 'abc123';

        processManager.addCommands(<FakeCommand>[
          const FakeCommand(command: <String>['git', 'fetch', '--tags']),
          const FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            stdout: revision,
          ),
          FakeCommand(
            command: const <String>['git', 'tag', '--points-at', revision],
            stdout: tags.join('\n'),
          ),
        ]);

        final FlutterVersion updateVersion = await realCommandRunner.fetchLatestVersion(
          localVersion: FakeFlutterVersion(),
        );

        expect(updateVersion.frameworkVersion, latestVersion);
        expect(updateVersion.frameworkRevision, revision);
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'fetchLatestVersion throws toolExit if HEAD is detached',
      () async {
        processManager.addCommands(const <FakeCommand>[
          FakeCommand(command: <String>['git', 'fetch', '--tags']),
          FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            exception: ProcessException('git', <String>[
              'rev-parse',
              '--verify',
              '@{upstream}',
            ], 'fatal: HEAD does not point to a branch'),
          ),
        ]);

        await expectLater(
          () async => realCommandRunner.fetchLatestVersion(localVersion: FakeFlutterVersion()),
          throwsToolExit(
            message:
                'Unable to upgrade Flutter: Your Flutter checkout '
                'is currently not on a release branch.\n'
                'Use "flutter channel" to switch to an official channel, and retry. '
                'Alternatively, re-install Flutter by going to https://flutter.dev/setup.',
          ),
        );
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'fetchLatestVersion throws toolExit if no upstream configured',
      () async {
        processManager.addCommands(const <FakeCommand>[
          FakeCommand(command: <String>['git', 'fetch', '--tags']),
          FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            exception: ProcessException('git', <String>[
              'rev-parse',
              '--verify',
              '@{upstream}',
            ], 'fatal: no upstream configured for branch'),
          ),
        ]);

        await expectLater(
          () async => realCommandRunner.fetchLatestVersion(localVersion: FakeFlutterVersion()),
          throwsToolExit(
            message:
                'Unable to upgrade Flutter: The current Flutter '
                'branch/channel is not tracking any remote repository.\n'
                'Re-install Flutter by going to https://flutter.dev/setup.',
          ),
        );
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'git exception during attemptReset throwsToolExit',
      () async {
        const revision = 'abc123';
        const errorMessage = 'fatal: Could not parse object ´$revision´';
        processManager.addCommand(
          const FakeCommand(
            command: <String>['git', 'reset', '--hard', revision],
            exception: ProcessException('git', <String>['reset', '--hard', revision], errorMessage),
          ),
        );

        await expectLater(
          () async => realCommandRunner.attemptReset(revision),
          throwsToolExit(message: errorMessage),
        );
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'flutterUpgradeContinue passes env variables to child process',
      () async {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              globals.fs.path.join('bin', 'flutter'),
              'upgrade',
              '--continue',
              '--continue-started-at',
              '2026-01-01T00:00:00.000Z',
              '--no-version-check',
            ],
            environment: <String, String>{
              'FLUTTER_ALREADY_LOCKED': 'true',
              ...fakePlatform.environment,
            },
          ),
        );
        await realCommandRunner.flutterUpgradeContinue(startedAt: jan12026);
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'Show current version to the upgrade message.',
      () async {
        const revision = 'abc123';
        const upstreamRevision = 'def456';
        const version = '1.2.3';
        const upstreamVersion = '4.5.6';

        final flutterVersion = FakeFlutterVersion(
          branch: 'beta',
          frameworkRevision: revision,
          frameworkVersion: version,
        );
        final latestVersion = FakeFlutterVersion(
          frameworkRevision: upstreamRevision,
          frameworkVersion: upstreamVersion,
        );

        fakeCommandRunner.alreadyUpToDate = false;
        fakeCommandRunner.remoteVersion = latestVersion;
        fakeCommandRunner.workingDirectory = 'workingDirectory/aaa/bbb';

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: true,
          testFlow: true,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(
          testLogger.statusText,
          contains('Upgrading Flutter to 4.5.6 from 1.2.3 in workingDirectory/aaa/bbb...'),
        );
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'Can upgrade to a newer version with the same Git revision',
      () async {
        const revision = 'abc123';
        const version = '1.2.3';
        const upstreamVersion = '4.5.6';

        final flutterVersion = FakeFlutterVersion(
          frameworkRevision: revision,
          frameworkVersion: version,
          gitTagVersion: GitTagVersion.parse(version),
        );
        final latestVersion = FakeFlutterVersion(
          frameworkRevision: revision,
          frameworkVersion: upstreamVersion,
          gitTagVersion: GitTagVersion.parse(upstreamVersion),
        );

        fakeCommandRunner.alreadyUpToDate = false;
        fakeCommandRunner.remoteVersion = latestVersion;
        fakeCommandRunner.workingDirectory = 'workingDirectory/aaa/bbb';

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: true,
          testFlow: true,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(
          testLogger.statusText,
          contains('Upgrading Flutter to 4.5.6 from 1.2.3 in workingDirectory/aaa/bbb...'),
        );
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'Does not confuse an older release with the same revision as an available update',
      () async {
        const revision = 'abc123';
        const version = '4.5.6';
        final GitTagVersion currentTag = GitTagVersion.parse(version);
        const upstreamVersion = '1.2.3';
        final GitTagVersion upstreamTag = GitTagVersion.parse(upstreamVersion);

        final flutterVersion = FakeFlutterVersion(
          branch: 'stable',
          frameworkRevision: revision,
          frameworkVersion: version,
          gitTagVersion: currentTag,
        );
        final latestVersion = FakeFlutterVersion(
          branch: 'stable',
          frameworkRevision: revision,
          frameworkVersion: upstreamVersion,
          gitTagVersion: upstreamTag,
        );

        fakeCommandRunner.alreadyUpToDate = false;
        fakeCommandRunner.remoteVersion = latestVersion;
        fakeCommandRunner.workingDirectory = 'workingDirectory/aaa/bbb';

        final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
          const UpgradePhase.firstHalf(),
          force: true,
          testFlow: true,
          gitTagVersion: currentTag,
          flutterVersion: flutterVersion,
          verifyOnly: false,
        );
        expect(await result, FlutterCommandResult.success());
        expect(testLogger.statusText, contains('Flutter is already up to date on channel stable'));
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    testUsingContext(
      'precacheArtifacts passes env variables to child process',
      () async {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              globals.fs.path.join('bin', 'flutter'),
              '--no-color',
              '--no-version-check',
              'precache',
            ],
            environment: <String, String>{
              'FLUTTER_ALREADY_LOCKED': 'true',
              ...fakePlatform.environment,
            },
          ),
        );
        await precacheArtifacts();
        expect(processManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        ProcessManager: () => processManager,
        Platform: () => fakePlatform,
      },
    );

    group('runs upgrade', () {
      setUp(() {
        processManager.addCommand(
          FakeCommand(
            command: <String>[
              globals.fs.path.join('bin', 'flutter'),
              'upgrade',
              '--continue',
              '--continue-started-at',
              '2026-01-01T00:00:00.000Z',
              '--no-version-check',
            ],
          ),
        );
      });

      testUsingContext(
        'does not throw on unknown tag, official branch, force',
        () async {
          fakeCommandRunner.remoteVersion = FakeFlutterVersion(frameworkRevision: '1234');
          final flutterVersion = FakeFlutterVersion(branch: 'beta');

          final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
            const UpgradePhase.firstHalf(),
            force: true,
            testFlow: false,
            gitTagVersion: const GitTagVersion.unknown(),
            flutterVersion: flutterVersion,
            verifyOnly: false,
          );
          expect(await result, FlutterCommandResult.success());
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => processManager,
          Platform: () => fakePlatform,
        },
      );

      testUsingContext(
        'does not throw tool exit with uncommitted changes and force',
        () async {
          final flutterVersion = FakeFlutterVersion(branch: 'beta');
          fakeCommandRunner.remoteVersion = FakeFlutterVersion(frameworkRevision: '1234');
          fakeCommandRunner.willHaveUncommittedChanges = true;

          final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
            const UpgradePhase.firstHalf(),
            force: true,
            testFlow: false,
            gitTagVersion: gitTagVersion,
            flutterVersion: flutterVersion,
            verifyOnly: false,
          );
          expect(await result, FlutterCommandResult.success());
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => processManager,
          Platform: () => fakePlatform,
        },
      );

      testUsingContext(
        "Doesn't throw on known tag, beta branch, no force",
        () async {
          final flutterVersion = FakeFlutterVersion(branch: 'beta');
          fakeCommandRunner.remoteVersion = FakeFlutterVersion(frameworkRevision: '1234');

          final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
            const UpgradePhase.firstHalf(),
            force: true,
            testFlow: false,
            gitTagVersion: gitTagVersion,
            flutterVersion: flutterVersion,
            verifyOnly: false,
          );
          expect(await result, FlutterCommandResult.success());
          expect(processManager, hasNoRemainingExpectations);
        },
        overrides: <Type, Generator>{
          ProcessManager: () => processManager,
          Platform: () => fakePlatform,
        },
      );

      group('full command', () {
        late FakeProcessManager fakeProcessManager;
        late Directory tempDir;
        late File flutterToolState;
        late FileSystem fs;

        setUp(() {
          Cache.disableLocking();
          fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(command: <String>['git', 'tag', '--points-at', 'HEAD']),
            const FakeCommand(
              command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
              stdout: 'v1.12.16-19-gb45b676af',
            ),
          ]);
          fs = MemoryFileSystem.test();
          tempDir = fs.systemTempDirectory.createTempSync('flutter_upgrade_test.');
          flutterToolState = tempDir.childFile('.flutter_tool_state');
        });

        tearDown(() {
          Cache.enableLocking();
          tryToDelete(tempDir);
        });

        testUsingContext(
          'upgrade continue prints welcome message',
          () async {
            fakeProcessManager = FakeProcessManager.any();
            final upgradeCommand = UpgradeCommand(
              verboseHelp: false,
              commandRunner: fakeCommandRunner,
            );

            await createTestCommandRunner(upgradeCommand).run(<String>[
              'upgrade',
              '--continue',
              '--continue-started-at',
              DateTime.now().toIso8601String(),
            ]);

            expect(
              json.decode(flutterToolState.readAsStringSync()),
              containsPair('redisplay-welcome-message', true),
            );
          },
          overrides: <Type, Generator>{
            FileSystem: () => fs,
            FlutterVersion: () => FakeFlutterVersion(),
            ProcessManager: () => fakeProcessManager,
            PersistentToolState: () =>
                PersistentToolState.test(directory: tempDir, logger: testLogger),
          },
        );
      });
    });
  });
}

class FakeUpgradeCommandRunner extends UpgradeCommandRunner {
  var willHaveUncommittedChanges = false;
  var alreadyUpToDate = false;

  late FlutterVersion remoteVersion;

  @override
  Future<FlutterVersion> fetchLatestVersion({FlutterVersion? localVersion}) async => remoteVersion;

  @override
  Future<bool> hasUncommittedChanges() async => willHaveUncommittedChanges;

  @override
  Future<void> attemptReset(String newRevision) async {}

  @override
  Future<void> updatePackages(FlutterVersion flutterVersion) async {}

  @override
  Future<void> runDoctor() async {}
}
