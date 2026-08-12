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
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  Cache.disableLocking();
  Cache.flutterRoot = '';
  final StackTrace stackTrace = StackTrace.current;
  late FakeAnalytics fakeAnalytics;
  late MemoryFileSystem fileSystem;
  late BufferLogger logger;
  late Artifacts artifacts;
  late Cache cache;
  late FakeToolContext toolContext;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml').createSync();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    cache = Cache.test(processManager: FakeProcessManager.any());
    toolContext = FakeToolContext(
      artifacts: artifacts,
      cache: cache,
      fs: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );
  });

  testWithoutContext('flutter assemble can run a build', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        toolContext: toolContext,
      ),
    );
    await commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']);

    expect(logger.traceText, contains('build succeeded.'));
  });

  testWithoutContext('flutter assemble can parse defines whose values contain =', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          expect(environment.defines, containsPair('FooBar', 'fizz=2'));
        }),
        toolContext: toolContext,
      ),
    );
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '-dFooBar=fizz=2',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(logger.traceText, contains('build succeeded.'));
  });

  testWithoutContext('flutter assemble can parse empty defines', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          expect(environment.defines, const {'DeferredComponents': 'false'});
        }),
        toolContext: toolContext,
      ),
    );
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '--DartDefines=',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(logger.traceText, contains('build succeeded.'));
  });

  testWithoutContext('flutter assemble can parse inputs', () async {
    final command = AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.inputs, containsPair('Foo', 'Bar.txt'));
      }),
      toolContext: toolContext,
    );
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '-iFoo=Bar.txt',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(logger.traceText, contains('build succeeded.'));
    expect(await command.requiredArtifacts, isEmpty);
  });

  testWithoutContext('flutter assemble sets required artifacts from target platform', () async {
    final command = AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '-dTargetPlatform=darwin',
      '-dDarwinArchs=x86_64',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(await command.requiredArtifacts, <DevelopmentArtifact>{DevelopmentArtifact.macOS});
  });

  testWithoutContext('flutter assemble sends assemble-deferred-components', () async {
    final command = AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
      analytics: fakeAnalytics,
    );
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '-dTargetPlatform=android',
      '-dBuildMode=release',
      'android_aot_deferred_components_bundle_release_android-arm64',
    ]);
    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.flutterBuildInfo(
          label: 'assemble-deferred-components',
          buildType: 'android',
          settings: 'android_aot_deferred_components_bundle_release_android-arm64',
        ),
      ),
    );
  });

  testWithoutContext('flutter assemble sends usage values correctly with platform', () async {
    final command = AssembleCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
      analytics: fakeAnalytics,
    );
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    await commandRunner.run(<String>[
      'assemble',
      '-o Output',
      '-dTargetPlatform=darwin',
      '-dDarwinArchs=x86_64',
      'debug_macos_bundle_flutter_assets',
    ]);

    expect(
      fakeAnalytics.sentEvents,
      contains(
        Event.commandUsageValues(
          workflow: 'assemble',
          commandHasTerminal: false,
          buildBundleTargetPlatform: 'darwin',
          buildBundleIsModule: false,
        ),
      ),
    );
  });

  testWithoutContext('flutter assemble throws ToolExit if not provided with output', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        toolContext: toolContext,
      ),
    );

    expect(
      commandRunner.run(<String>['assemble', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit(),
    );
  });

  testWithoutContext(
    'flutter assemble can run a build if dart-defines are base64 encoded',
    () async {
      final CommandRunner<void> commandRunner = createTestCommandRunner(
        AssembleCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          toolContext: toolContext,
        ),
      );

      await commandRunner.run([
        'assemble',
        '--output',
        'Output',
        '--dart-define=${base64.encode(utf8.encode('flutter.inspector.structuredErrors=true'))}',
        'debug_macos_bundle_flutter_assets',
      ]);

      expect(logger.traceText, contains('build succeeded.'));
    },
  );

  testWithoutContext(
    'flutter assemble throws ToolExit if dart-defines are not base64 encoded',
    () async {
      final CommandRunner<void> commandRunner = createTestCommandRunner(
        AssembleCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          toolContext: toolContext,
        ),
      );

      const invalidDartDefines = [
        'flutter.inspector.structuredErrors%3Dtrue',
        '///',
        '@@@@',
        "'",
        '"',
        '`',
        r'\',
        r'$',
        ';',
        '/*',
        '*/',
        '//',
        '\n',
        '\r',
        '<',
        '>',
        '{',
        '}',
        '[',
        ']',
        '(',
        ')',
        '%',
        '=',
        '&',
        '?',
        '#',
      ];
      for (final invalidDartDefine in invalidDartDefines) {
        final command = <String>[
          'assemble',
          '--output',
          'Output',
          '-DartDefines=$invalidDartDefine',
          'debug_macos_bundle_flutter_assets',
        ];
        expect(
          commandRunner.run(command),
          throwsToolExit(
            message:
                'Error parsing assemble command: The -Pdart-defines argument contains non-base64 encoded data. '
                'Check your build command and try again.',
          ),
        );
      }
    },
  );

  testWithoutContext('flutter assemble throws ToolExit if called with non-existent rule', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        toolContext: toolContext,
      ),
    );

    expect(commandRunner.run(<String>['assemble', '-o Output', 'undefined']), throwsToolExit());
  });

  testWithoutContext('flutter assemble does not log stack traces during build failure', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(
          BuildResult(
            success: false,
            exceptions: <String, ExceptionMeasurement>{
              'hello': ExceptionMeasurement('hello', 'bar', stackTrace, fatal: true),
            },
          ),
        ),
        toolContext: toolContext,
      ),
    );

    await expectLater(
      commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit(),
    );
    expect(logger.errorText, contains('Target hello failed: bar'));
    expect(logger.errorText, isNot(contains(stackTrace.toString())));
  });

  testWithoutContext('flutter assemble outputs JSON performance data to provided file', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.all(
          BuildResult(
            success: true,
            performance: <String, PerformanceMeasurement>{
              'hello': PerformanceMeasurement(
                target: 'hello',
                analyticsName: 'bar',
                elapsedMilliseconds: 123,
                skipped: false,
                succeeded: true,
              ),
            },
          ),
        ),
        toolContext: toolContext,
      ),
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
      containsPair('targets', contains(containsPair('name', 'bar'))),
    );
  });

  testWithoutContext(
    'flutter assemble does not inject engine revision with local-engine',
    () async {
      final localArtifacts = Artifacts.testLocalEngine(
        localEngine: 'out/host_release',
        localEngineHost: 'out/host_release',
      );
      final localToolContext = FakeToolContext(
        artifacts: localArtifacts,
        cache: cache,
        fs: fileSystem,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );
      final CommandRunner<void> commandRunner = createTestCommandRunner(
        AssembleCommand(
          buildSystem: TestBuildSystem.all(BuildResult(success: true), (
            Target target,
            Environment environment,
          ) {
            expect(environment.engineVersion, isNull);
          }),
          toolContext: localToolContext,
        ),
      );
      await commandRunner.run(<String>[
        'assemble',
        '-o Output',
        'debug_macos_bundle_flutter_assets',
      ]);
    },
  );

  testWithoutContext(
    'flutter assemble only writes input and output files when the values change',
    () async {
      final BuildSystem buildSystem = TestBuildSystem.list(<BuildResult>[
        BuildResult(
          success: true,
          inputFiles: <File>[fileSystem.file('foo')..createSync()],
          outputFiles: <File>[fileSystem.file('bar')..createSync()],
        ),
        BuildResult(
          success: true,
          inputFiles: <File>[fileSystem.file('foo')..createSync()],
          outputFiles: <File>[fileSystem.file('bar')..createSync()],
        ),
        BuildResult(
          success: true,
          inputFiles: <File>[fileSystem.file('foo'), fileSystem.file('fizz')..createSync()],
          outputFiles: <File>[
            fileSystem.file('bar'),
            fileSystem.file(fileSystem.path.join('.dart_tool', 'fizz2'))
              ..createSync(recursive: true),
          ],
        ),
      ]);
      final CommandRunner<void> commandRunner = createTestCommandRunner(
        AssembleCommand(buildSystem: buildSystem, toolContext: toolContext),
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

      final theDistantPast = DateTime(1991, 8, 23);
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
    },
  );

  testWithoutContext('writePerformanceData outputs performance data in JSON form', () {
    final performanceMeasurement = <PerformanceMeasurement>[
      PerformanceMeasurement(
        analyticsName: 'foo',
        target: 'hidden',
        skipped: false,
        succeeded: true,
        elapsedMilliseconds: 123,
      ),
    ];
    final FileSystem localFileSystem = MemoryFileSystem.test();
    final File outFile = localFileSystem.currentDirectory
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

  testWithoutContext('hides itself from usage unless --verbose', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(buildSystem: TestBuildSystem.error(null), toolContext: toolContext),
    );

    // If all commands are hidden, hidden is ignored. Add a non-hidden stub command.
    commandRunner.addCommand(_StubCommand(toolContext: toolContext));

    await commandRunner.run(['--help']);
    expect(logger.statusText, isNot(contains('assemble')));
  });

  testWithoutContext('describes itself from usage if --verbose', () async {
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(
        buildSystem: TestBuildSystem.error(null),
        toolContext: toolContext,
        verboseHelp: true,
      ),
    );

    // If all commands are hidden, hidden is ignored. Add a non-hidden stub command.
    commandRunner.addCommand(_StubCommand(toolContext: toolContext));

    await commandRunner.run(['--help' /* -- verbose omitted (verboseHelp: true) is set above */]);
    expect(logger.statusText, contains('assemble'));
  });

  testWithoutContext('flutter assemble fails if pubspec.yaml is missing', () async {
    final emptyFs = MemoryFileSystem.test();
    final emptyToolContext = FakeToolContext(
      artifacts: artifacts,
      cache: cache,
      fs: emptyFs,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );
    final CommandRunner<void> commandRunner = createTestCommandRunner(
      AssembleCommand(buildSystem: TestBuildSystem.error(null), toolContext: emptyToolContext),
    );

    await expectLater(
      commandRunner.run(<String>['assemble', '-o Output', 'debug_macos_bundle_flutter_assets']),
      throwsToolExit(message: 'No pubspec.yaml file found'),
    );
  });
}

final class _StubCommand extends FlutterCommand {
  _StubCommand({super.toolContext});

  @override
  String get description => 'This is a stub';

  @override
  String get name => 'stub';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}
