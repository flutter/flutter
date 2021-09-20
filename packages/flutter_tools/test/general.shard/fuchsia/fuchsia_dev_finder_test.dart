// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_dev_finder.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  late FakeFuchsiaArtifacts fuchsiaArtifacts;
  late BufferLogger logger;
  late MemoryFileSystem memoryFileSystem;
  late File deviceFinder;

  setUp(() {
    fuchsiaArtifacts = FakeFuchsiaArtifacts();
    memoryFileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    deviceFinder = memoryFileSystem.file('device-finder');
    fuchsiaArtifacts.devFinder = deviceFinder;
  });

  group('device-finder list', () {
    testWithoutContext('device-finder not found', () {
      final FuchsiaDevFinder fuchsiaDevFinder = FuchsiaDevFinder(
        fuchsiaArtifacts: fuchsiaArtifacts,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );

      expect(() async => fuchsiaDevFinder.list(),
        throwsToolExit(message: 'Fuchsia device-finder tool not found.'));
    });

    testWithoutContext('no devices', () async {
      deviceFinder.createSync();

      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ deviceFinder.path, 'list', '-full' ],
          exitCode: 1,
          stderr: 'list.go:72: no devices found',
        ),
      ]);

      final FuchsiaDevFinder fuchsiaDevFinder = FuchsiaDevFinder(
        fuchsiaArtifacts: fuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaDevFinder.list(), isNull);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('error', () async {
      deviceFinder.createSync();

      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ deviceFinder.path, 'list', '-full' ],
          exitCode: 1,
          stderr: 'unexpected error',
        ),
      ]);

      final FuchsiaDevFinder fuchsiaDevFinder = FuchsiaDevFinder(
        fuchsiaArtifacts: fuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaDevFinder.list(), isNull);
      expect(logger.errorText, contains('unexpected error'));
    });

    testWithoutContext('devices found', () async {
      deviceFinder.createSync();

      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[ deviceFinder.path, 'list', '-full' ],
          exitCode: 0,
          stdout: 'device1\ndevice2',
        ),
      ]);

      final FuchsiaDevFinder fuchsiaDevFinder = FuchsiaDevFinder(
        fuchsiaArtifacts: fuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaDevFinder.list(), <String>['device1', 'device2']);
      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('timeout', () async {
      deviceFinder.createSync();

      final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            deviceFinder.path,
            'list',
            '-full',
            '-timeout',
            '2000ms',
          ],
          exitCode: 0,
          stdout: 'device1',
        ),
      ]);

      final FuchsiaDevFinder fuchsiaDevFinder = FuchsiaDevFinder(
        fuchsiaArtifacts: fuchsiaArtifacts,
        logger: logger,
        processManager: processManager,
      );

      expect(await fuchsiaDevFinder.list(timeout: const Duration(seconds: 2)), <String>['device1']);
    });
  });
}

class FakeFuchsiaArtifacts extends Fake implements FuchsiaArtifacts {
  @override
  File? devFinder;
}
