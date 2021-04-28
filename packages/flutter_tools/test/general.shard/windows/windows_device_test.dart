// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/windows/application_package.dart';
import 'package:flutter_tools/src/windows/native_api.dart';
import 'package:flutter_tools/src/windows/windows_device.dart';
import 'package:flutter_tools/src/windows/windows_workflow.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  testWithoutContext('WindowsDevice defaults', () async {
    final WindowsDevice windowsDevice = setUpWindowsDevice();
    final PrebuiltWindowsApp windowsApp = PrebuiltWindowsApp(executable: 'foo');

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

  testWithoutContext('WindowsUwpDevice defaults', () async {
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice();
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    expect(await windowsDevice.targetPlatform, TargetPlatform.windows_uwp_x64);
    expect(windowsDevice.name, 'Windows (UWP)');
    expect(await windowsDevice.installApp(package), true);
    expect(await windowsDevice.uninstallApp(package), true);
    expect(await windowsDevice.isLatestBuildInstalled(package), false);
    expect(await windowsDevice.isAppInstalled(package), false);
    expect(windowsDevice.category, Category.desktop);

    expect(windowsDevice.supportsRuntimeMode(BuildMode.debug), true);
    expect(windowsDevice.supportsRuntimeMode(BuildMode.profile), true);
    expect(windowsDevice.supportsRuntimeMode(BuildMode.release), true);
    expect(windowsDevice.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext('WindowsDevices does not list devices if the workflow is unsupported', () async {
    expect(await WindowsDevices(
      windowsWorkflow: WindowsWorkflow(
        featureFlags: TestFeatureFlags(isWindowsEnabled: false),
        platform: FakePlatform(operatingSystem: 'windows'),
      ),
      featureFlags: TestFeatureFlags(isWindowsEnabled: false),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      nativeApi: FakeNativeApi(),
    ).devices, <Device>[]);
  });

  testWithoutContext('WindowsDevices lists a devices if the workflow is supported', () async {
    expect(await WindowsDevices(
      windowsWorkflow: WindowsWorkflow(
        featureFlags: TestFeatureFlags(isWindowsEnabled: true),
        platform: FakePlatform(operatingSystem: 'windows')
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      featureFlags: TestFeatureFlags(isWindowsEnabled: true),
      nativeApi: FakeNativeApi(),
    ).devices, hasLength(1));
  });

  testWithoutContext('WindowsDevices lists a UWP Windows device if feature is enabled', () async {
    final FeatureFlags featureFlags = TestFeatureFlags(isWindowsEnabled: true, isWindowsUwpEnabled: true);
    expect(await WindowsDevices(
      windowsWorkflow: WindowsWorkflow(
        featureFlags: featureFlags,
        platform: FakePlatform(operatingSystem: 'windows')
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      featureFlags: featureFlags,
      nativeApi: FakeNativeApi(),
    ).devices, hasLength(2));
  });

  testWithoutContext('WindowsDevices ignores the timeout provided to discoverDevices', () async {
    final WindowsDevices windowsDevices = WindowsDevices(
      windowsWorkflow: WindowsWorkflow(
        featureFlags: TestFeatureFlags(isWindowsEnabled: true),
        platform: FakePlatform(operatingSystem: 'windows')
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      featureFlags: TestFeatureFlags(isWindowsEnabled: true),
      nativeApi: FakeNativeApi(),
    );
    // Timeout ignored.
    final List<Device> devices = await windowsDevices.discoverDevices(timeout: const Duration(seconds: 10));
    expect(devices, hasLength(1));
  });

  testWithoutContext('isSupportedForProject is true with editable host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsDevice windowsDevice = setUpWindowsDevice(fileSystem: fileSystem);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.directory('windows').createSync();
    fileSystem.file(fileSystem.path.join('windows', 'CMakeLists.txt')).createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(windowsDevice.isSupportedForProject(flutterProject), true);
  });

  testWithoutContext('isSupportedForProject is false with no host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsDevice windowsDevice = setUpWindowsDevice(fileSystem: fileSystem);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(windowsDevice.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('isSupportedForProject is false with no build file', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsDevice windowsDevice = setUpWindowsDevice(fileSystem: fileSystem);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.directory('windows').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(windowsDevice.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('executablePathForDevice uses the correct package executable', () async {
    final WindowsDevice windowsDevice = setUpWindowsDevice();
    final FakeWindowsApp fakeApp = FakeWindowsApp();

    expect(windowsDevice.executablePathForDevice(fakeApp, BuildMode.debug), 'debug/executable');
    expect(windowsDevice.executablePathForDevice(fakeApp, BuildMode.profile), 'profile/executable');
    expect(windowsDevice.executablePathForDevice(fakeApp, BuildMode.release), 'release/executable');
  });

  testWithoutContext('WinUWPDevice can launch application', () async {
    Cache.flutterRoot = '';
    final FakeNativeApi nativeApi = FakeNativeApi();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'powershell.exe',
        'build/winuwp/AppPackages/testapp/testapp_1.2.3.4_Debug_Test/Add-AppDevPackage.ps1',
      ]),
      const FakeCommand(command: <String>[
        'powershell.exe',
        'packages/flutter_tools/bin/getaumidfromname.ps1',
        '-Name',
        '1234'
      ], stdout: 'ABCDEFG'),
    ]);
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(fileSystem: fileSystem, processManager: processManager, nativeApi: nativeApi);
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    final LaunchResult result = await windowsDevice.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      prebuiltApplication: true,
      platformArgs: <String, Object>{},
    );

    expect(result.started, true);
    expect(nativeApi.requests.single.amuid, 'ABCDEFG');
    expect(nativeApi.requests.single.args, <String>[
      '--observatory-port=12345',
      '--disable-service-auth-codes',
      '--enable-dart-profiling',
      '--enable-checked-mode',
      '--verify-entry-points',
    ]);
  });
}

FlutterProject setUpFlutterProject(Directory directory) {
  final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

WindowsDevice setUpWindowsDevice({
  FileSystem fileSystem,
  Logger logger,
  ProcessManager processManager,
}) {
  return WindowsDevice(
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    logger: logger ?? BufferLogger.test(),
    processManager: processManager ?? FakeProcessManager.any(),
    operatingSystemUtils: FakeOperatingSystemUtils(),
  );
}

WindowsUWPDevice setUpWindowsUwpDevice({
  FileSystem fileSystem,
  Logger logger,
  ProcessManager processManager,
  NativeApi nativeApi,
}) {
  return WindowsUWPDevice(
    logger: logger ?? BufferLogger.test(),
    processManager: processManager ?? FakeProcessManager.any(),
    operatingSystemUtils: FakeOperatingSystemUtils(),
    nativeApi: nativeApi ?? FakeNativeApi(),
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
  );
}

class FakeWindowsApp extends Fake implements WindowsApp {
  @override
  String executable(BuildMode buildMode) => '${buildMode.name}/executable';
}

class FakeBuildableUwpApp extends Fake implements BuildableUwpApp {
  @override
  String get id => '1234';
  @override
  String get name => 'testapp';
  @override
  String get projectVersion => '1.2.3.4';
}

class FakeNativeApi implements NativeApi {
  final List<FakeLaunchRequest> requests = <FakeLaunchRequest>[];

  @override
  int launchApp(String amuid, List<String> args) {
    requests.add(FakeLaunchRequest(amuid, args));
    return 0;
  }
}

class FakeLaunchRequest {
  const FakeLaunchRequest(this.amuid, this.args);

  final String amuid;
  final List<String> args;
}