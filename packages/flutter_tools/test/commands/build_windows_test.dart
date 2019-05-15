// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:xml/xml.dart' as xml;

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  Cache.disableLocking();
  final MockProcessManager mockProcessManager = MockProcessManager();
  final MemoryFileSystem memoryFilesystem = MemoryFileSystem(style: FileSystemStyle.windows);
  final MockProcess mockProcess = MockProcess();
  final MockPlatform windowsPlatform = MockPlatform()
      ..environment['PROGRAMFILES(X86)'] = r'C:\Program Files (x86)\';
  final MockPlatform notWindowsPlatform = MockPlatform();
  const String projectPath = r'windows\Runner.vcxproj';
  // A vcvars64.bat location that will be found by the lookup method.
  const String vcvarsPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat';

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

  testUsingContext('Windows build fails when there is no vcvars64.bat', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(projectPath).createSync(recursive: true);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => memoryFilesystem,
  });

  testUsingContext('Windows build fails when there is no windows project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(vcvarsPath).createSync(recursive: true);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => memoryFilesystem,
  });

  testUsingContext('Windows build fails on non windows platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(projectPath).createSync(recursive: true);
    fs.file(vcvarsPath).createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notWindowsPlatform,
    FileSystem: () => memoryFilesystem,
  });

  testUsingContext('Windows build invokes msbuild and writes generated files', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    fs.file(projectPath).createSync(recursive: true);
    fs.file(vcvarsPath).createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();

    when(mockProcessManager.start(<String>[
      vcvarsPath,
      '&&',
      'msbuild',
      'C:\\$projectPath',
      '/p:Configuration=Release',
    ], runInShell: true)).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    );

    // Spot-check important elemenst from the properties file.
    final File propsFile = fs.file(r'C:\windows\flutter\Generated.props');
    expect(propsFile.existsSync(), true);
    final xml.XmlDocument props = xml.parse(propsFile.readAsStringSync());
    expect(props.findAllElements('PropertyGroup').first.getAttribute('Label'), 'UserMacros');
    expect(props.findAllElements('ItemGroup').length, 1);
    expect(props.findAllElements('FLUTTER_ROOT').first.text, r'C:\');
  }, overrides: <Type, Generator>{
    FileSystem: () => memoryFilesystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
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
