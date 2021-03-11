// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/assemble.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/testbed.dart';

void main() {
  Cache.disableLocking();
  Cache.flutterRoot = '';
  final StackTrace stackTrace = StackTrace.current;

  testUsingContext('flutter assemble can run a build', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    ));
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble can parse defines whose values contain =', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
        expect(environment.defines, containsPair('FooBar', 'fizz=2'));
      })
    ));
    await commandRunner.run(<String>['assemble', '-o Output', '-dFooBar=fizz=2', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble can parse inputs', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
        expect(environment.inputs, containsPair('Foo', 'Bar.txt'));
      })
    ));
    await commandRunner.run(<String>['assemble', '-o Output', '-iFoo=Bar.txt', 'debug_macos_bundle_flutter_assets']);

    expect(testLogger.traceText, contains('build succeeded.'));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble throws ToolExit if not provided with output', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    ));

    expect(commandRunner.run(<String>['assemble', 'debug_macos_bundle_flutter_assets']), throwsToolExit());
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble throws ToolExit if called with non-existent rule', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    ));

    expect(commandRunner.run(<String>['assemble', '-o Output', 'undefined']),
      throwsToolExit());
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble does not log stack traces during build failure', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: false, exceptions: <String, ExceptionMeasurement>{
        'hello': ExceptionMeasurement('hello', 'bar', stackTrace),
      }))
    ));

    await expectLater(commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit());
    expect(testLogger.errorText, isNot(contains('bar')));
    expect(testLogger.errorText, isNot(contains(stackTrace.toString())));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble outputs JSON performance data to provided file', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(
        BuildResult(success: true, performance: <String, PerformanceMeasurement>{
          'hello': PerformanceMeasurement(
            target: 'hello',
            analyticsName: 'bar',
            elapsedMilliseconds: 123,
            skipped: false,
            succeeded: true,
          ),
        }),
      ),
    ));

    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--performance-measurement-file=out.json',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(globals.fs.file('out.json'), exists);
    expect(
      json.decode(globals.fs.file('out.json').readAsStringSync()),
      containsPair('targets', contains(
        containsPair('name', 'bar'),
      )),
    );
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble does not inject engine revision with local-engine', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
        expect(environment.engineVersion, isNull);
      })
    ));
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);
  }, overrides: <Type, Generator>{
    Artifacts: () => Artifacts.test(localEngine: 'out/host_release'),
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flutter assemble only writes input and output files when the values change', () async {
    final BuildSystem buildSystem = TestBuildSystem.list(<BuildResult>[
      BuildResult(
        success: true,
        inputFiles: <File>[globals.fs.file('foo')..createSync()],
        outputFiles: <File>[globals.fs.file('bar')..createSync()],
      ),
      BuildResult(
        success: true,
        inputFiles: <File>[globals.fs.file('foo')..createSync()],
        outputFiles: <File>[globals.fs.file('bar')..createSync()],
      ),
      BuildResult(
        success: true,
        inputFiles: <File>[globals.fs.file('foo'), globals.fs.file('fizz')..createSync()],
        outputFiles: <File>[globals.fs.file('bar'), globals.fs.file(globals.fs.path.join('.dart_tool', 'fizz2'))..createSync(recursive: true)],
      ),
    ]);
    final CommandRunner<void> commandRunner = createTestCommandRunner(AssembleCommand(buildSystem: buildSystem));
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
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testWithoutContext('writePerformanceData outputs performance data in JSON form', () {
    final List<PerformanceMeasurement> performanceMeasurement = <PerformanceMeasurement>[
      PerformanceMeasurement(
        analyticsName: 'foo',
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
