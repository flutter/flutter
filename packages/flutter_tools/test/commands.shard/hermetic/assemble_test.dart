// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';
void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  testUsingContext('flutter assemble can run a build', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    final BufferLogger logger = BufferLogger.test();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem, logger: logger),
    );
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  });

  testUsingContext('flutter assemble can parse defines whose values contain =', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    final BufferLogger logger = BufferLogger.test();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        expect((invocation.positionalArguments[1] as Environment).defines, containsPair('FooBar', 'fizz=2'));
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem, logger: logger),
    );
    await commandRunner.run(<String>['assemble', '-o Output', '-dFooBar=fizz=2', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  });

  testUsingContext('flutter assemble can parse inputs', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    final BufferLogger logger = BufferLogger.test();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        expect((invocation.positionalArguments[1] as Environment).inputs, containsPair('Foo', 'Bar.txt'));
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem, logger: logger),
    );
    await commandRunner.run(<String>['assemble', '-o Output', '-iFoo=Bar.txt', 'debug_macos_bundle_flutter_assets']);

    expect(logger.traceText, contains('build succeeded.'));
  });

  testUsingContext('flutter assemble throws ToolExit if not provided with output', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem),
    );

    expect(commandRunner.run(<String>['assemble', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit());
  });

  testUsingContext('flutter assemble throws ToolExit if called with non-existent rule', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem),
    );

    expect(commandRunner.run(<String>['assemble', '-o Output', 'undefined']),
      throwsToolExit());
  });

  testUsingContext('flutter assemble does not log stack traces during build failure', () async {
    final StackTrace testStackTrace = StackTrace.current;
    final BuildSystem buildSystem = MockBuildSystem();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: false, exceptions: <String, ExceptionMeasurement>{
          'hello': ExceptionMeasurement('hello', 'bar', testStackTrace),
        });
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem),
    );

    await expectLater(commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit());
    expect(testLogger.errorText, isNot(contains('bar')));
    expect(testLogger.errorText, isNot(contains(testStackTrace.toString())));
  });

  testUsingContext('flutter assemble outputs JSON performance data to provided file', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    final FileSystem fileSystem = MemoryFileSystem.test();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(success: true, performance: <String, PerformanceMeasurement>{
          'hello': PerformanceMeasurement(
            target: 'hello',
            analyicsName: 'bar',
            elapsedMilliseconds: 123,
            skipped: false,
            succeeded: true,
          ),
        });
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem, fileSystem: fileSystem),
    );

    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--performance-measurement-file=out.json',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(fileSystem.file('out.json'), exists);
    expect(
      json.decode(fileSystem.file('out.json').readAsStringSync()),
      containsPair('targets', contains(
        containsPair('name', 'bar'),
      )),
    );
  });

  testUsingContext('flutter assemble does not inject engine revision with local-engine', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    final Artifacts artifacts = MockLocalEngineArtifacts();
    Environment environment;
    when(artifacts.isLocalEngine).thenReturn(true);
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        environment = invocation.positionalArguments[1] as Environment;
        return BuildResult(success: true);
      });
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem, artifacts: artifacts),
    );
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);

    expect(environment.engineVersion, isNull);
  });

  testUsingContext('flutter assemble only writes input and output files when the values change', () async {
    final BuildSystem buildSystem = MockBuildSystem();
    final FileSystem fileSystem = MemoryFileSystem.test();
    when(buildSystem.build(any, any, buildSystemConfig: anyNamed('buildSystemConfig')))
      .thenAnswer((Invocation invocation) async {
        return BuildResult(
          success: true,
          inputFiles: <File>[fileSystem.file('foo')..createSync()],
          outputFiles: <File>[fileSystem.file('bar')..createSync()],
        );
      });

    final CommandRunner<void> commandRunner = createTestCommandRunner(
      setUpAssembleCommand(buildSystem, fileSystem: fileSystem),
    );
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--build-outputs=outputs',
      '--build-inputs=inputs',
      'debug_macos_bundle_flutter_assets',
    ]);

    final File inputs = fileSystem.file('inputs');
    final File outputs = fileSystem.file('outputs');
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
          inputFiles: <File>[
            fileSystem.file('foo'),
            fileSystem.file('fizz')..createSync(),
          ],
          outputFiles: <File>[
            fileSystem.file('bar'),
            fileSystem.file('.dart_tool/fizz2')..createSync(recursive: true),
          ]);
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

  testUsingContext('writePerformanceData outputs performance data in JSON form', () {
    final List<PerformanceMeasurement> performanceMeasurement = <PerformanceMeasurement>[
      PerformanceMeasurement(
        analyicsName: 'foo',
        target: 'hidden',
        skipped: false,
        succeeded: true,
        elapsedMilliseconds: 123,
      )
    ];
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File outFile = fileSystem.currentDirectory
      .childDirectory('foo')
      .childFile('out.json');

    writePerformanceData(performanceMeasurement, outFile);

    expect(outFile, exists);
    expect(json.decode(outFile.readAsStringSync()), <String, Object>{
      'targets': <Object>[
        <String, Object>{
          'name': 'foo',
          'skipped': false,
          'succeeded': true,
          'elapsedMilliseconds': 123,
        },
      ],
    });
  });
}

AssembleCommand setUpAssembleCommand(BuildSystem buildSystem, {
  Logger logger,
  FileSystem fileSystem,
  Artifacts artifacts,
}) {
  return AssembleCommand(
    artifacts: artifacts ?? Artifacts.test(),
    cache: FakeCache(),
    flutterVersion: FakeFlutterVerision(),
    logger: logger ?? BufferLogger.test(),
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    processManager: FakeProcessManager.any(),
    buildSystem: buildSystem,
  );
}

class FakeFlutterVerision extends Fake implements FlutterVersion {}
class MockBuildSystem extends Mock implements BuildSystem {}
class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
