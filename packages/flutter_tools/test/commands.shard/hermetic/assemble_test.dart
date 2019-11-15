// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
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
  Testbed testbed;
  MockBuildSystem mockBuildSystem;
  Cache.disableLocking();

  setUp(() {
    mockBuildSystem = MockBuildSystem();
    testbed = Testbed(overrides: <Type, Generator>{
      BuildSystem: ()  => mockBuildSystem,
      Cache: () => FakeCache(),
    });
  });

  test('Can run a build', () => testbed.run(() async {
    when(mockBuildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);
    final BufferLogger bufferLogger = logger;

    expect(bufferLogger.traceText, contains('build succeeded.'));
  }));

  test('Throws ToolExit if not provided with output', () => testbed.run(() async {
    when(mockBuildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());

    expect(commandRunner.run(<String>['assemble', 'debug_macos_bundle_flutter_assets']), throwsA(isInstanceOf<ToolExit>()));
  }));

  test('Throws ToolExit if called with non-existent rule', () => testbed.run(() async {
    when(mockBuildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());

    expect(commandRunner.run(<String>['assemble', '-o Output', 'undefined']), throwsA(isInstanceOf<ToolExit>()));
  }));

  test('Only writes input and output files when the values change', () => testbed.run(() async {
    when(mockBuildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(
          success: true,
          inputFiles: <File>[fs.file('foo')..createSync()],
          outputFiles: <File>[fs.file('bar')..createSync()],
        );
      });

    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
    await commandRunner.run(<String>['assemble', '-o Output', '--build-outputs=outputs', '--build-inputs=inputs', 'debug_macos_bundle_flutter_assets']);

    final File inputs = fs.file('inputs');
    final File outputs = fs.file('outputs');
    expect(inputs.readAsStringSync(), contains('foo'));
    expect(outputs.readAsStringSync(), contains('bar'));

    final DateTime theDistantPast = DateTime(1991, 8, 23);
    inputs.setLastModifiedSync(theDistantPast);
    outputs.setLastModifiedSync(theDistantPast);
    await commandRunner.run(<String>['assemble', '-o Output', '--build-outputs=outputs', '--build-inputs=inputs', 'debug_macos_bundle_flutter_assets']);

    expect(inputs.lastModifiedSync(), theDistantPast);
    expect(outputs.lastModifiedSync(), theDistantPast);


    when(mockBuildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(
          success: true,
          inputFiles: <File>[fs.file('foo'), fs.file('fizz')..createSync()],
          outputFiles: <File>[fs.file('bar'), fs.file(fs.path.join('.dart_tool', 'fizz2'))..createSync(recursive: true)]);
      });
    await commandRunner.run(<String>['assemble', '-o Output', '--build-outputs=outputs', '--build-inputs=inputs', 'debug_macos_bundle_flutter_assets']);

    expect(inputs.readAsStringSync(), contains('foo'));
    expect(inputs.readAsStringSync(), contains('fizz'));
    expect(inputs.lastModifiedSync(), isNot(theDistantPast));
  }));
}

class MockBuildSystem extends Mock implements BuildSystem {}
