// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

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
    const GitTagVersion gitTagVersion = GitTagVersion(1, 2, 3, 4, 5, 'asd');
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
      fakeCommandRunner.alreadyUpToDate = true;
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

    testUsingContext('verifyUpstreamConfigured', () async {
      when(globals.processManager.run(
        <String>['git', 'rev-parse', '@{u}'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((Invocation invocation) async {
        return FakeProcessResult()
          ..exitCode = 0;
      });
      await realCommandRunner.verifyUpstreamConfigured();
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
              'git', 'describe', '--match', 'v*.*.*', '--first-parent', '--long', '--tags',
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

  group('matchesGitLine', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    bool _match(String line) => UpgradeCommandRunner.matchesGitLine(line);

    test('regex match', () {
      expect(_match(' .../flutter_gallery/lib/demo/buttons_demo.dart    | 10 +--'), true);
      expect(_match(' dev/benchmarks/complex_layout/lib/main.dart        |  24 +-'), true);

      expect(_match(' rename {packages/flutter/doc => dev/docs}/styles.html (92%)'), true);
      expect(_match(' delete mode 100644 doc/index.html'), true);
      expect(_match(' create mode 100644 dev/integration_tests/flutter_gallery/lib/gallery/demo.dart'), true);

      expect(_match('Fast-forward'), true);
    });

    test("regex doesn't match", () {
      expect(_match('Updating 79cfe1e..5046107'), false);
      expect(_match('229 files changed, 6179 insertions(+), 3065 deletions(-)'), false);
    });

    group('findProjectRoot', () {
      Directory tempDir;

      setUp(() async {
        tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_upgrade_test.');
      });

      tearDown(() {
        tryToDelete(tempDir);
      });

      testUsingContext('in project', () async {
        final String projectPath = await createProject(tempDir);
        expect(findProjectRoot(projectPath), projectPath);
        expect(findProjectRoot(globals.fs.path.join(projectPath, 'lib')), projectPath);

        final String hello = globals.fs.path.join(Cache.flutterRoot, 'examples', 'hello_world');
        expect(findProjectRoot(hello), hello);
        expect(findProjectRoot(globals.fs.path.join(hello, 'lib')), hello);
      });

      testUsingContext('outside project', () async {
        final String projectPath = await createProject(tempDir);
        expect(findProjectRoot(globals.fs.directory(projectPath).parent.path), null);
        expect(findProjectRoot(Cache.flutterRoot), null);
      });
    });
  });
}

class FakeUpgradeCommandRunner extends UpgradeCommandRunner {
  bool willHaveUncomittedChanges = false;

  bool alreadyUpToDate = false;

  @override
  Future<void> verifyUpstreamConfigured() async {}

  @override
  Future<bool> hasUncomittedChanges() async => willHaveUncomittedChanges;

  @override
  Future<void> resetChanges(GitTagVersion gitTagVersion) async {}

  @override
  Future<void> upgradeChannel(FlutterVersion flutterVersion) async {}

  @override
  Future<bool> attemptFastForward(FlutterVersion flutterVersion) async => alreadyUpToDate;

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
