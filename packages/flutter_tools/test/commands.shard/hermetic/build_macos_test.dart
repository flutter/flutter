// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_macos.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
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

void main() {
  MockProcessManager mockProcessManager;
  MockProcess mockProcess;
  MockPlatform macosPlatform;
  MockPlatform notMacosPlatform;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    mockProcess = MockProcess();
    macosPlatform = MockPlatform();
    notMacosPlatform = MockPlatform();
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async {
      return 0;
    });
    when(mockProcess.stderr).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(mockProcess.stdout).thenAnswer((Invocation invocation) {
      return Stream<List<int>>.fromIterable(<List<int>>[utf8.encode('STDOUT STUFF')]);
    });
    when(macosPlatform.isMacOS).thenReturn(true);
    when(macosPlatform.isWindows).thenReturn(false);
    when(notMacosPlatform.isMacOS).thenReturn(false);
    when(notMacosPlatform.isWindows).thenReturn(false);
  });

  // Sets up the minimal mock project files necessary for macOS builds to succeed.
  void createMinimalMockProjectFiles() {
    globals.fs.directory('macos').createSync();
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Mocks the process manager to handle an xcodebuild call to build the app
  // in the given configuration.
  void setUpMockXcodeBuildHandler(String configuration) {
    final FlutterProject flutterProject = FlutterProject.fromDirectory(globals.fs.currentDirectory);
    final Directory flutterBuildDir = globals.fs.directory(getMacOSBuildDirectory());
    when(mockProcessManager.start(<String>[
      '/usr/bin/env',
      'xcrun',
      'xcodebuild',
      '-workspace', flutterProject.macos.xcodeWorkspace.path,
      '-configuration', configuration,
      '-scheme', 'Runner',
      '-derivedDataPath', flutterBuildDir.absolute.path,
      'OBJROOT=${globals.fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
      'SYMROOT=${globals.fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Products')}',
      'COMPILER_INDEX_STORE_ENABLE=NO',
    ])).thenAnswer((Invocation invocation) async {
      globals.fs.file(globals.fs.path.join('macos', 'Flutter', 'ephemeral', '.app_filename'))
        ..createSync(recursive: true)
        ..writeAsStringSync('example.app');
      return mockProcess;
    });
  }

  testUsingContext('macOS build fails when there is no macos project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build does not spew stdout to status logger', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    createMinimalMockProjectFiles();
    setUpMockXcodeBuildHandler('Debug');

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (debug)', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    createMinimalMockProjectFiles();
    setUpMockXcodeBuildHandler('Debug');

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--debug']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (profile)', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    createMinimalMockProjectFiles();
    setUpMockXcodeBuildHandler('Profile');

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--profile']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithProfile(),
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes xcode build (release)', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    createMinimalMockProjectFiles();
    setUpMockXcodeBuildHandler('Release');

    await createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--release']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => macosPlatform,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('Refuses to build for macOS when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'macos']),
        throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
  });

  testUsingContext('hidden when not enabled on macOS host', () {
    when(globals.platform.isMacOS).thenReturn(true);

    expect(BuildMacosCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: false),
    Platform: () => MockPlatform(),
  });

  testUsingContext('Not hidden when enabled and on macOS host', () {
    when(globals.platform.isMacOS).thenReturn(true);

    expect(BuildMacosCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    Platform: () => MockPlatform(),
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}
