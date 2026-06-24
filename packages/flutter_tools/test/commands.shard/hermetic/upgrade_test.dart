// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/git.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' show FakeAndroidSdk, FakeFlutterVersion;
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late FakeProcessManager processManager;
  late FakeToolContext fakeToolContext;
  UpgradeCommand command;
  late CommandRunner<void> runner;
  const flutterRoot = '/path/to/flutter';

  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = flutterRoot;
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.directory(flutterRoot).createSync(recursive: true);
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();

    final testPlatform = FakePlatform();
    final testProcessUtils = ProcessUtils(processManager: processManager, logger: logger);
    final testGit = Git(currentPlatform: testPlatform, runProcessWith: testProcessUtils);
    final testFlutterVersion = FakeFlutterVersion(branch: 'dev');
    final testPersistentToolState = PersistentToolState.test(
      directory: fileSystem.directory(flutterRoot),
      logger: logger,
    );

    fakeToolContext = FakeToolContext(
      fs: fileSystem,
      logger: logger,
      platform: testPlatform,
      git: testGit,
      flutterVersion: testFlutterVersion,
      persistentToolState: testPersistentToolState,
      processUtils: testProcessUtils,
      systemClock: SystemClock.fixed(DateTime.utc(2026)),
    );

    command = UpgradeCommand(toolContext: fakeToolContext, verboseHelp: false);
    runner = createTestCommandRunner(command);
  });

  testUsingContext(
    'can auto-migrate a user from dev to beta',
    () async {
      const startingTag = '3.0.0-1.2.pre';
      const latestUpstreamTag = '3.0.0-1.3.pre';
      const upstreamHeadRevision = 'deadbeef';
      final reEntryCompleter = Completer<void>();

      Future<void> reEnterTool(List<String> command) async {
        await runner.run(<String>[
          'upgrade',
          '--continue',
          '--continue-started-at',
          '2026-01-01T00:00:00.000Z',
          '--no-version-check',
        ]);
        reEntryCompleter.complete();
      }

      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: startingTag,
        ),
        // Ensure we have upstream tags present locally
        const FakeCommand(command: <String>['git', 'fetch', '--tags']),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
          stdout: upstreamHeadRevision,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', upstreamHeadRevision],
          stdout: latestUpstreamTag,
        ),
        // check for uncommitted changes; empty stdout means clean checkout
        const FakeCommand(command: <String>['git', 'status', '-s']),

        // here the tool is upgrading the branch from dev -> beta
        const FakeCommand(command: <String>['git', 'fetch']),
        // test if there already exists a local beta branch; 0 exit code means yes
        const FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        ),
        const FakeCommand(command: <String>['git', 'checkout', 'beta', '--']),

        // reset instead of pull since cherrypicks from one release branch will
        // not be present on a newer one
        const FakeCommand(command: <String>['git', 'reset', '--hard', upstreamHeadRevision]),
        // re-enter flutter command with the newer version, so that `doctor`
        // checks will be up to date
        FakeCommand(
          command: const <String>[
            'bin/flutter',
            'upgrade',
            '--continue',
            '--continue-started-at',
            '2026-01-01T00:00:00.000Z',
            '--no-version-check',
          ],
          onRun: reEnterTool,
          completer: reEntryCompleter,
        ),

        // commands following this are from the re-entrant `flutter upgrade --continue` call
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: latestUpstreamTag,
        ),
        const FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
        const FakeCommand(command: <String>['bin/flutter', '--no-version-check', 'doctor']),
      ]);
      await runner.run(<String>['upgrade']);
      expect(processManager, hasNoRemainingExpectations);
      expect(logger.statusText, contains("Transitioning from 'dev' to 'beta'..."));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FlutterVersion: () => FakeFlutterVersion(branch: 'dev'),
      Logger: () => logger,
      ProcessManager: () => processManager,
      AndroidSdk: () => FakeAndroidSdk(),
    },
  );

  const startingTag = '3.0.0';
  const latestUpstreamTag = '3.1.0';
  const upstreamHeadRevision = '5765737420536964652053746f7279';

  testUsingContext(
    'can push people from master to beta',
    () async {
      fakeToolContext.flutterVersion = FakeFlutterVersion(
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      );
      final reEntryCompleter = Completer<void>();

      Future<void> reEnterTool(List<String> args) async {
        await runner.run(<String>[
          'upgrade',
          '--continue',
          '--continue-started-at',
          '2026-01-01T00:00:00.000Z',
          '--no-version-check',
        ]);
        reEntryCompleter.complete();
      }

      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: startingTag,
        ),
        const FakeCommand(command: <String>['git', 'fetch', '--tags']),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
          stdout: upstreamHeadRevision,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', upstreamHeadRevision],
          stdout: latestUpstreamTag,
        ),
        const FakeCommand(command: <String>['git', 'status', '-s']),
        const FakeCommand(command: <String>['git', 'reset', '--hard', upstreamHeadRevision]),
        FakeCommand(
          command: const <String>[
            'bin/flutter',
            'upgrade',
            '--continue',
            '--continue-started-at',
            '2026-01-01T00:00:00.000Z',
            '--no-version-check',
          ],
          onRun: reEnterTool,
          completer: reEntryCompleter,
        ),

        // commands following this are from the re-entrant `flutter upgrade --continue` call
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: latestUpstreamTag,
        ),
        const FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
        const FakeCommand(command: <String>['bin/flutter', '--no-version-check', 'doctor']),
      ]);
      await runner.run(<String>['upgrade']);
      expect(processManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        'Upgrading Flutter to 3.1.0 from 3.0.0 in ${Cache.flutterRoot}...\n'
        '\n'
        'Upgrading engine...\n'
        '\n'
        "Instance of 'FakeFlutterVersion'\n" // the real FlutterVersion has a better toString, heh
        '\n'
        'Running flutter doctor...\n'
        '\n'
        'This channel is intended for Flutter contributors. This channel is not as thoroughly '
        'tested as the "beta" and "stable" channels. We do not recommend using this channel '
        'for normal use as it more likely to contain serious regressions.\n'
        '\n'
        'For information on contributing to Flutter, see our contributing guide:\n'
        '    https://github.com/flutter/flutter/blob/main/CONTRIBUTING.md\n'
        '\n'
        'For the most up to date stable version of flutter, consider using the "beta" channel '
        'instead. The Flutter "beta" channel enjoys all the same automated testing as the '
        '"stable" channel, but is updated roughly once a month instead of once a quarter.\n'
        'To change channel, run the "flutter channel beta" command.\n'
        'Took 0.0s\n',
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FlutterVersion: () =>
          FakeFlutterVersion(frameworkVersion: startingTag, engineRevision: 'engine'),
      Logger: () => logger,
      ProcessManager: () => processManager,
      AndroidSdk: () => FakeAndroidSdk(),
    },
  );

  testUsingContext(
    'do not push people from beta to anything else',
    () async {
      fakeToolContext.flutterVersion = FakeFlutterVersion(
        branch: 'beta',
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      );
      final reEntryCompleter = Completer<void>();

      Future<void> reEnterTool(List<String> command) async {
        await runner.run(<String>[
          'upgrade',
          '--continue',
          '--continue-started-at',
          '2026-01-01T00:00:00.000Z',
          '--no-version-check',
        ]);
        reEntryCompleter.complete();
      }

      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: startingTag,
          workingDirectory: flutterRoot,
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', '--tags'],
          workingDirectory: flutterRoot,
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
          stdout: upstreamHeadRevision,
          workingDirectory: flutterRoot,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', upstreamHeadRevision],
          stdout: latestUpstreamTag,
          workingDirectory: flutterRoot,
        ),
        const FakeCommand(command: <String>['git', 'status', '-s'], workingDirectory: flutterRoot),
        const FakeCommand(
          command: <String>['git', 'reset', '--hard', upstreamHeadRevision],
          workingDirectory: flutterRoot,
        ),
        FakeCommand(
          command: const <String>[
            'bin/flutter',
            'upgrade',
            '--continue',
            '--continue-started-at',
            '2026-01-01T00:00:00.000Z',
            '--no-version-check',
          ],
          onRun: reEnterTool,
          completer: reEntryCompleter,
          workingDirectory: flutterRoot,
        ),

        // commands following this are from the re-entrant `flutter upgrade --continue` call
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: latestUpstreamTag,
          workingDirectory: flutterRoot,
        ),
        const FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
          workingDirectory: flutterRoot,
        ),
        const FakeCommand(
          command: <String>['bin/flutter', '--no-version-check', 'doctor'],
          workingDirectory: flutterRoot,
        ),
      ]);
      await runner.run(<String>['upgrade']);
      expect(processManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        'Upgrading Flutter to 3.1.0 from 3.0.0 in ${Cache.flutterRoot}...\n'
        '\n'
        'Upgrading engine...\n'
        '\n'
        "Instance of 'FakeFlutterVersion'\n" // the real FlutterVersion has a better toString, heh
        '\n'
        'Running flutter doctor...\n'
        'Took 0.0s\n',
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FlutterVersion: () => FakeFlutterVersion(
        branch: 'beta',
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      ),
      Logger: () => logger,
      ProcessManager: () => processManager,
      AndroidSdk: () => FakeAndroidSdk(),
    },
  );
  testUsingContext(
    'allows upgrading if the only local modifications are pubspec.lock files',
    () async {
      fakeToolContext.flutterVersion = FakeFlutterVersion(
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      );
      final reEntryCompleter = Completer<void>();

      Future<void> reEnterTool(List<String> args) async {
        reEntryCompleter.complete();
      }

      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: startingTag,
        ),
        const FakeCommand(command: <String>['git', 'fetch', '--tags']),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
          stdout: upstreamHeadRevision,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', upstreamHeadRevision],
          stdout: latestUpstreamTag,
        ),
        const FakeCommand(
          command: <String>['git', 'status', '-s'],
          stdout: ' M packages/flutter/pubspec.lock\n M packages/flutter_tools/pubspec.lock\n',
        ),
        const FakeCommand(command: <String>['git', 'reset', '--hard', upstreamHeadRevision]),
        FakeCommand(
          command: const <String>[
            'bin/flutter',
            'upgrade',
            '--continue',
            '--continue-started-at',
            '2026-01-01T00:00:00.000Z',
            '--no-version-check',
          ],
          onRun: reEnterTool,
          completer: reEntryCompleter,
        ),
      ]);

      await runner.run(<String>['upgrade']);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FlutterVersion: () =>
          FakeFlutterVersion(frameworkVersion: startingTag, engineRevision: 'engine'),
      Logger: () => logger,
      ProcessManager: () => processManager,
      AndroidSdk: () => FakeAndroidSdk(),
    },
  );

  testUsingContext(
    'fails upgrading on stable if pubspec.lock files are modified',
    () async {
      fakeToolContext.flutterVersion = FakeFlutterVersion(
        branch: 'stable',
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      );
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: startingTag,
        ),
        const FakeCommand(command: <String>['git', 'fetch', '--tags']),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
          stdout: upstreamHeadRevision,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', upstreamHeadRevision],
          stdout: latestUpstreamTag,
        ),
        const FakeCommand(
          command: <String>['git', 'status', '-s'],
          stdout: ' M packages/flutter/pubspec.lock\n',
        ),
      ]);

      expect(
        () => runner.run(<String>['upgrade']),
        throwsA(
          isA<ToolExit>().having(
            (ToolExit e) => e.message,
            'message',
            contains('Your flutter checkout has local changes'),
          ),
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      FlutterVersion: () => FakeFlutterVersion(
        branch: 'stable',
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      ),
      Logger: () => logger,
      ProcessManager: () => processManager,
      AndroidSdk: () => FakeAndroidSdk(),
    },
  );

  testUsingContext(
    'resolves all dependencies from ToolContext and not the Zone',
    () async {
      final mockFs = MemoryFileSystem.test();
      final mockLogger = BufferLogger.test();
      final mockPlatform = FakePlatform();
      final mockProcessManager = FakeProcessManager.empty();
      final mockProcessUtils = ProcessUtils(processManager: mockProcessManager, logger: mockLogger);
      final mockGit = Git(currentPlatform: mockPlatform, runProcessWith: mockProcessUtils);
      final mockClock = SystemClock.fixed(DateTime.utc(2026));
      final mockVersion = FakeFlutterVersion(branch: 'beta', frameworkRevision: 'abc');
      final mockPersistentToolState = PersistentToolState.test(
        directory: mockFs.systemTempDirectory.createTempSync('persistent_tool_state.'),
        logger: mockLogger,
      );

      final strictToolContext = FakeToolContext(
        fs: mockFs,
        logger: mockLogger,
        git: mockGit,
        systemClock: mockClock,
        platform: mockPlatform,
        persistentToolState: mockPersistentToolState,
        processUtils: mockProcessUtils,
        flutterVersion: mockVersion,
      );

      final strictCommand = UpgradeCommand(toolContext: strictToolContext, verboseHelp: false);

      final CommandRunner<void> strictRunner = createTestCommandRunner(strictCommand);

      mockProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>['git', 'tag', '--points-at', 'HEAD'], stdout: '3.0.0'),
        const FakeCommand(
          command: <String>[
            'git',
            '-c',
            'log.showSignature=false',
            'log',
            '-n',
            '1',
            '--pretty=format:%H',
          ],
          stdout: 'abc',
        ),
        const FakeCommand(command: <String>['git', 'tag', '--points-at', 'abc'], stdout: '3.0.0'),
        const FakeCommand(command: <String>['git', 'fetch', '--tags']),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
          stdout: 'def456',
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', '--abbrev-ref', '--symbolic', '@{upstream}'],
          stdout: 'upstream/beta',
        ),
        const FakeCommand(
          command: <String>['git', 'ls-remote', '--get-url', 'upstream'],
          stdout: 'https://github.com/flutter/flutter.git',
        ),
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'def456'],
          stdout: '3.1.0',
        ),
        const FakeCommand(command: <String>['git', 'status', '-s']),
        const FakeCommand(
          command: <String>['git', 'symbolic-ref', '--short', 'HEAD'],
          stdout: 'beta',
        ),
        const FakeCommand(command: <String>['git', 'reset', '--hard', 'def456']),
      ]);

      await strictRunner.run(<String>['upgrade', '--working-directory', '/path/to/flutter']);

      expect(mockProcessManager, hasNoRemainingExpectations);
      expect(mockLogger.statusText, contains('Upgrading Flutter to 3.1.0 from 3.0.0'));
    },
    overrides: <Type, Generator>{
      // Override AndroidSdk to null to prevent the runner from trying to locate Android SDK,
      // which falls back to executing 'which' on the host and throws due to FakeProcessManager.
      AndroidSdk: () => null,
    },
  );
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({
    required this.fs,
    required this.logger,
    required this.platform,
    required this.git,
    required this.flutterVersion,
    required this.persistentToolState,
    required this.processUtils,
    required this.systemClock,
  });

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final Platform platform;

  @override
  final Git git;

  @override
  FlutterVersion flutterVersion;

  @override
  final PersistentToolState persistentToolState;

  @override
  final ProcessUtils processUtils;

  @override
  final SystemClock systemClock;
}
