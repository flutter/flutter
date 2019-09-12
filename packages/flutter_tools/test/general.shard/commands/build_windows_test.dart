// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_windows.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:xml/xml.dart' as xml;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  MockProcessManager mockProcessManager;
  MemoryFileSystem memoryFilesystem;
  MockProcess mockProcess;
  MockPlatform windowsPlatform;
  MockPlatform notWindowsPlatform;
  MockVisualStudio mockVisualStudio;
  const String solutionPath = r'C:\windows\Runner.sln';
  const String visualStudioPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community';
  const String vcvarsPath = visualStudioPath + r'\VC\Auxiliary\Build\vcvars64.bat';

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    memoryFilesystem = MemoryFileSystem(style: FileSystemStyle.windows);
    mockProcess = MockProcess();
    windowsPlatform = MockPlatform()
        ..environment['PROGRAMFILES(X86)'] = r'C:\Program Files (x86)\';
    notWindowsPlatform = MockPlatform();
    mockVisualStudio = MockVisualStudio();
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async {
      return 0;
    });
    when(mockProcess.stderr).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(mockProcess.stdout).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(windowsPlatform.isWindows).thenReturn(true);
    when(notWindowsPlatform.isWindows).thenReturn(false);
  });

  testUsingContext('Windows build fails when there is no vcvars64.bat', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(solutionPath).createSync(recursive: true);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => memoryFilesystem,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails when there is no windows project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => memoryFilesystem,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails on non windows platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(solutionPath).createSync(recursive: true);
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notWindowsPlatform,
    FileSystem: () => memoryFilesystem,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build invokes msbuild and writes generated files', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(solutionPath).createSync(recursive: true);
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    when(mockProcessManager.start(<String>[
      r'C:\packages\flutter_tools\bin\vs_build.bat',
      vcvarsPath,
      fs.path.basename(solutionPath),
      'Release',
    ], workingDirectory: fs.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    );

    // Spot-check important elements from the properties file.
    final File propsFile = fs.file(r'C:\windows\flutter\ephemeral\Generated.props');
    expect(propsFile.existsSync(), true);
    final xml.XmlDocument props = xml.parse(propsFile.readAsStringSync());
    expect(props.findAllElements('PropertyGroup').first.getAttribute('Label'), 'UserMacros');
    expect(props.findAllElements('ItemGroup').length, 1);
    expect(props.findAllElements('FLUTTER_ROOT').first.text, r'C:\');
  }, overrides: <Type, Generator>{
    FileSystem: () => memoryFilesystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Release build prints an under-construction warning', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(solutionPath).createSync(recursive: true);
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);

    when(mockProcessManager.start(<String>[
      r'C:\packages\flutter_tools\bin\vs_build.bat',
      vcvarsPath,
      fs.path.basename(solutionPath),
      'Release',
    ], workingDirectory: fs.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    );

    final BufferLogger bufferLogger = logger;
    expect(bufferLogger.statusText, contains('🚧'));
  }, overrides: <Type, Generator>{
    FileSystem: () => memoryFilesystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('hidden when not enabled on Windows host', () {
    when(platform.isWindows).thenReturn(true);

    expect(BuildWindowsCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: false),
     Platform: () => MockPlatform(),
  });

  testUsingContext('Not hidden when enabled and on Windows host', () {
    when(platform.isWindows).thenReturn(true);

    expect(BuildWindowsCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
    Platform: () => MockPlatform(),
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': r'C:\',
  };
}
class MockVisualStudio extends Mock implements VisualStudio {}
