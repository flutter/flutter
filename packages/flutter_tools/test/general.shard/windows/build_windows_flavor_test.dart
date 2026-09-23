// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/cmake.dart';
import 'package:flutter_tools/src/cmake_project.dart';
import 'package:flutter_tools/src/commands/build_windows.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/windows/build_windows.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_flutter_command_runner.dart';

const flutterRoot = r'C:\flutter';
const buildFilePath = r'windows\CMakeLists.txt';
const visualStudioPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community';
const String _cmakePath =
    visualStudioPath + r'\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe';
const _defaultGenerator = 'Visual Studio 16 2019';

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'PROGRAMFILES(X86)': r'C:\Program Files (x86)\',
    'FLUTTER_ROOT': flutterRoot,
    'USERPROFILE': '/',
  },
);

void main() {
  late MemoryFileSystem fileSystem;
  late ProcessManager processManager;
  late FakeAnalytics fakeAnalytics;

  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '';
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    Cache.flutterRoot = flutterRoot;
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
  });

  void setUpMockCoreProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  void setUpMockProjectFilesForBuild() {
    fileSystem.file(buildFilePath).createSync(recursive: true);
    setUpMockCoreProjectFiles();
  }

  FakeCommand cmakeGenerationCommand({
    String? flavor,
    TargetPlatform targetPlatform = TargetPlatform.windows_x64,
  }) {
    final String buildDir = flavor != null && flavor.isNotEmpty
        ? r'C:\build\windows\x64\' + flavor
        : r'C:\build\windows\x64';
    return FakeCommand(
      command: <String>[
        _cmakePath,
        '-S',
        fileSystem.path.absolute(fileSystem.path.dirname(buildFilePath)),
        '-B',
        buildDir,
        '-G',
        _defaultGenerator,
        '-A',
        getCmakeWindowsArch(targetPlatform),
        '-DFLUTTER_TARGET_PLATFORM=windows-x64',
      ],
    );
  }

  FakeCommand buildCommand(String buildMode, {String? flavor}) {
    final String buildDir = flavor != null && flavor.isNotEmpty
        ? r'C:\build\windows\x64\' + flavor
        : r'C:\build\windows\x64';
    return FakeCommand(
      command: <String>[
        _cmakePath,
        '--build',
        buildDir,
        '--config',
        buildMode,
        '--target',
        'INSTALL',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Unit tests: getCmakeExecutableName with flavor
  // ---------------------------------------------------------------------------

  group('getCmakeExecutableName', () {
    test('returns the base binary name regardless of flavor', () {
      final File cmakeFile = fileSystem.file('windows/CMakeLists.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('set(BINARY_NAME "myapp")\n');

      final project = FakeCmakeProject(cmakeFile);
      expect(getCmakeExecutableName(project), 'myapp');
    });
  });

  // ---------------------------------------------------------------------------
  // Unit tests: getWindowsBuildDirectory with flavor
  // ---------------------------------------------------------------------------

  group('getWindowsBuildDirectory', () {
    testUsingContext(
      'returns legacy path when no flavor',
      () {
        expect(
          getWindowsBuildDirectory(TargetPlatform.windows_x64),
          endsWith(fileSystem.path.join('windows', 'x64')),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'inserts flavor segment when flavor is set',
      () {
        expect(
          getWindowsBuildDirectory(TargetPlatform.windows_x64, 'apple'),
          endsWith(fileSystem.path.join('windows', 'x64', 'apple')),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Integration test: flutter build windows --flavor apple
  // ---------------------------------------------------------------------------

  testUsingContext(
    'Windows build with --flavor uses a flavor-specific build dir',
    () async {
      final fakeVisualStudio = FakeVisualStudio();
      final command = BuildWindowsCommand(
        logger: BufferLogger.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      )..visualStudioOverride = fakeVisualStudio;
      setUpMockProjectFilesForBuild();

      processManager = FakeProcessManager.list(<FakeCommand>[
        cmakeGenerationCommand(flavor: 'apple'),
        buildCommand('Release', flavor: 'apple'),
      ]);

      await createTestCommandRunner(
        command,
      ).run(const <String>['windows', '--no-pub', '--flavor', 'apple']);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => windowsPlatform,
      FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
      Analytics: () => fakeAnalytics,
    },
  );

  // ---------------------------------------------------------------------------
  // Regression: build without flavor still works (legacy layout)
  // ---------------------------------------------------------------------------

  testUsingContext(
    'Windows build without --flavor uses legacy build dir (no flavor segment)',
    () async {
      final fakeVisualStudio = FakeVisualStudio();
      final command = BuildWindowsCommand(
        logger: BufferLogger.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      )..visualStudioOverride = fakeVisualStudio;
      setUpMockProjectFilesForBuild();

      processManager = FakeProcessManager.list(<FakeCommand>[
        cmakeGenerationCommand(),
        buildCommand('Release'),
      ]);

      await createTestCommandRunner(command).run(const <String>['windows', '--no-pub']);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => windowsPlatform,
      FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
      Analytics: () => fakeAnalytics,
    },
  );
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeVisualStudio extends Fake implements VisualStudio {
  FakeVisualStudio({
    this.cmakePath = _cmakePath,
    this.cmakeGenerator = _defaultGenerator,
    this.displayVersion = '17.0.0',
  });

  @override
  final String? cmakePath;

  @override
  final String? cmakeGenerator;

  @override
  final String displayVersion;

  @override
  bool get isInstalled => true;

  @override
  bool get isAtLeastMinimumVersion => true;

  @override
  bool get hasNecessaryComponents => true;
}

class FakeCmakeProject extends Fake implements CmakeBasedProject {
  FakeCmakeProject(this.cmakeFile);

  @override
  final File cmakeFile;
}
