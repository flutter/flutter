// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('Assemble', () {
    Testbed testbed;
    MockBuildSystem mockBuildSystem;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      mockBuildSystem = MockBuildSystem();
      testbed = Testbed(overrides: <Type, Generator>{
        BuildSystem: ()  => mockBuildSystem,
      });
    });

    test('Can list the output directory relative to project root', () => testbed.run(() async {
      final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
      await commandRunner.run(<String>['assemble', '--flutter-root=.', 'build-dir', '-dBuildMode=debug']);
      final BufferLogger bufferLogger = logger;
      final Environment environment = Environment(
        defines: <String, String>{
          'BuildMode': 'debug'
        }, projectDir: fs.currentDirectory,
        buildDir: fs.directory(fs.path.join('.dart_tool', 'flutter_build')).absolute,
      );

      expect(bufferLogger.statusText.trim(), environment.buildDir.path);
    }));

    test('Can describe a target', () => testbed.run(() async {
      when(mockBuildSystem.describe('foobar', any)).thenReturn(<Map<String, Object>>[
        <String, Object>{'fizz': 'bar'},
      ]);
      final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
      await commandRunner.run(<String>['assemble', '--flutter-root=.', 'describe', 'foobar']);
      final BufferLogger bufferLogger = logger;

      expect(bufferLogger.statusText.trim(), '[{"fizz":"bar"}]');
    }));

    test('Can describe a target\'s inputs', () => testbed.run(() async {
      when(mockBuildSystem.describe('foobar', any)).thenReturn(<Map<String, Object>>[
        <String, Object>{'name': 'foobar', 'inputs': <String>['bar', 'baz']},
      ]);
      final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
      await commandRunner.run(<String>['assemble', '--flutter-root=.', 'inputs', 'foobar']);
      final BufferLogger bufferLogger = logger;

      expect(bufferLogger.statusText.trim(), 'bar\nbaz');
    }));

    test('Can run a build', () => testbed.run(() async {
      when(mockBuildSystem.build('foobar', any, any)).thenAnswer((Invocation invocation) async {
        return BuildResult(true, const <String, ExceptionMeasurement>{}, const <String, PerformanceMeasurement>{});
      });
      final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
      await commandRunner.run(<String>['assemble', 'run', 'foobar']);
      final BufferLogger bufferLogger = logger;

      expect(bufferLogger.statusText.trim(), 'build succeeded');
    }));
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
