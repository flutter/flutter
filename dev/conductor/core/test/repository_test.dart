// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/repository.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import './common.dart';

void main() {
  group('repository', () {
    late FakePlatform platform;
    const String rootDir = '/';
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

    test('canCherryPick returns true if git cherry-pick returns 0', () async {
      const String commit = 'abc123';

      processManager.addCommands(<FakeCommand>[
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
          'checkout',
          FrameworkRepository.defaultBranch,
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
      expect(await repository.canCherryPick(commit), true);
    });

    test('canCherryPick returns false if git cherry-pick returns non-zero', () async {
      const String commit = 'abc123';

      processManager.addCommands(<FakeCommand>[
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
          'checkout',
          FrameworkRepository.defaultBranch,
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
      expect(await repository.canCherryPick(commit), false);
    });

    test('cherryPick() applies the commit', () async {
      const String commit = 'abc123';

      processManager.addCommands(<FakeCommand>[
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
          'checkout',
          FrameworkRepository.defaultBranch,
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
      await repository.cherryPick(commit);
      expect(processManager.hasRemainingExpectations, false);
    });

    test('updateDartRevision() updates the DEPS file', () async {
      const String previousDartRevision = '171876a4e6cf56ee6da1f97d203926bd7afda7ef';
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';

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
      await repo.updateDartRevision(nextDartRevision, depsFile: depsFile);
      final String updatedDepsFileContent = depsFile.readAsStringSync();
      expect(updatedDepsFileContent, generateMockDeps(nextDartRevision));
    });

    test('updateDartRevision() throws exception on malformed DEPS file', () {
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';

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
        () async => repo.updateDartRevision(nextDartRevision, depsFile: depsFile),
        throwsExceptionWith('Unexpected content in the DEPS file at'),
      );
    });

    test('commit() throws if there are no local changes to commit', () {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      const String message = 'This is a commit message.';
      processManager.addCommands(<FakeCommand>[
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
          EngineRepository.defaultBranch,
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
        () async => repo.commit(message),
        throwsExceptionWith('Tried to commit with message $message but no changes were present'),
      );
    });

    test('commit() passes correct commit message', () async {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      const String message = 'This is a commit message.';
      processManager.addCommands(<FakeCommand>[
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
          EngineRepository.defaultBranch,
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
      await repo.commit(message);
      expect(processManager.hasRemainingExpectations, false);
    });

    test('updateEngineRevision() returns false if newCommit is the same as version file', () async {
      const String commit1 = 'abc123';
      const String commit2 = 'def456';
      final File engineVersionFile = fileSystem.file('/engine.version')..writeAsStringSync(commit2);
      processManager.addCommands(<FakeCommand>[
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
      final bool didUpdate = await repo.updateEngineRevision(commit2, engineVersionFile: engineVersionFile);
      expect(didUpdate, false);
    });

    test('CiYaml(file) will throw if file does not exist', () {
      final File file = fileSystem.file('/non/existent/file.txt');

      expect(
        () => CiYaml(file),
        throwsExceptionWith('Could not find the .ci.yaml file at /non/existent/file.txt'),
      );
    });

    test('ciYaml.enableBranch() will prepend the given branch to the yaml list of enabled_branches', () async {
      const String commit1 = 'abc123';
      final File ciYaml = fileSystem.file('/flutter_conductor_checkouts/framework/.ci.yaml');
      processManager.addCommands(<FakeCommand>[
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
  - ${FrameworkRepository.defaultBranch}
  - dev
  - beta
  - stable
''');
        }),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          FrameworkRepository.defaultBranch,
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

      final FrameworkRepository framework = FrameworkRepository(checkouts);
      expect(
        (await framework.ciYaml).enabledBranches,
        <String>[FrameworkRepository.defaultBranch, 'dev', 'beta', 'stable'],
      );

      (await framework.ciYaml).enableBranch('foo');
      expect(
        (await framework.ciYaml).enabledBranches,
        <String>['foo', FrameworkRepository.defaultBranch, 'dev', 'beta', 'stable'],
      );

      expect(
        (await framework.ciYaml).stringContents,
        '''
# Friendly note

enabled_branches:
  - foo
  - ${FrameworkRepository.defaultBranch}
  - dev
  - beta
  - stable
'''
      );
    });

    test('ciYaml.enableBranch() will throw if the input branch is already present in the yaml file', () {
      const String commit1 = 'abc123';
      final File ciYaml = fileSystem.file('/flutter_conductor_checkouts/framework/.ci.yaml');
      processManager.addCommands(<FakeCommand>[
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
  - ${FrameworkRepository.defaultBranch}
  - dev
  - beta
  - stable
''');
        }),
        const FakeCommand(command: <String>[
          'git',
          'checkout',
          FrameworkRepository.defaultBranch,
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

      final FrameworkRepository framework = FrameworkRepository(checkouts);
      expect(
        () async => (await framework.ciYaml).enableBranch(FrameworkRepository.defaultBranch),
        throwsExceptionWith('.ci.yaml already contains the branch ${FrameworkRepository.defaultBranch}'),
      );
    });

    test('framework repo set as localUpstream ensures requiredLocalBranches exist locally', () async {
      const String commit = 'deadbeef';
      const String candidateBranch = 'flutter-1.2-candidate.3';
      bool createdCandidateBranch = false;
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          FrameworkRepository.defaultUpstream,
          fileSystem.path.join(rootDir, 'flutter_conductor_checkouts', 'framework'),
        ]),
        FakeCommand(
          command: const <String>['git', 'checkout', candidateBranch, '--'],
          onRun: () => createdCandidateBranch = true,
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', 'stable', '--'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', 'beta', '--'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', 'dev', '--'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', FrameworkRepository.defaultBranch, '--'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', FrameworkRepository.defaultBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: commit,
        ),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final Repository repo = FrameworkRepository(
        checkouts,
        additionalRequiredLocalBranches: <String>[candidateBranch],
        localUpstream: true,
      );
      // call this so that repo.lazilyInitialize() is called.
      await repo.checkoutDirectory;

      expect(processManager.hasRemainingExpectations, false);
      expect(createdCandidateBranch, true);
    });

    test('engine repo set as localUpstream ensures requiredLocalBranches exist locally', () async {
      const String commit = 'deadbeef';
      const String candidateBranch = 'flutter-1.2-candidate.3';
      bool createdCandidateBranch = false;
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'git',
          'clone',
          '--origin',
          'upstream',
          '--',
          EngineRepository.defaultUpstream,
          fileSystem.path.join(rootDir, 'flutter_conductor_checkouts', 'engine'),
        ]),
        FakeCommand(
          command: const <String>['git', 'checkout', candidateBranch, '--'],
          onRun: () => createdCandidateBranch = true,
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', EngineRepository.defaultBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: commit,
        ),
      ]);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(rootDir),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final Repository repo = EngineRepository(
        checkouts,
        additionalRequiredLocalBranches: <String>[candidateBranch],
        localUpstream: true,
      );
      // call this so that repo.lazilyInitialize() is called.
      await repo.checkoutDirectory;

      expect(processManager.hasRemainingExpectations, false);
      expect(createdCandidateBranch, true);
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
