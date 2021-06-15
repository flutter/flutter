// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:conductor/next.dart';
import 'package:conductor/proto/conductor_state.pb.dart' as pb;
import 'package:conductor/proto/conductor_state.pbenum.dart' show ReleasePhase;
import 'package:conductor/repository.dart';
import 'package:conductor/state.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import './common.dart';

void main() {
  group('next command', () {
    const String flutterRoot = '/flutter';
    const String checkoutsParentDirectory = '$flutterRoot/dev/tools/';
    final String localPathSeparator = const LocalPlatform().pathSeparator;
    final String localOperatingSystem = const LocalPlatform().pathSeparator;
    MemoryFileSystem fileSystem;
    TestStdio stdio;
    const String stateFile = '/state-file.json';

    setUp(() {
      stdio = TestStdio();
      fileSystem = MemoryFileSystem.test();
    });

    CommandRunner<void> createRunner({
      @required Checkouts checkouts,
    }) {
      final NextCommand command = NextCommand(
        checkouts: checkouts,
      );
      return CommandRunner<void>('codesign-test', '')..addCommand(command);
    }

    test('throws if no state file found', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      expect(
        () async => runner.run(<String>[
          'next',
          '--$kStateOption',
          stateFile,
        ]),
        throwsExceptionWith('No persistent state file found at $stateFile'),
      );
    });

    test('does not prompt user and updates state.lastPhase from INITIALIZE to APPLY_ENGINE_CHERRYPICKS if there are no engine cherrypicks', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        lastPhase: ReleasePhase.INITIALIZE,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(finalState.lastPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
      expect(stdio.error, isEmpty);
    });


    test('updates state.lastPhase from INITIALIZE to APPLY_ENGINE_CHERRYPICKS if user responds yes', () async {
      stdio.stdin.add('y');
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        engine: pb.Repository(
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(
              trunkRevision: 'abc123',
              state: pb.CherrypickState.PENDING,
            ),
          ],
        ),
        lastPhase: ReleasePhase.INITIALIZE,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(stdio.stdout, contains('Did you apply and merge all engine cherrypicks? (y/n) '));
      expect(finalState.lastPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
      expect(stdio.error, isEmpty);
    });

    test('does not update state.lastPhase from APPLY_ENGINE_CHERRYPICKS if user responds no', () async {
      stdio.stdin.add('n');
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        engine: pb.Repository(
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(
              trunkRevision: 'abc123',
              state: pb.CherrypickState.PENDING,
            ),
          ],
        ),
        lastPhase: ReleasePhase.APPLY_ENGINE_CHERRYPICKS,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(stdio.stdout, contains('Has CI passed for the engine PR and binaries been codesigned? (y/n) '));
      expect(finalState.lastPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
      expect(stdio.error.contains('Aborting command.'), true);
    });

    test('updates state.lastPhase from APPLY_ENGINE_CHERRYPICKS to CODESIGN_ENGINE_BINARIES if user responds yes', () async {
      stdio.stdin.add('y');
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        lastPhase: ReleasePhase.APPLY_ENGINE_CHERRYPICKS,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(stdio.stdout, contains('Has CI passed for the engine PR and binaries been codesigned? (y/n) '));
      expect(finalState.lastPhase, ReleasePhase.CODESIGN_ENGINE_BINARIES);
    });

    test('does not prompt user and updates state.lastPhase from CODESIGN_ENGINE_BINARIES to APPLY_FRAMEWORK_CHERRYPICKS if there are no framework cherrypicks', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        lastPhase: ReleasePhase.CODESIGN_ENGINE_BINARIES,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(stdio.stdout, isNot(contains('Did you apply and merge all framework cherrypicks? (y/n) ')));
      expect(finalState.lastPhase, ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS);
      expect(stdio.error, isEmpty);
    });

    test('does not update state.lastPhase from CODESIGN_ENGINE_BINARIES if user responds no', () async {
      stdio.stdin.add('n');
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        framework: pb.Repository(
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(
              trunkRevision: 'abc123',
              state: pb.CherrypickState.PENDING,
            ),
          ],
        ),
        lastPhase: ReleasePhase.CODESIGN_ENGINE_BINARIES,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(stdio.stdout, contains('Did you apply and merge all framework cherrypicks? (y/n) '));
      expect(stdio.error, contains('Aborting command.'));
      expect(finalState.lastPhase, ReleasePhase.CODESIGN_ENGINE_BINARIES);
    });

    test('updates state.lastPhase from CODESIGN_ENGINE_BINARIES to APPLY_FRAMEWORK_CHERRYPICKS if user responds yes', () async {
      stdio.stdin.add('y');
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        framework: pb.Repository(
          cherrypicks: <pb.Cherrypick>[
            pb.Cherrypick(
              trunkRevision: 'abc123',
              state: pb.CherrypickState.PENDING,
            ),
          ],
        ),
        lastPhase: ReleasePhase.CODESIGN_ENGINE_BINARIES,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      await runner.run(<String>[
        'next',
        '--$kStateOption',
        stateFile,
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(finalState.lastPhase, ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS);
      expect(stdio.stdout, contains('Did you apply and merge all framework cherrypicks? (y/n)'));
    });

    test('throws exception if state.lastPhase is VERIFY_RELEASE', () async {
      final FakeProcessManager processManager = FakeProcessManager.list(
        <FakeCommand>[],
      );
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{
          'HOME': <String>['path', 'to', 'home'].join(localPathSeparator),
        },
        operatingSystem: localOperatingSystem,
        pathSeparator: localPathSeparator,
      );
      final pb.ConductorState state = pb.ConductorState(
        lastPhase: ReleasePhase.VERIFY_RELEASE,
      );
      writeStateToFile(
        fileSystem.file(stateFile),
        state,
      );
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: fileSystem.directory(checkoutsParentDirectory)..createSync(recursive: true),
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );
      final CommandRunner<void> runner = createRunner(checkouts: checkouts);
      expect(
        () async => runner.run(<String>[
          'next',
          '--$kStateOption',
          stateFile,
        ]),
        throwsExceptionWith('This release is finished.'),
      );
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
