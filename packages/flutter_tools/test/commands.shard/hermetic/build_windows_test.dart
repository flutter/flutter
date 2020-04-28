// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
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

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

const String flutterRoot = r'C:\flutter';
const String solutionPath = r'C:\windows\Runner.sln';
const String visualStudioPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community';
const String vcvarsPath = visualStudioPath + r'\VC\Auxiliary\Build\vcvars64.bat';

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'PROGRAMFILES(X86)':  r'C:\Program Files (x86)\',
    'FLUTTER_ROOT': flutterRoot,
  }
);
final Platform notWindowsPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{
    'FLUTTER_ROOT': flutterRoot,
  }
);

void main() {
  FileSystem fileSystem;

  MockProcessManager mockProcessManager;
  MockProcess mockProcess;
  MockVisualStudio mockVisualStudio;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    Cache.flutterRoot = flutterRoot;
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
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();

    expect(createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => fileSystem,
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
      const <String>['windows', '--no-pub']
    ), throwsToolExit(message: 'No Windows desktop project configured'));
  }, overrides: <Type, Generator>{
    Platform: () => windowsPlatform,
    FileSystem: () => fileSystem,
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
      const <String>['windows', '--no-pub']
    ), throwsToolExit());
  }, overrides: <Type, Generator>{
    Platform: () => notWindowsPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails with instructions when template is too old', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild(templateVersion: 1);

    expect(createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    ), throwsToolExit(message: 'flutter create .'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build fails with instructions when template is too new', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild(templateVersion: 999);

    expect(createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    ), throwsToolExit(message: 'Upgrade Flutter'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build does not spew stdout to status logger', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
        fileSystem.path.join(flutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
        vcvarsPath,
        fileSystem.path.basename(solutionPath),
        'Release',
      ],
      environment: <String, String>{},
      workingDirectory: fileSystem.path.dirname(solutionPath))
    ).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => mockProcessManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows verbose build sets VERBOSE_SCRIPT_LOGGING', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.vcvarsPath).thenReturn(vcvarsPath);

    when(mockProcessManager.start(<String>[
        fileSystem.path.join(flutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
        vcvarsPath,
        fileSystem.path.basename(solutionPath),
        'Release',
      ],
      environment: <String, String>{
        'VERBOSE_SCRIPT_LOGGING': 'true',
      },
      workingDirectory: fileSystem.path.dirname(solutionPath))
    ).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub', '-v']
    );
    expect(testLogger.statusText, contains('STDOUT STUFF'));
    expect(testLogger.traceText, isNot(contains('STDOUT STUFF')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
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
        fileSystem.path.join(flutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
        vcvarsPath,
        fileSystem.path.basename(solutionPath),
        'Release',
      ],
      environment: <String, String>{},
      workingDirectory: fileSystem.path.dirname(solutionPath))
    ).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });

    await createTestCommandRunner(command).run(
      const <String>[
        'windows',
        '--no-pub',
        '--track-widget-creation',
        '--obfuscate',
        '--tree-shake-icons',
        '--enable-experiment=non-nullable',
        r'--split-debug-info=C:\foo\',
        '--dart-define=foo=a',
        '--dart-define=bar=b',
        r'--target=lib\main.dart',
      ]
    );

    // Spot-check important elements from the properties file.
    final File propsFile = fileSystem.file(r'C:\windows\flutter\ephemeral\Generated.props');
    expect(propsFile, exists);

    final xml.XmlDocument props = xml.parse(propsFile.readAsStringSync());
    expect(props.findAllElements('PropertyGroup').first.getAttribute('Label'), 'UserMacros');
    expect(props.findAllElements('ItemGroup').length, 1);
    expect(props.findAllElements('FLUTTER_ROOT').first.text, flutterRoot);
    expect(props.findAllElements('TRACK_WIDGET_CREATION').first.text, 'true');
    expect(props.findAllElements('TREE_SHAKE_ICONS').first.text, 'true');
    expect(props.findAllElements('EXTRA_GEN_SNAPSHOT_OPTIONS').first.text, '--enable-experiment=non-nullable');
    expect(props.findAllElements('EXTRA_FRONT_END_OPTIONS').first.text, '--enable-experiment=non-nullable');
    expect(props.findAllElements('DART_DEFINES').first.text, 'foo=a,bar=b');
    expect(props.findAllElements('DART_OBFUSCATION').first.text, 'true');
    expect(props.findAllElements('SPLIT_DEBUG_INFO').first.text, r'C:\foo\');
    expect(props.findAllElements('FLUTTER_TARGET').first.text, r'lib\main.dart');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
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

    when(mockProcessManager.start(
      <String>[
        fileSystem.path.join(flutterRoot, 'packages', 'flutter_tools', 'bin', 'vs_build.bat'),
        vcvarsPath,
        fileSystem.path.basename(solutionPath),
        'Release',
      ],
      environment: <String, String>{},
      workingDirectory: fileSystem.path.dirname(solutionPath))).thenAnswer((Invocation invocation) async {
        return mockProcess;
      },
    );

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    );

    expect(testLogger.statusText, contains('🚧'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
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
