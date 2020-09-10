// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_windows.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

const String flutterRoot = r'C:\flutter';
const String buildFilePath = r'C:\windows\CMakeLists.txt';
const String visualStudioPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community';
const String cmakePath = visualStudioPath + r'\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe';

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

  ProcessManager processManager;
  MockVisualStudio mockVisualStudio;
  MockUsage usage;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    Cache.flutterRoot = flutterRoot;
    mockVisualStudio = MockVisualStudio();
    usage = MockUsage();
  });

  // Creates the mock files necessary to look like a Flutter project.
  void setUpMockCoreProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Creates the mock files necessary to run a build.
  void setUpMockProjectFilesForBuild({int templateVersion}) {
    fileSystem.file(buildFilePath).createSync(recursive: true);
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

  // Returns the command matching the build_windows call to generate CMake
  // files.
  FakeCommand cmakeGenerationCommand({void Function() onRun}) {
    return FakeCommand(
      command: <String>[
        cmakePath,
        '-S',
        fileSystem.path.dirname(buildFilePath),
        '-B',
        r'build\windows',
        '-G',
        'Visual Studio 16 2019',
      ],
      onRun: onRun,
    );
  }

  // Returns the command matching the build_windows call to build.
  FakeCommand buildCommand(String buildMode, {
    bool verbose = false,
    void Function() onRun,
    String stdout = '',
  }) {
    return FakeCommand(
      command: <String>[
        cmakePath,
        '--build',
        r'build\windows',
        '--config',
        buildMode,
        '--target',
        'INSTALL',
        if (verbose)
          '--verbose'
      ],
      environment: <String, String>{
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING': 'true'
      },
      onRun: onRun,
      stdout: stdout,
    );
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
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

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
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

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
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeGenerationCommand(),
      buildCommand('Release',
        stdout: 'STDOUT STUFF',
      ),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build extracts errors from stdout', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

    // This contains a mix of routine build output and various types of errors
    // (compile error, link error, warning treated as an error) from MSBuild,
    // edited down for compactness. For instance, where similar lines are
    // repeated in actual output, one or two representative lines are chosen
    // to be included here.
    const String stdout = r'''Microsoft (R) Build Engine version 16.6.0+5ff7b0c9e for .NET Framework
Copyright (C) Microsoft Corporation. All rights reserved.

  Checking Build System
  Generating C:/foo/windows/flutter/ephemeral/flutter_windows.dll, [etc], _phony_
  Building Custom Rule C:/foo/windows/flutter/CMakeLists.txt
  standard_codec.cc
  Generating Code...
  flutter_wrapper_plugin.vcxproj -> C:\foo\build\windows\flutter\Debug\flutter_wrapper_plugin.lib
C:\foo\windows\runner\main.cpp(18): error C2220: the following warning is treated as an error [C:\foo\build\windows\runner\test.vcxproj]
C:\foo\windows\runner\main.cpp(18): warning C4706: assignment within conditional expression [C:\foo\build\windows\runner\test.vcxproj]
main.obj : error LNK2019: unresolved external symbol "void __cdecl Bar(void)" (?Bar@@YAXXZ) referenced in function wWinMain [C:\foo\build\windows\runner\test.vcxproj]
C:\foo\build\windows\runner\Debug\test.exe : fatal error LNK1120: 1 unresolved externals [C:\foo\build\windows\runner\test.vcxproj]
  Building Custom Rule C:/foo/windows/runner/CMakeLists.txt
  flutter_window.cpp
  main.cpp
C:\foo\windows\runner\main.cpp(17,1): error C2065: 'Baz': undeclared identifier [C:\foo\build\windows\runner\test.vcxproj]
  -- Install configuration: "Debug"
  -- Installing: C:/foo/build/windows/runner/Debug/data/icudtl.dat
''';

    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeGenerationCommand(),
      buildCommand('Release',
        stdout: stdout,
      ),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub']
    );
    // Just the warnings and errors should be surfaced.
    expect(testLogger.errorText, r'''C:\foo\windows\runner\main.cpp(18): error C2220: the following warning is treated as an error [C:\foo\build\windows\runner\test.vcxproj]
C:\foo\windows\runner\main.cpp(18): warning C4706: assignment within conditional expression [C:\foo\build\windows\runner\test.vcxproj]
main.obj : error LNK2019: unresolved external symbol "void __cdecl Bar(void)" (?Bar@@YAXXZ) referenced in function wWinMain [C:\foo\build\windows\runner\test.vcxproj]
C:\foo\build\windows\runner\Debug\test.exe : fatal error LNK1120: 1 unresolved externals [C:\foo\build\windows\runner\test.vcxproj]
C:\foo\windows\runner\main.cpp(17,1): error C2065: 'Baz': undeclared identifier [C:\foo\build\windows\runner\test.vcxproj]
''');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows verbose build sets VERBOSE_SCRIPT_LOGGING', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeGenerationCommand(),
      buildCommand('Release',
        verbose: true,
        stdout: 'STDOUT STUFF',
      ),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub', '-v']
    );
    expect(testLogger.statusText, contains('STDOUT STUFF'));
    expect(testLogger.traceText, isNot(contains('STDOUT STUFF')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows build invokes build and writes generated files', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeGenerationCommand(),
      buildCommand('Release'),
    ]);
    fileSystem.file(fileSystem.path.join('lib', 'other.dart'))
      .createSync(recursive: true);

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
        r'--bundle-sksl-path=foo\bar.sksl.json',
        r'--target=lib\other.dart',
      ]
    );

    final File cmakeConfig = fileSystem.currentDirectory
      .childDirectory('windows')
      .childDirectory('flutter')
      .childDirectory('ephemeral')
      .childFile('generated_config.cmake');

    expect(cmakeConfig, exists);

    final List<String> configLines = cmakeConfig.readAsLinesSync();

    // Backslashes are escaped in the file, which is why this uses both raw
    // strings and double backslashes.
    expect(configLines, containsAll(<String>[
      r'file(TO_CMAKE_PATH "C:\\flutter" FLUTTER_ROOT)',
      r'file(TO_CMAKE_PATH "C:\\" PROJECT_DIR)',
      r'  "DART_DEFINES=\"foo%3Da,bar%3Db\""',
      r'  "DART_OBFUSCATION=\"true\""',
      r'  "EXTRA_FRONT_END_OPTIONS=\"--enable-experiment%3Dnon-nullable\""',
      r'  "EXTRA_GEN_SNAPSHOT_OPTIONS=\"--enable-experiment%3Dnon-nullable\""',
      r'  "SPLIT_DEBUG_INFO=\"C:\\foo\\\""',
      r'  "TRACK_WIDGET_CREATION=\"true\""',
      r'  "TREE_SHAKE_ICONS=\"true\""',
      r'  "FLUTTER_ROOT=\"C:\\flutter\""',
      r'  "PROJECT_DIR=\"C:\\\""',
      r'  "FLUTTER_TARGET=\"lib\\other.dart\""',
      r'  "BUNDLE_SKSL_PATH=\"foo\\bar.sksl.json\""',
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => windowsPlatform,
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
  });

  testUsingContext('Windows profile build passes Profile configuration', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeGenerationCommand(),
      buildCommand('Profile'),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['windows', '--profile', '--no-pub']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
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

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildWindowsCommand command = BuildWindowsCommand()
      ..visualStudioOverride = mockVisualStudio;
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockVisualStudio.cmakePath).thenReturn(cmakePath);

    fileSystem.file(r'build\windows\runner\Release\app.so')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0));

    processManager = FakeProcessManager.list(<FakeCommand>[
      cmakeGenerationCommand(),
      buildCommand('Release', onRun: () {
        fileSystem.file(r'build\flutter_size_01\snapshot.windows-x64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''[
{
  "l": "dart:_internal",
  "c": "SubListIterable",
  "n": "[Optimized] skip",
  "s": 2400
}
          ]''');
        fileSystem.file(r'build\flutter_size_01\trace.windows-x64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['windows', '--no-pub', '--analyze-size']
    );

    expect(testLogger.statusText, contains('A summary of your Windows bundle analysis can be found at'));
    verify(usage.sendEvent('code-size-analysis', 'windows')).called(1);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => windowsPlatform,
    FileSystemUtils: () => FileSystemUtils(fileSystem: fileSystem, platform: windowsPlatform),
    Usage: () => usage,
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockVisualStudio extends Mock implements VisualStudio {}
class MockUsage extends Mock implements Usage {}
