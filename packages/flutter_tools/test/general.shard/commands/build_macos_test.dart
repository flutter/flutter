// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  MockProcessManager mockProcessManager;
  MemoryFileSystem memoryFilesystem;
  MockProcess mockProcess;
  MockPlatform macosPlatform;
  MockPlatform notMacosPlatform;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    memoryFilesystem = MemoryFileSystem();
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
      return const Stream<List<int>>.empty();
    });
    when(macosPlatform.isMacOS).thenReturn(true);
    when(notMacosPlatform.isMacOS).thenReturn(false);
  });

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
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => memoryFilesystem,
    FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
  });

  testUsingContext('macOS build invokes build script', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.directory('macos').createSync();
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    final FlutterProject flutterProject = FlutterProject.fromDirectory(fs.currentDirectory);
    final Environment environment = Environment(
      projectDir: flutterProject.directory,
      buildDir: flutterProject.dartTool.childDirectory('flutter_build'),
      defines: <String, String>{
        kBuildMode: 'release',
        kTargetFile: fs.path.absolute(fs.path.join('lib', 'main.dart')),
        kTargetPlatform: 'darwin-x64',
      }
    );
    when(mockProcessManager.start(<String>[
      '/usr/bin/env',
      'xcrun',
      'xcodebuild',
      '-workspace', flutterProject.macos.xcodeWorkspace.path,
      '-configuration', 'Release',
      '-scheme', 'Runner',
      '-derivedDataPath', environment.buildDir.path,
      'OBJROOT=${fs.path.join(environment.buildDir.path, 'Build', 'Intermediates.noindex')}',
      'SYMROOT=${fs.path.join(environment.buildDir.path, 'Build', 'Products')}',
    ])).thenAnswer((Invocation invocation) async {
      fs.file(fs.path.join('macos', 'Flutter', 'ephemeral', '.app_filename'))
        ..createSync(recursive: true)
        ..writeAsStringSync('example.app');
      return mockProcess;
    });

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'macos', '--release']
    ), throwsA(isInstanceOf<AssertionError>()));
  }, overrides: <Type, Generator>{
    FileSystem: () => memoryFilesystem,
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
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}
