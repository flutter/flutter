// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late BufferLogger logger;
  late FileSystem fileSystem;
  late FakeProcessManager processManager;
  late CommandRunner<void> runner;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    logger = BufferLogger.test();
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
    runner = createTestCommandRunner();
  });

  group('version', () {
    const String startingRevision = '123';
    const String upstreamRevision = '456';
    const String upstreamTag = '7.8.9';
    const String repositoryUrl = 'abc.def';

    testUsingContext(
      'latest available version',
      () async {
        processManager.addCommands(<FakeCommand>[
          const FakeCommand(command: <String>['git', 'fetch', '--tags']),
          const FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            stdout: upstreamRevision,
          ),
          const FakeCommand(
            command: <String>['git', 'tag', '--points-at', upstreamRevision],
            stdout: upstreamTag,
          ),
        ]);
        await runner.run(<String>['--version']);
        expect(processManager, hasNoRemainingExpectations);
        expect(
          logger.statusText,
          "Instance of 'FakeFlutterVersion'\n"
          '\n'
          'Flutter is already up to date on channel master\n',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        FlutterVersion:
            () => FakeFlutterVersion(frameworkRevision: upstreamRevision),
        Logger: () => logger,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'new available version',
      () async {
        processManager.addCommands(<FakeCommand>[
          const FakeCommand(command: <String>['git', 'fetch', '--tags']),
          const FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            stdout: upstreamRevision,
          ),
          const FakeCommand(
            command: <String>['git', 'tag', '--points-at', upstreamRevision],
            stdout: upstreamTag,
          ),
        ]);
        await runner.run(<String>['--version']);
        expect(processManager, hasNoRemainingExpectations);
        expect(
          logger.statusText,
          "Instance of 'FakeFlutterVersion'\n"
          '\n'
          'A new version of Flutter is available on channel master\n'
          'The latest version: $upstreamTag (revision $upstreamRevision)\n'
          'To upgrade now, run "flutter upgrade".\n',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        FlutterVersion:
            () => FakeFlutterVersion(frameworkRevision: startingRevision),
        Logger: () => logger,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'detached head',
      () async {
        processManager.addCommands(<FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'fetch', '--tags'],
            exitCode: 1,
            stderr: 'fatal: HEAD does not point to a branch',
          ),
        ]);
        await runner.run(<String>['--version']);
        expect(processManager, hasNoRemainingExpectations);
        expect(
          logger.statusText,
          "Instance of 'FakeFlutterVersion'\n"
          '\n'
          'Unable to check for updates: Your Flutter checkout is currently not '
          'on a release branch.\n',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        FlutterVersion:
            () => FakeFlutterVersion(),
        Logger: () => logger,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'no upstream',
      () async {
        processManager.addCommands(<FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'fetch', '--tags'],
            exitCode: 1,
            stderr: 'fatal: no upstream configured for branch',
          ),
        ]);
        await runner.run(<String>['--version']);
        expect(processManager, hasNoRemainingExpectations);
        expect(
          logger.statusText,
          "Instance of 'FakeFlutterVersion'\n"
          '\n'
          'Unable to check for updates: The current Flutter branch/channel is '
          'not tracking any remote repository.\n',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        FlutterVersion:
            () => FakeFlutterVersion(),
        Logger: () => logger,
        ProcessManager: () => processManager,
      },
    );

    testUsingContext(
      'non-standard remote',
      () async {
        processManager.addCommands(<FakeCommand>[
          const FakeCommand(command: <String>['git', 'fetch', '--tags']),
          const FakeCommand(
            command: <String>['git', 'rev-parse', '--verify', '@{upstream}'],
            stdout: upstreamRevision,
          ),
        ]);
        await runner.run(<String>['--version']);
        expect(processManager, hasNoRemainingExpectations);
        expect(
          logger.statusText,
          "Instance of 'FakeFlutterVersion'\n"
          '\n'
          'Unable to check for updates: The Flutter SDK is tracking a '
          'non-standard remote "$repositoryUrl".\n'
          'Set the environment variable "FLUTTER_GIT_URL" to "$repositoryUrl". '
          'If this is intentional, it is recommended to use "git" directly '
          'to manage the SDK.\n'
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        FlutterVersion:
            () => FakeFlutterVersion(repositoryUrl: repositoryUrl),
        Logger: () => logger,
        ProcessManager: () => processManager,
      },
    );
  });
}
