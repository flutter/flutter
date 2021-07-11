// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor/globals.dart';
import 'package:conductor/repository.dart';
import 'package:conductor/roll_dev.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import './common.dart';
import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';

void main() {
  group('rollDev()', () {
    const String usage = 'usage info...';
    const String level = 'm';
    const String commit = 'abcde012345';
    const String remote = 'origin';
    const String lastVersion = '1.2.0-0.0.pre';
    const String nextVersion = '1.2.0-2.0.pre';
    const String candidateBranch = 'flutter-1.2-candidate.2';
    const String checkoutsParentDirectory = '/path/to/directory/';
    late FakeArgResults fakeArgResults;
    late MemoryFileSystem fileSystem;
    late TestStdio stdio;
    late FrameworkRepository repo;
    late Checkouts checkouts;
    late FakePlatform platform;
    late FakeProcessManager processManager;

    setUp(() {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
      platform = FakePlatform();
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      repo = FrameworkRepository(checkouts);
    });

    test('throws Exception if level not provided', () {
      fakeArgResults = FakeArgResults(
        level: null,
        candidateBranch: candidateBranch,
        remote: remote,
      );
      expect(
        () => rollDev(
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
          usage: usage,
        ),
        throwsExceptionWith(usage),
      );
    });

    test('throws exception if git checkout not clean', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ], stdout: ' M dev/conductor/bin/conductor.dart'),
      ]);
      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
      );
      expect(
        () => rollDev(
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
          usage: usage,
        ),
        throwsExceptionWith('Your git repository is not clean.'),
      );
    });

    test('does not reset or tag if --just-print is specified', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: 'zxy321'),
      ]);

      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
        justPrint: true,
      );
      expect(
        rollDev(
          usage: usage,
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
        ),
        false,
      );
      expect(stdio.logs.join('').contains(nextVersion), true);
    });

    test("exits with exception if --skip-tagging is provided but commit isn't already tagged", () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: 'zxy321'),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--exact-match',
          '--tags',
          commit,
        ], exitCode: 1),
      ]);

      const String exceptionMessage =
          'The $kSkipTagging flag is only supported '
          'for tagged commits.';

      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
        skipTagging: true,
      );
      expect(
        () => rollDev(
          usage: usage,
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
        ),
        throwsExceptionWith(exceptionMessage),
      );
    });

    test('throws exception if desired commit is already tip of dev branch', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        // [commit] is already [lastVersion]
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: commit),
      ]);
      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
        justPrint: true,
      );
      expect(
        () => rollDev(
          usage: usage,
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
        ),
        throwsExceptionWith(
          'Commit $commit is already on the dev branch as $lastVersion',
        ),
      );
    });

    test(
        'does not tag if last release is not direct ancestor of desired '
        'commit and --force not supplied', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: 'zxy321'),
        const FakeCommand(command: <String>[
          'git',
          'merge-base',
          '--is-ancestor',
          lastVersion,
          commit,
        ], exitCode: 1),
      ]);

      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
      );
      const String errorMessage = 'The previous dev tag $lastVersion is not a '
          'direct ancestor of $commit.';
      expect(
        () => rollDev(
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
          usage: usage,
        ),
        throwsExceptionWith(errorMessage),
      );
    });

    test('does not tag but updates branch if --skip-tagging provided', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: 'zxy321'),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--exact-match',
          '--tags',
          commit,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'merge-base',
          '--is-ancestor',
          lastVersion,
          commit,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          commit,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'push',
          remote,
          '$commit:dev',
        ]),
      ]);
      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
        skipTagging: true,
      );
      expect(
        rollDev(
          usage: usage,
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
        ),
        true,
      );
    });

    test('successfully tags and publishes release', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: 'zxy321'),
        const FakeCommand(command: <String>[
          'git',
          'merge-base',
          '--is-ancestor',
          lastVersion,
          commit,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          commit,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'tag',
          nextVersion,
          commit,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'push',
          remote,
          nextVersion,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'push',
          remote,
          '$commit:dev',
        ]),
      ]);
      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
      );
      expect(
        rollDev(
          usage: usage,
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
        ),
        true,
      );
    });

    test('successfully publishes release with --force', () {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          kUpstreamRemote,
          '${checkoutsParentDirectory}flutter_conductor_checkouts/framework',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'remote',
          'get-url',
          remote,
        ], stdout: kUpstreamRemote),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'fetch',
          remote,
          '--tags',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          candidateBranch,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'describe',
          '--match',
          '*.*.*',
          '--exact-match',
          '--tags',
          'refs/remotes/$remote/dev',
        ], stdout: lastVersion),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          lastVersion,
        ], stdout: 'zxy321'),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          commit,
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'tag',
          nextVersion,
          commit,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'push',
          remote,
          nextVersion,
        ]),
        const FakeCommand(command: <String>[
          'git',
          'push',
          '--force',
          remote,
          '$commit:dev',
        ]),
      ]);

      fakeArgResults = FakeArgResults(
        level: level,
        candidateBranch: candidateBranch,
        remote: remote,
        force: true,
      );
      expect(
        rollDev(
          argResults: fakeArgResults,
          repository: repo,
          stdio: stdio,
          usage: usage,
        ),
        true,
      );
      expect(processManager.hasRemainingExpectations, false);
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
