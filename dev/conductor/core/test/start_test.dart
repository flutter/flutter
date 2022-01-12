// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'package:args/command_runner.dart';
import 'package:conductor_core/src/globals.dart';
import 'package:conductor_core/src/proto/conductor_state.pb.dart' as pb;
import 'package:conductor_core/src/proto/conductor_state.pbenum.dart' show ReleasePhase;
import 'package:conductor_core/src/repository.dart';
import 'package:conductor_core/src/start.dart';
import 'package:conductor_core/src/state.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import './common.dart';

void main() {
  group('start command', () {
    const String flutterRoot = '/flutter';
    const String checkoutsParentDirectory = '$flutterRoot/dev/tools/';
    const String frameworkMirror = 'https://github.com/user/flutter.git';
    const String engineMirror = 'https://github.com/user/engine.git';
    const String candidateBranch = 'flutter-1.2-candidate.3';
    const String releaseChannel = 'stable';
    const String revision = 'abcd1234';
    const String conductorVersion = 'deadbeef';
    late Checkouts checkouts;
    late MemoryFileSystem fileSystem;
    late FakePlatform platform;
    late TestStdio stdio;
    late FakeProcessManager processManager;

    setUp(() {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
    });

    CommandRunner<void> createRunner({
      Map<String, String>? environment,
      String? operatingSystem,
      List<FakeCommand>? commands,
    }) {
      operatingSystem ??= const LocalPlatform().operatingSystem;
      final String pathSeparator = operatingSystem == 'windows' ? r'\' : '/';
      environment ??= <String, String>{
        'HOME': '/path/to/user/home',
      };
      final Directory homeDir = fileSystem.directory(
        environment['HOME'],
      );
      // Tool assumes this exists
      homeDir.createSync(recursive: true);
      platform = FakePlatform(
        environment: environment,
        operatingSystem: operatingSystem,
        pathSeparator: pathSeparator,
      );
      processManager = FakeProcessManager.list(commands ?? <FakeCommand>[]);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final StartCommand command = StartCommand(
        checkouts: checkouts,
        conductorVersion: conductorVersion,
      );
      return CommandRunner<void>('codesign-test', '')..addCommand(command);
    }

    test('throws exception if run from Windows', () async {
      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'rev-parse', 'HEAD'],
            stdout: revision,
          ),
        ],
        operatingSystem: 'windows',
      );
      await expectLater(
        () async => runner.run(<String>[
          'start',
          '--$kFrameworkMirrorOption',
          frameworkMirror,
          '--$kEngineMirrorOption',
          engineMirror,
          '--$kCandidateOption',
          candidateBranch,
          '--$kReleaseOption',
          'dev',
          '--$kStateOption',
          '/path/to/statefile.json',
          '--$kIncrementOption',
          'y',
        ]),
        throwsExceptionWith(
          'Error! This tool is only supported on macOS and Linux',
        ),
      );
    });

    test('throws if --$kFrameworkMirrorOption not provided', () async {
      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          const FakeCommand(
            command: <String>['git', 'rev-parse', 'HEAD'],
            stdout: revision,
          ),
        ],
      );

      await expectLater(
        () async => runner.run(<String>['start']),
        throwsExceptionWith(
          'Expected either the CLI arg --$kFrameworkMirrorOption or the environment variable FRAMEWORK_MIRROR to be provided',
        ),
      );
    });

    test('does not fail if version wrong but --force provided', () async {
      const String revision2 = 'def789';
      const String revision3 = '123abc';
      const String previousDartRevision = '171876a4e6cf56ee6da1f97d203926bd7afda7ef';
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';
      const String previousVersion = '1.2.0-1.0.pre';
      // This is what this release will be
      const String nextVersion = '1.2.0-1.1.pre';
      const String incrementLevel = 'n';

      final Directory engine = fileSystem
          .directory(checkoutsParentDirectory)
          .childDirectory('flutter_conductor_checkouts')
          .childDirectory('engine');

      final File depsFile = engine.childFile('DEPS');

      final List<FakeCommand> engineCommands = <FakeCommand>[
        FakeCommand(
            command: <String>[
              'git',
              'clone',
              '--origin',
              'upstream',
              '--',
              EngineRepository.defaultUpstream,
              engine.path,
            ],
            onRun: () {
              // Create the DEPS file which the tool will update
              engine.createSync(recursive: true);
              depsFile.writeAsStringSync(generateMockDeps(previousDartRevision));
            }),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', engineMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'status', '--porcelain'],
          stdout: 'MM path/to/DEPS',
        ),
        const FakeCommand(
          command: <String>['git', 'add', '--all'],
        ),
        const FakeCommand(
          command: <String>['git', 'commit', "--message='Update Dart SDK to $nextDartRevision'"],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
      ];

      final List<FakeCommand> frameworkCommands = <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            fileSystem.path.join(
              checkoutsParentDirectory,
              'flutter_conductor_checkouts',
              'framework',
            ),
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', frameworkMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'describe',
            '--match',
            '*.*.*',
            '--tags',
            'refs/remotes/upstream/$candidateBranch',
          ],
          stdout: '$previousVersion-42-gabc123',
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
      ];

      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          ...engineCommands,
          ...frameworkCommands,
        ],
      );

      final String stateFilePath = fileSystem.path.join(
        platform.environment['HOME']!,
        kStateFileName,
      );

      await runner.run(<String>[
        'start',
        '--$kFrameworkMirrorOption',
        frameworkMirror,
        '--$kEngineMirrorOption',
        engineMirror,
        '--$kCandidateOption',
        candidateBranch,
        '--$kReleaseOption',
        releaseChannel,
        '--$kStateOption',
        stateFilePath,
        '--$kDartRevisionOption',
        nextDartRevision,
        '--$kIncrementOption',
        incrementLevel,
        '--$kForceFlag',
      ]);

      final File stateFile = fileSystem.file(stateFilePath);

      final pb.ConductorState state = pb.ConductorState();
      state.mergeFromProto3Json(
        jsonDecode(stateFile.readAsStringSync()),
      );

      expect(processManager.hasRemainingExpectations, false);
      expect(state.isInitialized(), true);
      expect(state.releaseChannel, releaseChannel);
      expect(state.releaseVersion, nextVersion);
      expect(state.engine.candidateBranch, candidateBranch);
      expect(state.engine.startingGitHead, revision2);
      expect(state.engine.dartRevision, nextDartRevision);
      expect(state.engine.upstream.url, 'git@github.com:flutter/engine.git');
      expect(state.framework.candidateBranch, candidateBranch);
      expect(state.framework.startingGitHead, revision3);
      expect(state.framework.upstream.url, 'git@github.com:flutter/flutter.git');
      expect(state.currentPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
      expect(state.conductorVersion, conductorVersion);
      expect(state.incrementLevel, incrementLevel);
    });

    test('creates state file if provided correct inputs', () async {
      stdio.stdin.add('y'); // accept prompt from ensureBranchPointTagged()
      const String revision2 = 'def789';
      const String revision3 = '123abc';
      const String branchPointRevision = 'deadbeef';
      const String previousDartRevision = '171876a4e6cf56ee6da1f97d203926bd7afda7ef';
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';
      const String previousVersion = '1.2.0-1.0.pre';
      // This is a git tag applied to the branch point, not an actual release
      const String branchPointTag = '1.2.0-3.0.pre';
      // This is what this release will be
      const String nextVersion = '1.2.0-3.1.pre';
      const String incrementLevel = 'm';

      final Directory engine = fileSystem
          .directory(checkoutsParentDirectory)
          .childDirectory('flutter_conductor_checkouts')
          .childDirectory('engine');

      final File depsFile = engine.childFile('DEPS');

      final List<FakeCommand> engineCommands = <FakeCommand>[
        FakeCommand(
            command: <String>[
              'git',
              'clone',
              '--origin',
              'upstream',
              '--',
              EngineRepository.defaultUpstream,
              engine.path,
            ],
            onRun: () {
              // Create the DEPS file which the tool will update
              engine.createSync(recursive: true);
              depsFile.writeAsStringSync(generateMockDeps(previousDartRevision));
            }),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', engineMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'status', '--porcelain'],
          stdout: 'MM path/to/DEPS',
        ),
        const FakeCommand(
          command: <String>['git', 'add', '--all'],
        ),
        const FakeCommand(
          command: <String>['git', 'commit', "--message='Update Dart SDK to $nextDartRevision'"],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
      ];

      final List<FakeCommand> frameworkCommands = <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            fileSystem.path.join(
              checkoutsParentDirectory,
              'flutter_conductor_checkouts',
              'framework',
            ),
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', frameworkMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'describe',
            '--match',
            '*.*.*',
            '--tags',
            'refs/remotes/upstream/$candidateBranch',
          ],
          stdout: '$previousVersion-42-gabc123',
        ),
        const FakeCommand(
          command: <String>['git', 'merge-base', candidateBranch, 'master'],
          stdout: branchPointRevision,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', branchPointTag, branchPointRevision],
        ),
        const FakeCommand(
          command: <String>['git', 'push', FrameworkRepository.defaultUpstream, branchPointTag],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
      ];

      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          ...engineCommands,
          ...frameworkCommands,
        ],
      );

      final String stateFilePath = fileSystem.path.join(
        platform.environment['HOME']!,
        kStateFileName,
      );

      await runner.run(<String>[
        'start',
        '--$kFrameworkMirrorOption',
        frameworkMirror,
        '--$kEngineMirrorOption',
        engineMirror,
        '--$kCandidateOption',
        candidateBranch,
        '--$kReleaseOption',
        releaseChannel,
        '--$kStateOption',
        stateFilePath,
        '--$kDartRevisionOption',
        nextDartRevision,
        '--$kIncrementOption',
        incrementLevel,
      ]);

      final File stateFile = fileSystem.file(stateFilePath);

      final pb.ConductorState state = pb.ConductorState();
      state.mergeFromProto3Json(
        jsonDecode(stateFile.readAsStringSync()),
      );

      expect(processManager.hasRemainingExpectations, false);
      expect(state.isInitialized(), true);
      expect(state.releaseChannel, releaseChannel);
      expect(state.releaseVersion, nextVersion);
      expect(state.engine.candidateBranch, candidateBranch);
      expect(state.engine.startingGitHead, revision2);
      expect(state.engine.dartRevision, nextDartRevision);
      expect(state.engine.upstream.url, 'git@github.com:flutter/engine.git');
      expect(state.framework.candidateBranch, candidateBranch);
      expect(state.framework.startingGitHead, revision3);
      expect(state.framework.upstream.url, 'git@github.com:flutter/flutter.git');
      expect(state.currentPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
      expect(state.conductorVersion, conductorVersion);
      expect(state.incrementLevel, incrementLevel);
      expect(stdio.stdout, contains('Applying the tag $branchPointTag at the branch point $branchPointRevision'));
      expect(stdio.stdout, contains('The actual release will be version $nextVersion'));
      expect(branchPointTag != nextVersion, true);
    });

    test('can convert from dev style version to stable version', () async {
      const String revision2 = 'def789';
      const String revision3 = '123abc';
      const String previousDartRevision = '171876a4e6cf56ee6da1f97d203926bd7afda7ef';
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';
      const String previousVersion = '1.2.0-3.0.pre';
      const String nextVersion = '1.2.0';
      const String incrementLevel = 'z';

      final Directory engine = fileSystem
          .directory(checkoutsParentDirectory)
          .childDirectory('flutter_conductor_checkouts')
          .childDirectory('engine');

      final File depsFile = engine.childFile('DEPS');

      final List<FakeCommand> engineCommands = <FakeCommand>[
        FakeCommand(
            command: <String>[
              'git',
              'clone',
              '--origin',
              'upstream',
              '--',
              EngineRepository.defaultUpstream,
              engine.path,
            ],
            onRun: () {
              // Create the DEPS file which the tool will update
              engine.createSync(recursive: true);
              depsFile.writeAsStringSync(generateMockDeps(previousDartRevision));
            }),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', engineMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'status', '--porcelain'],
          stdout: 'MM path/to/DEPS',
        ),
        const FakeCommand(
          command: <String>['git', 'add', '--all'],
        ),
        const FakeCommand(
          command: <String>['git', 'commit', "--message='Update Dart SDK to $nextDartRevision'"],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
      ];

      final List<FakeCommand> frameworkCommands = <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            fileSystem.path.join(
              checkoutsParentDirectory,
              'flutter_conductor_checkouts',
              'framework',
            ),
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', frameworkMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'describe',
            '--match',
            '*.*.*',
            '--tags',
            'refs/remotes/upstream/$candidateBranch',
          ],
          stdout: '$previousVersion-42-gabc123',
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
      ];

      final CommandRunner<void> runner = createRunner(
        commands: <FakeCommand>[
          ...engineCommands,
          ...frameworkCommands,
        ],
      );

      final String stateFilePath = fileSystem.path.join(
        platform.environment['HOME']!,
        kStateFileName,
      );

      await runner.run(<String>[
        'start',
        '--$kFrameworkMirrorOption',
        frameworkMirror,
        '--$kEngineMirrorOption',
        engineMirror,
        '--$kCandidateOption',
        candidateBranch,
        '--$kReleaseOption',
        releaseChannel,
        '--$kStateOption',
        stateFilePath,
        '--$kDartRevisionOption',
        nextDartRevision,
        '--$kIncrementOption',
        incrementLevel,
      ]);

      final File stateFile = fileSystem.file(stateFilePath);

      final pb.ConductorState state = pb.ConductorState();
      state.mergeFromProto3Json(
        jsonDecode(stateFile.readAsStringSync()),
      );

      expect(processManager.hasRemainingExpectations, false);
      expect(state.isInitialized(), true);
      expect(state.releaseChannel, releaseChannel);
      expect(state.releaseVersion, nextVersion);
      expect(state.engine.candidateBranch, candidateBranch);
      expect(state.engine.startingGitHead, revision2);
      expect(state.engine.dartRevision, nextDartRevision);
      expect(state.framework.candidateBranch, candidateBranch);
      expect(state.framework.startingGitHead, revision3);
      expect(state.currentPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
      expect(state.conductorVersion, conductorVersion);
      expect(state.incrementLevel, incrementLevel);
    });

    test('StartContext gets engine and framework checkout directories after run', () async {
      stdio.stdin.add('y');
      const String revision2 = 'def789';
      const String revision3 = '123abc';
      const String branchPointRevision = 'deadbeef';
      const String previousDartRevision = '171876a4e6cf56ee6da1f97d203926bd7afda7ef';
      const String nextDartRevision = 'f6c91128be6b77aef8351e1e3a9d07c85bc2e46e';
      const String previousVersion = '1.2.0-1.0.pre';
      // This is a git tag applied to the branch point, not an actual release
      const String branchPointTag = '1.2.0-3.0.pre';
      // This is what this release will be
      const String incrementLevel = 'm';

      final Directory engine = fileSystem
          .directory(checkoutsParentDirectory)
          .childDirectory('flutter_conductor_checkouts')
          .childDirectory('engine');

      final Directory framework = fileSystem
          .directory(checkoutsParentDirectory)
          .childDirectory('flutter_conductor_checkouts')
          .childDirectory('framework');

      final File depsFile = engine.childFile('DEPS');

      final List<FakeCommand> engineCommands = <FakeCommand>[
        FakeCommand(
            command: <String>[
              'git',
              'clone',
              '--origin',
              'upstream',
              '--',
              EngineRepository.defaultUpstream,
              engine.path,
            ],
            onRun: () {
              // Create the DEPS file which the tool will update
              engine.createSync(recursive: true);
              depsFile.writeAsStringSync(generateMockDeps(previousDartRevision));
            }),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', engineMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'status', '--porcelain'],
          stdout: 'MM path/to/DEPS',
        ),
        const FakeCommand(
          command: <String>['git', 'add', '--all'],
        ),
        const FakeCommand(
          command: <String>['git', 'commit', "--message='Update Dart SDK to $nextDartRevision'"],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision2,
        ),
      ];

      final List<FakeCommand> frameworkCommands = <FakeCommand>[
        FakeCommand(
          command: <String>[
            'git',
            'clone',
            '--origin',
            'upstream',
            '--',
            FrameworkRepository.defaultUpstream,
            framework.path,
          ],
        ),
        const FakeCommand(
          command: <String>['git', 'remote', 'add', 'mirror', frameworkMirror],
        ),
        const FakeCommand(
          command: <String>['git', 'fetch', 'mirror'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', candidateBranch],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'checkout',
            '-b',
            'cherrypicks-$candidateBranch',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'git',
            'describe',
            '--match',
            '*.*.*',
            '--tags',
            'refs/remotes/upstream/$candidateBranch',
          ],
          stdout: '$previousVersion-42-gabc123',
        ),
        const FakeCommand(
          command: <String>['git', 'merge-base', candidateBranch, 'master'],
          stdout: branchPointRevision,
        ),
        const FakeCommand(
          command: <String>['git', 'tag', branchPointTag, branchPointRevision],
        ),
        const FakeCommand(
          command: <String>['git', 'push', FrameworkRepository.defaultUpstream, branchPointTag],
        ),
        const FakeCommand(
          command: <String>['git', 'rev-parse', 'HEAD'],
          stdout: revision3,
        ),
      ];

      final String operatingSystem = const LocalPlatform().operatingSystem;
      final Map<String, String> environment = <String, String>{
        'HOME': '/path/to/user/home',
      };
      final Directory homeDir = fileSystem.directory(
        environment['HOME'],
      );
      // Tool assumes this exists
      homeDir.createSync(recursive: true);
      platform = FakePlatform(
        environment: environment,
        operatingSystem: operatingSystem,
      );

      final String stateFilePath = fileSystem.path.join(
        platform.environment['HOME']!,
        kStateFileName,
      );
      final File stateFile = fileSystem.file(stateFilePath);

      processManager = FakeProcessManager.list(<FakeCommand>[
        ...engineCommands,
        ...frameworkCommands,
      ]);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final StartContext startContext = StartContext(
          candidateBranch: candidateBranch,
          checkouts: checkouts,
          dartRevision: nextDartRevision,
          engineCherrypickRevisions: <String>[],
          engineMirror: engineMirror,
          engineUpstream: EngineRepository.defaultUpstream,
          frameworkCherrypickRevisions: <String>[],
          frameworkMirror: frameworkMirror,
          frameworkUpstream: FrameworkRepository.defaultUpstream,
          releaseChannel: releaseChannel,
          incrementLetter: incrementLevel,
          processManager: processManager,
          conductorVersion: conductorVersion,
          stateFile: stateFile);

      await startContext.run();

      expect((await startContext.engine.checkoutDirectory).path, equals(engine.path));
      expect((await startContext.framework.checkoutDirectory).path, equals(framework.path));
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
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
