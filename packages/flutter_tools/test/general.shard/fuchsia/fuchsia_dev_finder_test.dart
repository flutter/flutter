// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_dev_finder.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('fuchsia device-finder', () {
    MockFuchsiaArtifacts mockFuchsiaArtifacts;
    MockProcessManager mockProcessManager;
    BufferLogger logger;
    MemoryFileSystem memoryFileSystem;
    File deviceFinder;
    FuchsiaDevFinder fuchsiaDevFinder;

    setUp(() {
      mockFuchsiaArtifacts = MockFuchsiaArtifacts();
      mockProcessManager = MockProcessManager();
      memoryFileSystem = MemoryFileSystem();
      logger = BufferLogger.test();
      deviceFinder = memoryFileSystem.file('device-finder');

      when(mockFuchsiaArtifacts.devFinder).thenReturn(deviceFinder);

      fuchsiaDevFinder = FuchsiaDevFinder(
        fuchsiaArtifacts: mockFuchsiaArtifacts,
        logger: logger,
        processManager: mockProcessManager
      );
    });

    group('list', () {
      testWithoutContext('device-finder not found', () {
        expect(() async => await fuchsiaDevFinder.list(),
          throwsToolExit(message: 'Fuchsia device-finder tool not found.'));
      });

      testWithoutContext('no devices', () async {
        deviceFinder.createSync();

        when(mockProcessManager.run(
          <String>[
            deviceFinder.path,
            'list',
            '-full',
          ],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        )).thenAnswer(
            (_) => Future<ProcessResult>.value(ProcessResult(1, 1, '', 'list.go:72: no devices found'))
        );

        expect(await fuchsiaDevFinder.list(), isNull);
        expect(logger.errorText, isEmpty);
      });

      testWithoutContext('error', () async {
        deviceFinder.createSync();

        when(mockProcessManager.run(
          <String>[
            deviceFinder.path,
            'list',
            '-full',
          ],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        )).thenAnswer(
            (_) => Future<ProcessResult>.value(ProcessResult(1, 1, '', 'unexpected error'))
        );

        expect(await fuchsiaDevFinder.list(), isNull);
        expect(logger.errorText, contains('unexpected error'));
      });

      testWithoutContext('devices found', () async {
        deviceFinder.createSync();

        when(mockProcessManager.run(
          <String>[
            deviceFinder.path,
            'list',
            '-full',
          ],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        )).thenAnswer(
            (_) => Future<ProcessResult>.value(ProcessResult(1, 0, 'device1\ndevice2', ''))
        );

        expect(await fuchsiaDevFinder.list(), <String>['device1', 'device2']);
        expect(logger.errorText, isEmpty);
      });

      testWithoutContext('timeout', () async {
        deviceFinder.createSync();

        when(mockProcessManager.run(
          <String>[
            deviceFinder.path,
            'list',
            '-full',
            '-timeout',
            '2000ms',
          ],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
        )).thenAnswer(
            (_) => Future<ProcessResult>.value(ProcessResult(1, 0, 'device1', ''))
        );

        expect(await fuchsiaDevFinder.list(timeout: const Duration(seconds: 2)), <String>['device1']);
      });
    });
  });
}

class MockFuchsiaArtifacts extends Mock implements FuchsiaArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}