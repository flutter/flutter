// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/windows/application_package.dart';
import 'package:flutter_tools/src/windows/windows_device.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';

void main() {
  testWithoutContext('WindowsDevice defaults', () async {
    final WindowsDevice windowsDevice = setUpWindowsDevice();
    final File dummyFile = MemoryFileSystem.test().file('dummy');
    final windowsApp = PrebuiltWindowsApp(executable: 'foo', applicationPackage: dummyFile);

    expect(await windowsDevice.targetPlatform, TargetPlatform.windows_x64);
    expect(windowsDevice.name, 'Windows');
    expect(await windowsDevice.installApp(windowsApp), true);
    expect(await windowsDevice.uninstallApp(windowsApp), true);
    expect(await windowsDevice.isLatestBuildInstalled(windowsApp), true);
    expect(await windowsDevice.isAppInstalled(windowsApp), true);
    expect(windowsDevice.category, Category.desktop);

    expect(windowsDevice.supportsRuntimeMode(BuildMode.debug), true);
    expect(windowsDevice.supportsRuntimeMode(BuildMode.profile), true);
    expect(windowsDevice.supportsRuntimeMode(BuildMode.release), true);
    expect(windowsDevice.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext(
    'WindowsDevices does not list devices if the workflow is unsupported',
    () async {
      expect(
        await WindowsDevices(
          analytics: const NoOpAnalytics(),
          windowsWorkflow: WindowsWorkflow(
            featureFlags: TestFeatureFlags(),
            platform: FakePlatform(operatingSystem: 'windows'),
          ),
          toolContext: FakeToolContext(
            fs: MemoryFileSystem.test(),
            logger: BufferLogger.test(),
            os: FakeOperatingSystemUtils(),
            processManager: FakeProcessManager.any(),
          ),
        ).devices(),
        <Device>[],
      );
    },
  );

  testWithoutContext('WindowsDevices lists a devices if the workflow is supported', () async {
    expect(
      await WindowsDevices(
        analytics: const NoOpAnalytics(),
        windowsWorkflow: WindowsWorkflow(
          featureFlags: TestFeatureFlags(isWindowsEnabled: true),
          platform: FakePlatform(operatingSystem: 'windows'),
        ),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(),
          processManager: FakeProcessManager.any(),
        ),
      ).devices(),
      hasLength(1),
    );
  });

  testWithoutContext('isSupportedForProject is true with editable host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsDevice windowsDevice = setUpWindowsDevice(fileSystem: fileSystem);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('windows').createSync();
    fileSystem.file(fileSystem.path.join('windows', 'CMakeLists.txt')).createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(windowsDevice.isSupportedForProject(flutterProject), true);
  });

  testWithoutContext('isSupportedForProject is false with no host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsDevice windowsDevice = setUpWindowsDevice(fileSystem: fileSystem);
    fileSystem.file('pubspec.yaml').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(windowsDevice.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('isSupportedForProject is false with no build file', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsDevice windowsDevice = setUpWindowsDevice(fileSystem: fileSystem);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('windows').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(windowsDevice.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('executablePathForDevice uses the correct package executable', () async {
    final WindowsDevice windowsDevice = setUpWindowsDevice();
    final fakeApp = FakeWindowsApp();

    expect(windowsDevice.executablePathForDevice(fakeApp, BuildInfo.debug), 'debug/executable');
    expect(windowsDevice.executablePathForDevice(fakeApp, BuildInfo.profile), 'profile/executable');
    expect(windowsDevice.executablePathForDevice(fakeApp, BuildInfo.release), 'release/executable');
  });

  group('WindowsDevice.buildForDevice', () {
    late MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
    });

    testUsingContext(
      'sends timing events to analytics',
      () async {
        Cache.flutterRoot = r'C:\flutter';
        fileSystem.file('pubspec.yaml').createSync();
        writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
        fileSystem
            .file(fileSystem.path.join('windows', 'CMakeLists.txt'))
            .createSync(recursive: true);
        const vsPath = r'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community';
        const cmakePath =
            '$vsPath'
            r'\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe';
        const vswherePath = r'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe';
        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: fileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );
        final processManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>[
              vswherePath,
              '-format',
              'json',
              '-products',
              '*',
              '-utf8',
              '-latest',
              '-version',
              '16',
              '-requires',
              'Microsoft.VisualStudio.Workload.NativeDesktop',
              'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
              'Microsoft.VisualStudio.Component.VC.CMake.Project',
            ],
            stdout:
                '[{"installationPath": ${jsonEncode(vsPath)}, "installationVersion": "16.11.0.0", "displayName": "Visual Studio Community 2019", "catalog": {"productDisplayVersion": "16.11.0"}}]',
          ),
          const FakeCommand(
            command: <String>[
              cmakePath,
              '-S',
              r'C:\windows',
              '-B',
              r'C:\build\windows\x64',
              '-G',
              'Visual Studio 16 2019',
              '-A',
              'x64',
              '-DFLUTTER_TARGET_PLATFORM=windows-x64',
            ],
          ),
          const FakeCommand(
            command: <String>[
              cmakePath,
              '--build',
              r'C:\build\windows\x64',
              '--config',
              'Debug',
              '--target',
              'INSTALL',
            ],
          ),
        ]);
        final device = WindowsDevice(
          analytics: fakeAnalytics,
          toolContext: FakeToolContext(
            fs: fileSystem,
            logger: BufferLogger.test(),
            os: FakeOperatingSystemUtils(),
            platform: FakePlatform(
              operatingSystem: 'windows',
              environment: <String, String>{
                'PROGRAMFILES(X86)': r'C:\Program Files (x86)\',
                'FLUTTER_ROOT': r'C:\flutter',
              },
            ),
            processManager: processManager,
          ),
        );

        await device.buildForDevice(buildInfo: BuildInfo.debug);

        expect(processManager.hasRemainingExpectations, isFalse);
        expect(
          analyticsTimingEventExists(
            sentEvents: fakeAnalytics.sentEvents,
            workflow: 'build',
            variableName: 'windows-cmake-generation',
          ),
          true,
        );
        expect(
          analyticsTimingEventExists(
            sentEvents: fakeAnalytics.sentEvents,
            workflow: 'build',
            variableName: 'windows-cmake-build',
          ),
          true,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.empty(),
      },
    );
  });
}

FlutterProject setUpFlutterProject(Directory directory) {
  final flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

WindowsDevice setUpWindowsDevice({
  FileSystem? fileSystem,
  Logger? logger,
  ProcessManager? processManager,
}) {
  return WindowsDevice(
    analytics: const NoOpAnalytics(),
    toolContext: FakeToolContext(
      fs: fileSystem ?? MemoryFileSystem.test(),
      logger: logger ?? BufferLogger.test(),
      os: FakeOperatingSystemUtils(),
      processManager: processManager ?? FakeProcessManager.any(),
    ),
  );
}

class FakeWindowsApp extends Fake implements WindowsApp {
  @override
  String executable(BuildMode buildMode, TargetPlatform targetPlatform, [String? flavor]) =>
      '${buildMode.cliName}/executable';
}
