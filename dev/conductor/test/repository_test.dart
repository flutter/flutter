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
