// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_ffx.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  FakeFuchsiaArtifacts fakeFuchsiaArtifacts;
  BufferLogger logger;
  MemoryFileSystem memoryFileSystem;
  File ffx;

  setUp(() {
    fakeFuchsiaArtifacts = FakeFuchsiaArtifacts();
    memoryFileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    ffx = memoryFileSystem.file('ffx');
    fakeFuchsiaArtifacts.ffx = ffx;
  });

  group('ffx list', () {
    testWithoutContext('ffx not found', () {
      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );

      expect(() async => fuchsiaFfx.list(),
          throwsToolExit(message: 'Fuchsia ffx tool not found.'));
    });

    testWithoutContext('no device found', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, 'target', 'list', '--format', 's'],
          exitCode: 0,
          stderr: 'No devices found.',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.list(), isNull);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('error', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, 'target', 'list', '--format', 's'],
          exitCode: 1,
          stderr: 'unexpected error',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.list(), isNull);
      expect(logger.errorText, contains('unexpected error'));
    });

    testWithoutContext('devices found', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, 'target', 'list', '--format', 's'],
          exitCode: 0,
          stdout: 'device1\ndevice2',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.list(), <String>['device1', 'device2']);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('timeout', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, '-T', '2', 'target', 'list', '--format', 's'],
          exitCode: 0,
          stdout: 'device1',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.list(timeout: const Duration(seconds: 2)),
          <String>['device1']);
    });
  });

  group('ffx resolve', () {
    testWithoutContext('ffx not found', () {
      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );

      expect(() async => fuchsiaFfx.list(),
          throwsToolExit(message: 'Fuchsia ffx tool not found.'));
    });

    testWithoutContext('unknown device', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, 'target', 'list', '--format', 'a', 'unknown-device'],
          exitCode: 2,
          stderr: 'No devices found.',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.resolve('unknown-device'), isNull);
      expect(logger.errorText, 'ffx failed: No devices found.\n');
    });

    testWithoutContext('error', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, 'target', 'list', '--format', 'a', 'error-device'],
          exitCode: 1,
          stderr: 'unexpected error',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.resolve('error-device'), isNull);
      expect(logger.errorText, contains('unexpected error'));
    });

    testWithoutContext('valid device', () async {
      ffx.createSync();

      final ProcessManager processManager =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ffx.path, 'target', 'list', '--format', 'a', 'known-device'],
          exitCode: 0,
          stdout: '1234-1234-1234-1234',
        ),
      ]);

      final FuchsiaFfx fuchsiaFfx = FuchsiaFfx(
        fuchsiaArtifacts: fakeFuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaFfx.resolve('known-device'), '1234-1234-1234-1234');
      expect(logger.errorText, isEmpty);
    });
  });
}

class FakeFuchsiaArtifacts extends Fake implements FuchsiaArtifacts {
  @override
  File ffx;
}
