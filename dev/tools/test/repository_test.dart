// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dev_tools/repository.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';

import './common.dart';

void main() {
  group('repository', () {
    test('canCherryPick returns true if git cherry-pick returns 0', () {
      const LocalPlatform platform = LocalPlatform();
      const String rootDir = '/';
      const String commit = 'abc123';

      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          FrameworkRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'framework'),
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'cherry-pick',
          '--no-commit',
          commit,
        ], exitCode: 0),
        const FakeCommand(command: <String>[
          'git',
          'reset',
          'HEAD',
          '--hard',
        ]),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final Repository repository = FrameworkRepository(checkouts);
      expect(repository.canCherryPick(commit), true);
    });

    test('canCherryPick returns false if git cherry-pick returns non-zero', () {
      const LocalPlatform platform = LocalPlatform();
      const String rootDir = '/';
      const String commit = 'abc123';

      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          FrameworkRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'framework'),
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'cherry-pick',
          '--no-commit',
          commit,
        ], exitCode: 1),
        const FakeCommand(command: <String>[
          'git',
          'diff',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'reset',
          'HEAD',
          '--hard',
        ]),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final Repository repository = FrameworkRepository(checkouts);
      expect(repository.canCherryPick(commit), false);
    });

    test('cherryPick() applies the commit', () {
      const LocalPlatform platform = LocalPlatform();
      const String rootDir = '/';
      const String commit = 'abc123';

      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          FrameworkRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'framework'),
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'cherry-pick',
          commit,
        ]),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final Repository repository = FrameworkRepository(checkouts);
      repository.cherryPick(commit);
      expect(processManager.hasRemainingExpectations, false);
    });
  });
}
