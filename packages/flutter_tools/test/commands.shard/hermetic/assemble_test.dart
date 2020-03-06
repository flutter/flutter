// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  FlutterCommandRunner.initFlutterRoot();
  Cache.disableLocking();
  final Testbed testbed = Testbed(overrides: <Type, Generator>{
    BuildSystem: ()  => MockBuildSystem(),
    Cache: () => FakeCache(),
  });

  testbed.test('Can run a build', () async {
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  });

  testbed.test('Can parse defines whose values contain =', () async {
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        expect((invocation.positionalArguments[1] as Environment).defines, containsPair('FooBar', 'fizz=2'));
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
    await commandRunner.run(<String>['assemble', '-o Output', '-dFooBar=fizz=2', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  });

  testbed.test('Throws ToolExit if not provided with output', () async {
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());

    expect(commandRunner.run(<String>['assemble', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit());
  });

  testbed.test('Throws ToolExit if called with non-existent rule', () async {
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());

    expect(commandRunner.run(<String>['assemble', '-o Output', 'undefined']),
      throwsToolExit());
  });

  testbed.test('Does not log stack traces during build failure', () async {
    final StackTrace testStackTrace = StackTrace.current;
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: false, exceptions: <String, ExceptionMeasurement>{
          'hello': ExceptionMeasurement('hello', 'bar', testStackTrace),
        });
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());

    await expectLater(commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit());
    expect(testLogger.errorText, contains('bar'));
    expect(testLogger.errorText, isNot(contains(testStackTrace.toString())));
  });

  testbed.test('Only writes input and output files when the values change', () async {
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(
          success: true,
          inputFiles: <File>[globals.fs.file('foo')..createSync()],
          outputFiles: <File>[globals.fs.file('bar')..createSync()],
        );
      });

    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand());
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--build-outputs=outputs',
      '--build-inputs=inputs',
      'debug_macos_bundle_flutter_assets',
    ]);

    final File inputs = globals.fs.file('inputs');
    final File outputs = globals.fs.file('outputs');
    expect(inputs.readAsStringSync(), contains('foo'));
    expect(outputs.readAsStringSync(), contains('bar'));

    final DateTime theDistantPast = DateTime(1991, 8, 23);
    inputs.setLastModifiedSync(theDistantPast);
    outputs.setLastModifiedSync(theDistantPast);
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--build-outputs=outputs',
      '--build-inputs=inputs',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(inputs.lastModifiedSync(), theDistantPast);
    expect(outputs.lastModifiedSync(), theDistantPast);

    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(
          success: true,
          inputFiles: <File>[globals.fs.file('foo'), globals.fs.file('fizz')..createSync()],
          outputFiles: <File>[globals.fs.file('bar'), globals.fs.file(globals.fs.path.join('.dart_tool', 'fizz2'))..createSync(recursive: true)]);
      });
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--build-outputs=outputs',
      '--build-inputs=inputs',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(inputs.readAsStringSync(), contains('foo'));
    expect(inputs.readAsStringSync(), contains('fizz'));
    expect(inputs.lastModifiedSync(), isNot(theDistantPast));
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
