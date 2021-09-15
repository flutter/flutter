// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor/repository.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import './common.dart';
import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';

void main() {
  group('repository', () {
    late FakePlatform platform;
    const String rootDir = '/';

    setUp(() {
      final String pathSeparator = const LocalPlatform().pathSeparator;
      platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(pathSeparator),
        },
        pathSeparator: pathSeparator,
      );
    });

    test('canCherryPick returns true if git cherry-pick returns 0', () {
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

    test('updateDartRevision() updates the DEPS file', () {
      const String previousDartRevision = '171876a4e6cf56ee6da1f97d203926bd7afda7ef';
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager = FakeProcessManager.empty();

      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final EngineRepository repo = EngineRepository(checkouts);
      final File depsFile = fileSystem.file('/DEPS');
      depsFile.writeAsStringSync(generateMockDeps(previousDartRevision));
      repo.updateDartRevision(nextDartRevision, depsFile: depsFile);
      final String updatedDepsFileContent = depsFile.readAsStringSync();
      expect(updatedDepsFileContent, generateMockDeps(nextDartRevision));
    });

    test('updateDartRevision() throws exception on malformed DEPS file', () {
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager = FakeProcessManager.empty();

      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final EngineRepository repo = EngineRepository(checkouts);
      final File depsFile = fileSystem.file('/DEPS');
      depsFile.writeAsStringSync('''
vars = {
}''');
      expect(
        () => repo.updateDartRevision(nextDartRevision, depsFile: depsFile),
        throwsExceptionWith('Unexpected content in the DEPS file at'),
      );
    });

    test('commit() throws if there are no local changes to commit', () {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      const String message = 'This is a commit message.';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          EngineRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'engine'),
        ]),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          'upstream/master',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit1),
        const FakeCommand(command: <String>[
          'git',
          'status',
          '--porcelain',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'commit',
          "--message='$message'",
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit2),
      ]);

      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final EngineRepository repo = EngineRepository(checkouts);
      expect(
        () => repo.commit(message),
        throwsExceptionWith('Tried to commit with message $message but no changes were present'),
      );
    });

    test('commit() passes correct commit message', () {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      const String message = 'This is a commit message.';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          EngineRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'engine'),
        ]),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          'upstream/master',
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit1),
        const FakeCommand(
          command: <String>['git', 'status', '--porcelain'],
          stdout: 'MM path/to/file.txt',
        ),
        const FakeCommand(command: <String>[
          'git',
          'commit',
          "--message='$message'",
        ]),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit2),
      ]);

      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final EngineRepository repo = EngineRepository(checkouts);
      repo.commit(message);
    });

    test('updateEngineRevision() returns false if newCommit is the same as version file', () {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final File engineVersionFile = fileSystem.file('/engine.version')..writeAsStringSync(commit2);
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
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
        ], stdout: commit1),
      ]);

      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final FrameworkRepository repo = FrameworkRepository(checkouts);
      final bool didUpdate = repo.updateEngineRevision(commit2, engineVersionFile: engineVersionFile);
      expect(didUpdate, false);
    });

    test('CiYaml(file) will throw if file does not exist', () {
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final File file = fileSystem.file('/non/existent/file.txt');

      expect(
        () => CiYaml(file),
        throwsExceptionWith('Could not find the .ci.yaml file at /non/existent/file.txt'),
      );
    });

    test('ciYaml.enableBranch() will prepend the given branch to the yaml list of enabled_branches', () {
      const String commit1 = 'abc123';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final File ciYaml = fileSystem.file('/flutter_conductor_checkouts/framework/.ci.yaml');
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
            command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          FrameworkRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'framework'),
        ],
        onRun: () {
          ciYaml.createSync(recursive: true);
          ciYaml.writeAsStringSync('''
# Friendly note

enabled_branches:
  - master
  - dev
  - beta
  - stable
''');
        }),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit1),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final FrameworkRepository framework = FrameworkRepository(checkouts);
      expect(
        framework.ciYaml.enabledBranches,
        <String>['master', 'dev', 'beta', 'stable'],
      );

      framework.ciYaml.enableBranch('foo');
      expect(
        framework.ciYaml.enabledBranches,
        <String>['foo', 'master', 'dev', 'beta', 'stable'],
      );

      expect(
        framework.ciYaml.stringContents,
        '''
# Friendly note

enabled_branches:
  - foo
  - master
  - dev
  - beta
  - stable
'''
      );
    });

    test('ciYaml.enableBranch() will throw if the input branch is already present in the yaml file', () {
      const String commit1 = 'abc123';
      final TestStdio stdio = TestStdio();
      final MemoryFileSystem fileSystem = MemoryFileSystem.test();
      final File ciYaml = fileSystem.file('/flutter_conductor_checkouts/framework/.ci.yaml');
      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
            command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          FrameworkRepository.defaultUpstream,
          fileSystem.path
              .join(rootDir, 'flutter_conductor_checkouts', 'framework'),
        ],
        onRun: () {
          ciYaml.createSync(recursive: true);
          ciYaml.writeAsStringSync('''
enabled_branches:
  - master
  - dev
  - beta
  - stable
''');
        }),
        const FakeCommand(command: <String>[
          'git',
          'rev-parse',
          'HEAD',
        ], stdout: commit1),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final FrameworkRepository framework = FrameworkRepository(checkouts);
      expect(
        () => framework.ciYaml.enableBranch('master'),
        throwsExceptionWith('.ci.yaml already contains the branch master'),
      );
    });
  });
}

String generateMockDeps(String dartRevision) {
  return '''
vars = {
  'chromium_git': 'https://chromium.googlesource.com',
  'swiftshader_git': 'https://swiftshader.googlesource.com',
  'dart_git': 'https://dart.googlesource.com',
  'flutter_git': 'https://flutter.googlesource.com',
  'fuchsia_git': 'https://fuchsia.googlesource.com',
  'github_git': 'https://github.com',
  'skia_git': 'https://skia.googlesource.com',
  'ocmock_git': 'https://github.com/erikdoe/ocmock.git',
  'skia_revision': '4e9d5e2bdf04c58bc0bff57be7171e469e5d7175',

  'dart_revision': '$dartRevision',
  'dart_boringssl_gen_rev': '7322fc15cc065d8d2957fccce6b62a509dc4d641',
}''';
}
