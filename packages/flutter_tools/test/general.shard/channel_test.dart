// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:flutter_tools/src/git.dart';
import 'package:flutter_tools/src/version.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  group('channel', () {
    late FakeProcessManager fakeProcessManager;
    late BufferLogger logger;
    late MemoryFileSystem fileSystem;

    setUp(() {
      fakeProcessManager = FakeProcessManager.empty();
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
    });

    setUpAll(() {
      Cache.disableLocking();
    });

    Future<void> simpleChannelTest(List<String> args) async {
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              '  origin/branch-1\n'
              '  origin/branch-2\n'
              '  origin/master\n'
              '  origin/main\n'
              '  origin/stable\n'
              '  origin/beta',
        ),
      ]);
      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(args);
      expect(logger.errorText, hasLength(0));
      // The bots may return an empty list of channels (network hiccup?)
      // and when run locally the list of branches might be different
      // so we check for the header text rather than any specific channel name.
      expect(logger.statusText, containsIgnoringWhitespace('Flutter channels:'));
    }

    test('usage (--help) explains how to use channel', () async {
      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: FakeProcessManager.empty(),
      );

      // Required because otherwise command.usage fails as it is not hooked up.
      createTestCommandRunner(command);

      // TODO(matanlurey): https://github.com/flutter/flutter/issues/158532
      //
      // <Command>.usage is checked instead of log output because by default
      // every command emits usage directly to stdout (via print) instead of
      // to the interfaces provided. It would be a much larger refactor to
      // change how every command works:
      expect(
        command.usage,
        stringContainsInOrder(<String>[
          'List or switch Flutter channels',
          'Common commands:',
          'List Flutter channels',
          "Switch to Flutter's main channel.",
        ]),
      );
    });

    test('list', () async {
      await simpleChannelTest(<String>['channel']);
    });

    test('verbose list', () async {
      await simpleChannelTest(<String>['channel', '-v']);
    });

    test('sorted by stability', () async {
      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);

      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/beta\n'
              'origin/master\n'
              'origin/main\n'
              'origin/stable\n',
        ),
      );

      await runner.run(<String>['channel']);
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.errorText, hasLength(0));
      expect(
        logger.statusText,
        'Flutter channels:\n'
        '* master (latest development branch, for contributors)\n'
        '  main (latest development branch, follows master channel)\n'
        '  beta (updated monthly, recommended for experienced users)\n'
        '  stable (updated quarterly, for new users and for production app releases)\n',
      );

      // clear buffer for next process
      logger.clear();

      // Extra branches.
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/beta\n'
              'origin/master\n'
              'origin/dependabot/bundler\n'
              'origin/main\n'
              'origin/v1.4.5-hotfixes\n'
              'origin/stable\n',
        ),
      );

      await runner.run(<String>['channel']);
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.errorText, hasLength(0));
      expect(
        logger.statusText,
        'Flutter channels:\n'
        '* master (latest development branch, for contributors)\n'
        '  main (latest development branch, follows master channel)\n'
        '  beta (updated monthly, recommended for experienced users)\n'
        '  stable (updated quarterly, for new users and for production app releases)\n',
      );

      // clear buffer for next process
      logger.clear();

      // Missing branches.
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/master\n'
              'origin/dependabot/bundler\n'
              'origin/v1.4.5-hotfixes\n'
              'origin/stable\n'
              'origin/beta\n',
        ),
      );

      await runner.run(<String>['channel']);
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.errorText, hasLength(0));
      // check if available official channels are in order of stability
      var prev = -1;
      var next = -1;
      for (final String branch in kOfficialChannels) {
        next = logger.statusText.indexOf(branch);
        if (next != -1) {
          expect(prev < next, isTrue);
          prev = next;
        }
      }
    });

    test('ignores lines with unexpected output', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/beta\n'
              'origin/stable\n'
              'upstream/beta\n'
              'upstream/stable\n'
              'foo',
        ),
      );

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
        flutterVersion: FakeFlutterVersion(branch: 'beta'),
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.errorText, hasLength(0));
      expect(
        logger.statusText,
        'Flutter channels:\n'
        '* beta (updated monthly, recommended for experienced users)\n'
        '  stable (updated quarterly, for new users and for production app releases)\n',
      );
    });

    test('handles custom branches', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/beta\n'
              'origin/stable\n'
              'origin/foo',
        ),
      );

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
        flutterVersion: FakeFlutterVersion(branch: 'foo'),
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.errorText, hasLength(0));
      expect(
        logger.statusText,
        'Flutter channels:\n'
        '  beta (updated monthly, recommended for experienced users)\n'
        '  stable (updated quarterly, for new users and for production app releases)\n'
        '* foo\n'
        '\n'
        'Currently not on an official channel.\n',
      );
    });

    test('removes duplicates', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/beta\n'
              'origin/stable\n'
              'upstream/beta\n'
              'upstream/stable\n',
        ),
      );

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
        flutterVersion: FakeFlutterVersion(branch: 'beta'),
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(logger.errorText, hasLength(0));
      expect(
        logger.statusText,
        'Flutter channels:\n'
        '* beta (updated monthly, recommended for experienced users)\n'
        '  stable (updated quarterly, for new users and for production app releases)\n',
      );
    });

    test('can switch channels', () async {
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta']),
        FakeCommand(command: <String>['git', 'checkout', 'beta', '--']),
        FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        containsIgnoringWhitespace("Switching to flutter channel 'beta'..."),
      );
      expect(logger.errorText, hasLength(0));

      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        ),
        FakeCommand(command: <String>['git', 'checkout', 'stable', '--']),
        FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
      ]);

      await runner.run(<String>['channel', 'stable']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('can switch channels with --force', () async {
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta']),
        FakeCommand(command: <String>['git', 'checkout', '-f', 'beta', '--']),
        FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', '--force', 'beta']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        containsIgnoringWhitespace("Switching to flutter channel 'beta'..."),
      );
      expect(logger.errorText, hasLength(0));
    });

    test('can switch channels with -f when branch does not exist locally', () async {
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
          exitCode: 1,
        ),
        FakeCommand(
          command: <String>['git', 'checkout', '-f', '--track', '-b', 'beta', 'origin/beta'],
        ),
        FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', '-f', 'beta']);

      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(
        logger.statusText,
        containsIgnoringWhitespace("Switching to flutter channel 'beta'..."),
      );
      expect(logger.errorText, hasLength(0));
    });

    test('switching channels prompts to run flutter upgrade', () async {
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta']),
        FakeCommand(command: <String>['git', 'checkout', 'beta', '--']),
        FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

      expect(
        logger.statusText,
        containsIgnoringWhitespace("Successfully switched to flutter channel 'beta'."),
      );
      expect(
        logger.statusText,
        containsIgnoringWhitespace(
          "To ensure that you're on the latest build "
          "from this channel, run 'flutter upgrade'",
        ),
      );
      expect(logger.errorText, hasLength(0));
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    // This verifies that bug https://github.com/flutter/flutter/issues/21134
    // doesn't return.
    test('removes version stamp file when switching channels', () async {
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta']),
        FakeCommand(command: <String>['git', 'checkout', 'beta', '--']),
        FakeCommand(
          command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
        ),
      ]);

      final testCache = Cache.test(fileSystem: fileSystem, processManager: fakeProcessManager);
      final File versionCheckFile = testCache.getStampFileFor(
        VersionCheckStamp.flutterVersionCheckStampFile,
      );

      /// Create a bogus "leftover" version check file to make sure it gets
      /// removed when the channel changes. The content doesn't matter.
      versionCheckFile.createSync(recursive: true);
      versionCheckFile.writeAsStringSync('''
        {
          "lastTimeVersionWasChecked": "2151-08-29 10:17:30.763802",
          "lastKnownRemoteVersion": "2151-09-26 15:56:19.000Z"
        }
      ''');

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

      expect(logger.statusText, isNot(contains('A new version of Flutter')));
      expect(logger.errorText, hasLength(0));
      expect(versionCheckFile.existsSync(), isFalse);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('deletes cached version file before precaching when switching channels', () async {
      final flutterVersion = FakeFlutterVersion();
      var deletedBeforePrecache = false;
      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>['git', 'fetch']),
        const FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        ),
        const FakeCommand(command: <String>['git', 'checkout', 'stable', '--']),
        FakeCommand(
          command: const <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
          onRun: (_) {
            deletedBeforePrecache = flutterVersion.didDeleteVersionFile;
          },
        ),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
        flutterVersion: flutterVersion,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'stable']);

      expect(deletedBeforePrecache, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('deletes cached version file when switching channels with --no-cache-artifacts', () async {
      final flutterVersion = FakeFlutterVersion();
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        ),
        FakeCommand(command: <String>['git', 'checkout', 'stable', '--']),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
        flutterVersion: flutterVersion,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', '--no-cache-artifacts', 'stable']);

      expect(flutterVersion.didDeleteVersionFile, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('does not delete cached version file when switching channels fails', () async {
      final flutterVersion = FakeFlutterVersion();
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        ),
        FakeCommand(command: <String>['git', 'checkout', 'stable', '--'], exitCode: 1),
      ]);

      final ChannelCommand command = createChannelCommand(
        logger: logger,
        fs: fileSystem,
        processManager: fakeProcessManager,
        flutterVersion: flutterVersion,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await expectLater(
        () => runner.run(<String>['channel', 'stable']),
        throwsToolExit(message: 'Switching channels failed'),
      );

      expect(flutterVersion.didDeleteVersionFile, isFalse);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('upgradeChannel deletes cached version file when transitioning channels', () async {
      final flutterVersion = FakeFlutterVersion(branch: 'dev');
      fakeProcessManager.addCommands(const <FakeCommand>[
        FakeCommand(command: <String>['git', 'fetch']),
        FakeCommand(command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta']),
        FakeCommand(command: <String>['git', 'checkout', 'beta', '--']),
      ]);

      final cache = Cache.test(fileSystem: fileSystem, processManager: fakeProcessManager);
      final processUtils = ProcessUtils(processManager: fakeProcessManager, logger: logger);
      final git = Git(currentPlatform: FakePlatform(), runProcessWith: processUtils);

      await ChannelCommand.upgradeChannel(flutterVersion, cache: cache, git: git, logger: logger);

      expect(flutterVersion.didDeleteVersionFile, isTrue);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    test('resolves dependencies from the injected ToolContext rather than the Zone', () async {
      final contextLogger = BufferLogger.test();
      final localFs = MemoryFileSystem.test();
      final localFakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout:
              'origin/beta\n'
              'origin/master\n'
              'origin/main\n'
              'origin/stable\n',
        ),
      ]);
      final processUtils = ProcessUtils(
        processManager: localFakeProcessManager,
        logger: contextLogger,
      );
      final fakePlatform = FakePlatform();
      final git = Git(currentPlatform: fakePlatform, runProcessWith: processUtils);

      final toolContext = FakeToolContext(
        fs: localFs,
        logger: contextLogger,
        platform: fakePlatform,
        processManager: localFakeProcessManager,
        processUtils: processUtils,
        git: git,
        flutterVersion: FakeFlutterVersion(),
      );

      final command = ChannelCommand(toolContext: toolContext);
      expect(command.toolContext, same(toolContext));
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['channel']);

      // Verify that the output went to the injected logger
      expect(contextLogger.statusText, contains('Flutter channels:'));
      expect(contextLogger.statusText, contains('* master'));
      expect(localFakeProcessManager, hasNoRemainingExpectations);
    });
  });
}

