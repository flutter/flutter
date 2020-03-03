// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
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

const String _kTestFlutterRoot = r'C:\flutter';

void main() {
  FileSystem fileSystem;

  MockProcessManager mockProcessManager;
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
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    Cache.flutterRoot = _kTestFlutterRoot;
    mockProcessManager = MockProcessManager();
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
      return Stream<List<int>>.fromIterable(<List<int>>[utf8.encode('STDOUT STUFF')]);
    });
    when(windowsPlatform.isWindows).thenReturn(true);
    when(notWindowsPlatform.isWindows).thenReturn(false);
  });

  // Creates the mock files necessary to look like a Flutter project.
  void setUpMockCoreProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Creates the mock files necessary to run a build.
  void setUpMockProjectFilesForBuild({int templateVersion}) {
    fileSystem.file(solutionPath).createSync(recursive: true);
    setUpMockCoreProjectFiles();

    final String versionFileSubpath = fileSystem.path.join('flutter', '.template_version');
    const int expectedTemplateVersion = 10;  // Arbitrary value for tests.
    final File sourceTemplateVersionfile = fileSystem.file(fileSystem.path.join(
      fileSystem.path.absolute(Cache.flutterRoot),
      'packages',
      'flutter_tools',
      'templates',
      'app',
      'windows.tmpl',
      versionFileSubpath,
    ));
    sourceTemplateVersionfile.createSync(recursive: true);
    sourceTemplateVersionfile.writeAsStringSync(expectedTemplateVersion.toString());

    final File projectTemplateVersionFile = fileSystem.file(
      fileSystem.path.join('windows', versionFileSubpath));
    templateVersion ??= expectedTemplateVersion;
    projectTemplateVersionFile.createSync(recursive: true);
    projectTemplateVersionFile.writeAsStringSync(templateVersion.toString());
  }

  testUsingContext('Windows build fails when there is no vcvars64.bat', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails when there is no windows project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockCoreProjectFiles();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsToolExit(message: 'No Windows desktop project configured'));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails on non windows platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notWindowsPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails with instructions when template is too old', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild(templateVersion: 1);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsToolExit(message: 'flutter create .'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails with instructions when template is too new', () async {
    final BuildCommand command = BuildCommand();
    setUpMockProjectFilesForBuild(templateVersion: 999);

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    ), throwsToolExit(message: 'Upgrade Flutter'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build does not spew stdout to status logger', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
      fileSystem.path.join(_kTestFlutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
      vcvarsPath,
      fileSystem.path.basename(solutionPath),
      'Release',
    ], workingDirectory: fileSystem.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build invokes msbuild and writes generated files', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
      fileSystem.path.join(_kTestFlutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
      vcvarsPath,
      fileSystem.path.basename(solutionPath),
      'Release',
    ], workingDirectory: fileSystem.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    );

    // Spot-check important elements from the properties file.
    final File propsFile = fileSystem.file(r'C:\windows\flutter\ephemeral\Generated.props');
    expect(propsFile.existsSync(), true);
    final xml.XmlDocument props = xml.parse(propsFile.readAsStringSync());
    expect(props.findAllElements('PropertyGroup').first.getAttribute('Label'), 'UserMacros');
    expect(props.findAllElements('ItemGroup').length, 1);
    expect(props.findAllElements('FLUTTER_ROOT').first.text, _kTestFlutterRoot);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Release build prints an under-construction warning', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
      fileSystem.path.join(_kTestFlutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
      vcvarsPath,
      fileSystem.path.basename(solutionPath),
      'Release',
    ], workingDirectory: fileSystem.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['build', 'windows']
    );

    expect(testLogger.statusText, contains('🚧'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    VisualStudio: () => mockVisualStudio,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('hidden when not enabled on Windows host', () {
    when(globals.platform.isWindows).thenReturn(true);

    expect(BuildWindowsCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: false),
    Platform: () => MockPlatform(),
  });

  testUsingContext('Not hidden when enabled and on Windows host', () {
    when(globals.platform.isWindows).thenReturn(true);

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
    'FLUTTER_ROOT': _kTestFlutterRoot,
  };
}
class MockVisualStudio extends Mock implements VisualStudio {}
