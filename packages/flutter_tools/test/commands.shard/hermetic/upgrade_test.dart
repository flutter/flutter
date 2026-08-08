// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late FakeProcessManager processManager;
  const flutterRoot = '/path/to/flutter';

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
  });

  CommandRunner<void> createRunner({FlutterVersion? flutterVersion}) {
    final toolContext = FakeToolContext(
      fs: fileSystem,
      cache: Cache.test(
        fileSystem: fileSystem,
        flutterRoot: flutterRoot,
        processManager: processManager,
      ),
      flutterVersion: flutterVersion,
      logger: logger,
      processManager: processManager,
    );
    final command = UpgradeCommand(
      toolContext: toolContext,
      verboseHelp: false,
      commandRunner: UpgradeCommandRunner(toolContext: toolContext)
        ..clock = SystemClock.fixed(DateTime.utc(2026)),
    );
    return createTestCommandRunner(command);
  }

  testWithoutContext('can auto-migrate a user from dev to beta', () async {
    final CommandRunner<void> runner = createRunner(
      flutterVersion: FakeFlutterVersion(branch: 'dev'),
    );
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
          '/path/to/flutter/bin/flutter',
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
  });

  const startingTag = '3.0.0';
  const latestUpstreamTag = '3.1.0';
  const upstreamHeadRevision = '5765737420536964652053746f7279';

  testWithoutContext('can push people from master to beta', () async {
    final CommandRunner<void> runner = createRunner(
      flutterVersion: FakeFlutterVersion(frameworkVersion: startingTag, engineRevision: 'engine'),
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
          '/path/to/flutter/bin/flutter',
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
      'Upgrading Flutter to 3.1.0 from 3.0.0 in $flutterRoot...\n'
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
  });

  testWithoutContext('do not push people from beta to anything else', () async {
    final CommandRunner<void> runner = createRunner(
      flutterVersion: FakeFlutterVersion(
        branch: 'beta',
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      ),
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
      const FakeCommand(command: <String>['git', 'fetch', '--tags'], workingDirectory: flutterRoot),
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
          '/path/to/flutter/bin/flutter',
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
      'Upgrading Flutter to 3.1.0 from 3.0.0 in $flutterRoot...\n'
      '\n'
      'Upgrading engine...\n'
      '\n'
      "Instance of 'FakeFlutterVersion'\n" // the real FlutterVersion has a better toString, heh
      '\n'
      'Running flutter doctor...\n'
      'Took 0.0s\n',
    );
  });

  testWithoutContext(
    'allows upgrading if the only local modifications are pubspec.lock files',
    () async {
      final CommandRunner<void> runner = createRunner(
        flutterVersion: FakeFlutterVersion(frameworkVersion: startingTag, engineRevision: 'engine'),
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
            '/path/to/flutter/bin/flutter',
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
  );

  testWithoutContext('fails upgrading on stable if pubspec.lock files are modified', () async {
    final CommandRunner<void> runner = createRunner(
      flutterVersion: FakeFlutterVersion(
        branch: 'stable',
        frameworkVersion: startingTag,
        engineRevision: 'engine',
      ),
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
  });
}