ChannelCommand createChannelCommand({
  FileSystem? fs,
  Logger? logger,
  Platform? platform,
  ProcessManager? processManager,
  ProcessUtils? processUtils,
  Git? git,
  FlutterVersion? flutterVersion,
  bool verboseHelp = false,
}) {
  final FileSystem resolvedFs = fs ?? MemoryFileSystem.test();
  final Platform resolvedPlatform = platform ?? FakePlatform();
  final ProcessManager resolvedProcessManager = processManager ?? FakeProcessManager.any();
  final Logger resolvedLogger = logger ?? BufferLogger.test();
  final ProcessUtils resolvedProcessUtils =
      processUtils ?? ProcessUtils(processManager: resolvedProcessManager, logger: resolvedLogger);
  return ChannelCommand(
    toolContext: FakeToolContext(
      fs: resolvedFs,
      logger: resolvedLogger,
      platform: resolvedPlatform,
      processManager: resolvedProcessManager,
      processUtils: resolvedProcessUtils,
      git: git ?? Git(currentPlatform: resolvedPlatform, runProcessWith: resolvedProcessUtils),
      flutterVersion: flutterVersion ?? FakeFlutterVersion(),
      cache: Cache.test(fileSystem: resolvedFs, processManager: resolvedProcessManager),
    ),
    verboseHelp: verboseHelp,
  );
}
