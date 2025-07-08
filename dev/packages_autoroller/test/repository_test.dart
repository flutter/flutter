// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:packages_autoroller/src/repository.dart';
import 'package:platform/platform.dart';

import 'common.dart';

void main() {
  group('repository', () {
    late FakePlatform platform;
    const String rootDir = '/';
    const String revision = 'deadbeef';
    late MemoryFileSystem fileSystem;
    late FakeProcessManager processManager;
    late TestStdio stdio;

    setUp(() {
      final String pathSeparator = const LocalPlatform().pathSeparator;
      fileSystem = MemoryFileSystem.test();
      platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(pathSeparator),
        },
        pathSeparator: pathSeparator,
      );
      processManager = FakeProcessManager.empty();
      stdio = TestStdio();
    });

    test('commit() throws if there are no local changes to commit and addFirst = true', () {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      const String message = 'This is a commit message.';
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            fileSystem.path.join(rootDir, 'package_autoroller_checkouts', 'framework'),
          ],
        ),
        const FakeCommand(command: <String>['git', 'remote', 'add', 'mirror', 'mirror']),
        const FakeCommand(command: <String>['git', 'fetch', 'mirror']),
        const FakeCommand(command: <String>['git', 'checkout', FrameworkRepository.defaultBranch]),
        const FakeCommand(command: <String>['git', 'rev-parse', 'HEAD'], stdout: commit1),
        const FakeCommand(command: <String>['git', 'status', '--porcelain']),
        const FakeCommand(command: <String>['git', 'commit', '--message', message]),
        const FakeCommand(command: <String>['git', 'rev-parse', 'HEAD'], stdout: commit2),
      ]);

      final Checkouts checkouts = Checkouts(
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final FrameworkRepository repo = FrameworkRepository(
        checkouts,
        mirrorRemote: const Remote.mirror('mirror'),
      );
      expect(
        () async => repo.commit(message, addFirst: true),
        throwsExceptionWith('Tried to commit with message $message but no changes were present'),
      );
    });

    test('commit() passes correct commit message', () async {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      const String message = 'This is a commit message.';
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            fileSystem.path.join(rootDir, 'package_autoroller_checkouts', 'framework'),
          ],
        ),
        const FakeCommand(command: <String>['git', 'remote', 'add', 'mirror', 'mirror']),
        const FakeCommand(command: <String>['git', 'fetch', 'mirror']),
        const FakeCommand(command: <String>['git', 'checkout', FrameworkRepository.defaultBranch]),
        const FakeCommand(command: <String>['git', 'rev-parse', 'HEAD'], stdout: commit1),
        const FakeCommand(command: <String>['git', 'commit', '--message', message]),
        const FakeCommand(command: <String>['git', 'rev-parse', 'HEAD'], stdout: commit2),
      ]);

      final Checkouts checkouts = Checkouts(
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final FrameworkRepository repo = FrameworkRepository(
        checkouts,
        mirrorRemote: const Remote.mirror('mirror'),
      );
      await repo.commit(message);
      expect(processManager.hasRemainingExpectations, false);
    });

    test('.listRemoteBranches() parses git output', () async {
      const String remoteName = 'mirror';
      const String lsRemoteOutput = '''
Extraneous debug information that should be ignored.

4d44dca340603e25d4918c6ef070821181202e69        refs/heads/experiment
35185330c6af3a435f615ee8ac2fed8b8bb7d9d4        refs/heads/feature-a
6f60a1e7b2f3d2c2460c9dc20fe54d0e9654b131        refs/heads/feature-b
c1436c42c0f3f98808ae767e390c3407787f1a67        refs/heads/fix_bug_1234
bbbcae73699263764ad4421a4b2ca3952a6f96cb        refs/heads/stable

Extraneous debug information that should be ignored.
''';
      processManager.addCommands(const <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            '${rootDir}package_autoroller_checkouts/framework',
          ],
        ),
        FakeCommand(command: <String>['git', 'remote', 'add', 'mirror', 'mirror']),
        FakeCommand(command: <String>['git', 'fetch', 'mirror']),
        FakeCommand(command: <String>['git', 'checkout', 'master']),
        FakeCommand(command: <String>['git', 'rev-parse', 'HEAD'], stdout: revision),
        FakeCommand(
          command: <String>['git', 'ls-remote', '--heads', remoteName],
          stdout: lsRemoteOutput,
        ),
      ]);
      final Checkouts checkouts = Checkouts(
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final Repository repo = FrameworkRepository(
        checkouts,
        mirrorRemote: const Remote.mirror('mirror'),
      );
      final List<String> branchNames = await repo.listRemoteBranches(remoteName);
      expect(
        branchNames,
        equals(<String>['experiment', 'feature-a', 'feature-b', 'fix_bug_1234', 'stable']),
      );
    });
  });
}
