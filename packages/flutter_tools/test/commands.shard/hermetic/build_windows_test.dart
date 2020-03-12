// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_windows.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

const String solutionPath = r'C:\windows\Runner.sln';
const String visualStudioPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community';
const String vcvarsPath = visualStudioPath + r'\VC\Auxiliary\Build\vcvars64.bat';

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'PROGRAMFILES(X86)':  r'C:\Program Files (x86)\',
    'FLUTTER_ROOT': r'C:\',
  }
);
final Platform notWindowsPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'FLUTTER_ROOT': r'C:\',
  }
);

void main() {
  MockProcessManager mockProcessManager;
  MockProcess mockProcess;
  MockVisualStudio mockVisualStudio;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    mockProcess = MockProcess();
    mockVisualStudio = MockVisualStudio();
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async {
      return 0;
    });
    when(mockProcess.stderr).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(mockProcess.stdout).thenAnswer((Invocation invocation) {
      return Stream<List<int>>.fromIterable(<List<int>>[utf8.encode('STDOUT STUFF')]);
    });
  });

  // Creates the mock files necessary to look like a Flutter project.
  void setUpMockCoreProjectFiles() {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Creates the mock files necessary to run a build.
  void setUpMockProjectFilesForBuild() {
    globals.fs.file(solutionPath).createSync(recursive: true);
    setUpMockCoreProjectFiles();
  }

  testUsingContext('Windows build fails when there is no vcvars64.bat', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();

    expect(createTestCommandRunner(command).run(
      const <String>['windows']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails when there is no windows project', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockCoreProjectFiles();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    expect(createTestCommandRunner(command).run(
      const <String>['windows']
    ), throwsToolExit(message: 'No Windows desktop project configured'));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails on non windows platform', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    expect(createTestCommandRunner(command).run(
      const <String>['windows']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notWindowsPlatform,
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build does not spew stdout to status logger', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
      r'C:\packages\flutter_tools\bin\vs_build.bat',
      vcvarsPath,
      globals.fs.path.basename(solutionPath),
      'Release',
    ], workingDirectory: globals.fs.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['windows']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build invokes msbuild and writes generated files', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
      r'C:\packages\flutter_tools\bin\vs_build.bat',
      vcvarsPath,
      globals.fs.path.basename(solutionPath),
      'Release',
    ], workingDirectory: globals.fs.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['windows']
    );

    // Spot-check important elements from the properties file.
    final File propsFile = globals.fs.file(r'C:\windows\flutter\ephemeral\Generated.props');
    expect(propsFile.existsSync(), true);
    final xml.XmlDocument props = xml.parse(propsFile.readAsStringSync());
    expect(props.findAllElements('PropertyGroup').first.getAttribute('Label'), 'UserMacros');
    expect(props.findAllElements('ItemGroup').length, 1);
    expect(props.findAllElements('FLUTTER_ROOT').first.text, r'C:\');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Release build prints an under-construction warning', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
      r'C:\packages\flutter_tools\bin\vs_build.bat',
      vcvarsPath,
      globals.fs.path.basename(solutionPath),
      'Release',
    ], workingDirectory: globals.fs.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['windows']
    );

    expect(testLogger.statusText, contains('🚧'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('hidden when not enabled on Windows host', () {
    expect(BuildWindowsCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: false),
    Platform: () => windowsPlatform,
  });

  testUsingContext('Not hidden when enabled and on Windows host', () {
    expect(BuildWindowsCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
    Platform: () => windowsPlatform,
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockVisualStudio extends Mock implements VisualStudio {}
