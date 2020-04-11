// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_macos.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

class FakeXcodeProjectInterpreterWithProfile extends FakeXcodeProjectInterpreter {
  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return XcodeProjectInfo(
      <String>['Runner'],
      <String>['Debug', 'Profile', 'Release'],
      <String>['Runner'],
    );
  }
}

final Platform macosPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
  }
);
final Platform notMacosPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
  }
);

void main() {
  FileSystem fileSystem;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  // Sets up the minimal mock project files necessary to look like a Flutter project.
  void createCoreMockProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up the minimal mock project files necessary for macOS builds to succeed.
  void createMinimalMockProjectFiles() {
    fileSystem.directory(fileSystem.path.join('macos', 'Runner.xcworkspace')).createSync(recursive: true);
    createCoreMockProjectFiles();
  }

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpMockXcodeBuildHandler(String configuration, { bool verbose = false }) {
    final FlutterProject flutterProject = FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final Directory flutterBuildDir = fileSystem.directory(getMacOSBuildDirectory());
    return FakeCommand(
      command: <String>[
        '/usr/bin/env',
        'xcrun',
        'xcodebuild',
        '-workspace', flutterProject.macos.xcodeWorkspace.path,
        '-configuration', configuration,
        '-scheme', 'Runner',
        '-derivedDataPath', flutterBuildDir.absolute.path,
        'OBJROOT=${fileSystem.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
        'SYMROOT=${fileSystem.path.join(flutterBuildDir.absolute.path, 'Build', 'Products')}',
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING=YES',
        'COMPILER_INDEX_STORE_ENABLE=NO',
      ],
      stdout: 'STDOUT STUFF',
      onRun: () {
        fileSystem.file(fileSystem.path.join('macos', 'Flutter', 'ephemeral', '.app_filename'))
          ..createSync(recursive: true)
          ..writeAsStringSync('example.app');
      }
    );
  }

  testUsingContext('macOS build fails when there is no macos project', () async {
    final BuildCommand command = BuildCommand();
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsToolExit(message: 'No macOS desktop project configured'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build does not spew stdout to status logger', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpMockXcodeBuildHandler('Debug')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (debug)', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpMockXcodeBuildHandler('Debug')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (debug) with verbosity', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug', '-v']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpMockXcodeBuildHandler('Debug', verbose: true)
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });


  testUsingContext('macOS build invokes xcode build (profile)', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--profile']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpMockXcodeBuildHandler('Profile')
    ]),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithProfile(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (release)', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--release']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpMockXcodeBuildHandler('Release')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build supports build-name and build-number', () async {
    final BuildCommand command = BuildCommand();
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>[
        'build',
        'macos',
        '--debug',
        '--build-name=1.2.3',
        '--build-number=42',
      ],
    );
    final String contents = fileSystem
      .file('./macos/Flutter/ephemeral/Flutter-Generated.xcconfig')
      .readAsStringSync();

    expect(contents, contains('FLUTTER_BUILD_NAME=1.2.3'));
    expect(contents, contains('FLUTTER_BUILD_NUMBER=42'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      setUpMockXcodeBuildHandler('Debug')
    ]),
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('Refuses to build for macOS when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'macos']),
      throwsToolExit());
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });

  testUsingContext('hidden when not enabled on macOS host', () {
    expect(BuildMacosCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
    Platform: () => macosPlatform,
  });

  testUsingContext('Not hidden when enabled and on macOS host', () {
    expect(BuildMacosCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    Platform: () => macosPlatform,
  });
}
