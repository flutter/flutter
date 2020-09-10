// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/cmake.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_linux.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

const String _kTestFlutterRoot = '/flutter';

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'FLUTTER_ROOT': _kTestFlutterRoot
  }
);
final Platform notLinuxPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'FLUTTER_ROOT': _kTestFlutterRoot,
  }
);


void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  FileSystem fileSystem;
  ProcessManager processManager;
  MockUsage usage;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    Cache.flutterRoot = _kTestFlutterRoot;
    usage = MockUsage();
  });

  // Creates the mock files necessary to look like a Flutter project.
  void setUpMockCoreProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Creates the mock files necessary to run a build.
  void setUpMockProjectFilesForBuild() {
    setUpMockCoreProjectFiles();
    fileSystem.file(fileSystem.path.join('linux', 'CMakeLists.txt')).createSync(recursive: true);
  }

  // Returns the command matching the build_linux call to cmake.
  FakeCommand cmakeCommand(String buildMode, {void Function() onRun}) {
    return FakeCommand(
      command: <String>[
        'cmake',
        '-G',
        'Ninja',
        '-DCMAKE_BUILD_TYPE=${toTitleCase(buildMode)}',
        '/linux',
      ],
      workingDirectory: 'build/linux/$buildMode',
      onRun: onRun,
    );
  }

  // Returns the command matching the build_linux call to ninja.
  FakeCommand ninjaCommand(String buildMode, {
    Map<String, String> environment,
    void Function() onRun,
    String stdout = '',
  }) {
    return FakeCommand(
      command: <String>[
        'ninja',
        '-C',
        'build/linux/$buildMode',
        'install',
      ],
      environment: environment,
      onRun: onRun,
      stdout: stdout,
    );
  }

  testUsingContext('Linux build fails when there is no linux project', () async {
    final BuildCommand command = BuildCommand();
    setUpMockCoreProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--no-pub']
    ), throwsToolExit(message: 'No Linux desktop project configured'));
  }, overrides: <Type, Generator>{
    Platform: () => linuxPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build fails on non-linux platform', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--no-pub']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notLinuxPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build invokes CMake and ninja, and writes temporary files', () async {
    final BuildCommand command = BuildCommand();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('release'),
      ninjaCommand('release'),
    ]);

    setUpMockProjectFilesForBuild();

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--no-pub']
    );
    expect(fileSystem.file('linux/flutter/ephemeral/generated_config.cmake'), exists);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Handles argument error from missing cmake', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('release', onRun: () {
        throw ArgumentError();
      }),
    ]);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--no-pub']
    ), throwsToolExit(message: "cmake not found. Run 'flutter doctor' for more information."));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Handles argument error from missing ninja', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('release'),
      ninjaCommand('release', onRun: () {
        throw ArgumentError();
      }),
    ]);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--no-pub']
    ), throwsToolExit(message: "ninja not found. Run 'flutter doctor' for more information."));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build does not spew stdout to status logger', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('debug'),
      ninjaCommand('debug',
        stdout: 'STDOUT STUFF',
      ),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug', '--no-pub']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux verbose build sets VERBOSE_SCRIPT_LOGGING', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('debug'),
      ninjaCommand('debug',
        environment: const <String, String>{
          'VERBOSE_SCRIPT_LOGGING': 'true'
        },
        stdout: 'STDOUT STUFF',
      ),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug', '-v', '--no-pub']
    );
    expect(testLogger.statusText, contains('STDOUT STUFF'));
    expect(testLogger.traceText, isNot(contains('STDOUT STUFF')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build --debug passes debug mode to cmake and ninja', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('debug'),
      ninjaCommand('debug'),
    ]);


    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build --profile passes profile mode to make', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('profile'),
      ninjaCommand('profile'),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--profile', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build configures CMake exports', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('release'),
      ninjaCommand('release'),
    ]);
    fileSystem.file('lib/other.dart')
      .createSync(recursive: true);

    await createTestCommandRunner(command).run(
      const <String>[
        'build',
        'linux',
        '--target=lib/other.dart',
        '--no-pub',
        '--track-widget-creation',
        '--split-debug-info=foo/',
        '--enable-experiment=non-nullable',
        '--obfuscate',
        '--dart-define=foo.bar=2',
        '--dart-define=fizz.far=3',
        '--tree-shake-icons',
        '--bundle-sksl-path=foo/bar.sksl.json',
      ]
    );

    final File cmakeConfig = fileSystem.currentDirectory
      .childDirectory('linux')
      .childDirectory('flutter')
      .childDirectory('ephemeral')
      .childFile('generated_config.cmake');

    expect(cmakeConfig, exists);

    final List<String> configLines = cmakeConfig.readAsLinesSync();

    expect(configLines, containsAll(<String>[
      'file(TO_CMAKE_PATH "$_kTestFlutterRoot" FLUTTER_ROOT)',
      'file(TO_CMAKE_PATH "${fileSystem.currentDirectory.path}" PROJECT_DIR)',
      '  "DART_DEFINES=\\"foo.bar%3D2,fizz.far%3D3\\""',
      '  "DART_OBFUSCATION=\\"true\\""',
      '  "EXTRA_FRONT_END_OPTIONS=\\"--enable-experiment%3Dnon-nullable\\""',
      '  "EXTRA_GEN_SNAPSHOT_OPTIONS=\\"--enable-experiment%3Dnon-nullable\\""',
      '  "SPLIT_DEBUG_INFO=\\"foo/\\""',
      '  "TRACK_WIDGET_CREATION=\\"true\\""',
      '  "TREE_SHAKE_ICONS=\\"true\\""',
      '  "FLUTTER_ROOT=\\"$_kTestFlutterRoot\\""',
      '  "PROJECT_DIR=\\"${fileSystem.currentDirectory.path}\\""',
      '  "FLUTTER_TARGET=\\"lib/other.dart\\""',
      '  "BUNDLE_SKSL_PATH=\\"foo/bar.sksl.json\\""',
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('linux can extract binary name from CMake file', () async {
    fileSystem.file('linux/CMakeLists.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "fizz_bar")
''');
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(getCmakeExecutableName(flutterProject.linux), 'fizz_bar');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Refuses to build for Linux when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'linux', '--no-pub']),
      throwsToolExit());
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
  });

  testUsingContext('hidden when not enabled on Linux host', () {
    expect(BuildLinuxCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
    Platform: () => notLinuxPlatform,
  });

  testUsingContext('Not hidden when enabled and on Linux host', () {
    expect(BuildLinuxCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
    Platform: () => linuxPlatform,
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild();
    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeCommand('release'),
      ninjaCommand('release', onRun: () {
        fileSystem.file('build/flutter_size_01/snapshot.linux-x64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''[
{
  "l": "dart:_internal",
  "c": "SubListIterable",
  "n": "[Optimized] skip",
  "s": 2400
}
          ]''');
        fileSystem.file('build/flutter_size_01/trace.linux-x64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }),
    ]);

    fileSystem.file('build/linux/release/bundle/libapp.so')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(10000, 0));

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--no-pub', '--analyze-size']
    );
    expect(testLogger.statusText, contains('A summary of your Linux bundle analysis can be found at'));
    verify(usage.sendEvent('code-size-analysis', 'linux')).called(1);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
    Usage: () => usage,
  });
}

class MockUsage extends Mock implements Usage {}
