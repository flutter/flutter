// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:conductor/next.dart';
import 'package:conductor/proto/conductor_state.pb.dart' as pb;
import 'package:conductor/proto/conductor_state.pbenum.dart' show ReleasePhase;
import 'package:conductor/repository.dart';
import 'package:conductor/state.dart';
import 'package:conductor/stdio.dart';
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
    Stdio stdio;
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
      // This file is never created
      const String stateFile = '/state-file.json';
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

    test('updates state.lastPhase from INITIALIZE to APPLY_ENGINE_CHERRYPICKS on linux', () async {
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
        '--$kYesFlag',
      ]);

      final pb.ConductorState finalState = readStateFromFile(
        fileSystem.file(stateFile),
      );

      expect(finalState.lastPhase, ReleasePhase.APPLY_ENGINE_CHERRYPICKS);
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
