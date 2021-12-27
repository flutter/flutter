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
import 'package:flutter_tools/src/windows/uwptool.dart';
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
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
        fileSystem: fileSystem,
        uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    final String packagePath = fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    );
    fileSystem.file(packagePath).createSync(recursive:true);
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
        featureFlags: TestFeatureFlags(),
        platform: FakePlatform(operatingSystem: 'windows'),
      ),
      featureFlags: TestFeatureFlags(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      uwptool: FakeUwpTool(),
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
      uwptool: FakeUwpTool(),
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
      uwptool: FakeUwpTool(),
    ).devices, hasLength(2));
  });

  testWithoutContext('WindowsDevices has windows and winuwp well known devices', () async {
    final FeatureFlags featureFlags = TestFeatureFlags(isWindowsEnabled: true, isWindowsUwpEnabled: true);
    expect(WindowsDevices(
      windowsWorkflow: WindowsWorkflow(
        featureFlags: featureFlags,
        platform: FakePlatform(operatingSystem: 'windows')
      ),
      operatingSystemUtils: FakeOperatingSystemUtils(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      featureFlags: featureFlags,
      uwptool: FakeUwpTool(),
    ).wellKnownIds, <String>['windows', 'winuwp']);
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
      uwptool: FakeUwpTool(),
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

  testWithoutContext('WinUWPDevice installs cert if not installed', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    uwptool.hasValidSignature = false;
    final String packagePath = fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    );
    fileSystem.file(packagePath).createSync(recursive:true);
    final bool result = await windowsDevice.installApp(package);

    expect(result, isTrue);
    expect(uwptool.installCertRequests, hasLength(1));
    expect(uwptool.installAppRequests, hasLength(1));
  });

  testWithoutContext('WinUWPDevice does not install cert if not installed', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    uwptool.hasValidSignature = true;
    final String packagePath = fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    );
    fileSystem.file(packagePath).createSync(recursive:true);
    final bool result = await windowsDevice.installApp(package);

    expect(result, isTrue);
    expect(uwptool.installCertRequests, isEmpty);
    expect(uwptool.installAppRequests, hasLength(1));
  });

  testWithoutContext('WinUWPDevice prefers installing multi-arch binaries', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    final String singleArchPath = fileSystem.path.absolute(fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    ));
    fileSystem.file(singleArchPath).createSync(recursive:true);
    final String multiArchPath = fileSystem.path.absolute(fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_Debug_Test', 'testapp_1.2.3.4_Debug.msix',
    ));
    fileSystem.file(multiArchPath).createSync(recursive:true);
    final bool result = await windowsDevice.installApp(package);

    expect(result, isTrue);
    expect(uwptool.installAppRequests.single.packageUri, Uri.file(multiArchPath).toString());
  });

  testWithoutContext('WinUWPDevice falls back to installing single-arch binaries', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    final String singleArchPath = fileSystem.path.absolute(fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    ));
    fileSystem.file(singleArchPath).createSync(recursive:true);
    final bool result = await windowsDevice.installApp(package);

    expect(result, isTrue);
    expect(uwptool.installAppRequests.single.packageUri, Uri.file(singleArchPath).toString());
  });

  testWithoutContext('WinUWPDevice can launch application if cert is installed', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    uwptool.hasValidSignature = true;
    final String packagePath = fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    );
    fileSystem.file(packagePath).createSync(recursive:true);
    final LaunchResult result = await windowsDevice.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      prebuiltApplication: true,
      platformArgs: <String, Object>{},
    );

    expect(result.started, true);
    expect(uwptool.installCertRequests, isEmpty);
    expect(uwptool.launchAppRequests.single.packageFamily, 'PACKAGE-ID_publisher');
    expect(uwptool.launchAppRequests.single.args, <String>[
      '--observatory-port=12345',
      '--disable-service-auth-codes',
      '--enable-dart-profiling',
      '--enable-checked-mode',
      '--verify-entry-points',
    ]);
  });

  testWithoutContext('WinUWPDevice installs cert and can launch application if cert not installed', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    uwptool.hasValidSignature = false;
    final String packagePath = fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Debug_Test', 'testapp_1.2.3.4_x64_Debug.msix',
    );
    fileSystem.file(packagePath).createSync(recursive:true);
    final LaunchResult result = await windowsDevice.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      prebuiltApplication: true,
      platformArgs: <String, Object>{},
    );

    expect(result.started, true);
    expect(uwptool.installCertRequests, isNotEmpty);
    expect(uwptool.launchAppRequests.single.packageFamily, 'PACKAGE-ID_publisher');
    expect(uwptool.launchAppRequests.single.args, <String>[
      '--observatory-port=12345',
      '--disable-service-auth-codes',
      '--enable-dart-profiling',
      '--enable-checked-mode',
      '--verify-entry-points',
    ]);
  });

  testWithoutContext('WinUWPDevice can launch application in release mode', () async {
    Cache.flutterRoot = '';
    final FakeUwpTool uwptool = FakeUwpTool();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final WindowsUWPDevice windowsDevice = setUpWindowsUwpDevice(
      fileSystem: fileSystem,
      uwptool: uwptool,
    );
    final FakeBuildableUwpApp package = FakeBuildableUwpApp();

    final String packagePath = fileSystem.path.join(
      'build', 'winuwp', 'runner_uwp', 'AppPackages', 'testapp',
      'testapp_1.2.3.4_x64_Release_Test', 'testapp_1.2.3.4_x64_Release.msix',
    );
    fileSystem.file(packagePath).createSync(recursive:true);
    final LaunchResult result = await windowsDevice.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      prebuiltApplication: true,
      platformArgs: <String, Object>{},
    );

    expect(result.started, true);
    expect(uwptool.launchAppRequests.single.packageFamily, 'PACKAGE-ID_publisher');
    expect(uwptool.launchAppRequests.single.args, <String>[]);
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
  UwpTool uwptool,
}) {
  return WindowsUWPDevice(
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    logger: logger ?? BufferLogger.test(),
    processManager: processManager ?? FakeProcessManager.any(),
    operatingSystemUtils: FakeOperatingSystemUtils(),
    uwptool: uwptool ?? FakeUwpTool(),
  );
}

class FakeWindowsApp extends Fake implements WindowsApp {
  @override
  String executable(BuildMode buildMode) => '${buildMode.name}/executable';
}

class FakeBuildableUwpApp extends Fake implements BuildableUwpApp {
  @override
  String get id => 'PACKAGE-ID';
  @override
  String get name => 'testapp';
  @override
  String get projectVersion => '1.2.3.4';

  // Test helper to get the expected package family.
  static const String packageFamily = 'PACKAGE-ID_publisher';
}

class FakeUwpTool implements UwpTool {
  bool isInstalled = false;
  bool hasValidSignature = false;
  final List<_GetPackageFamilyRequest> getPackageFamilyRequests = <_GetPackageFamilyRequest>[];
  final List<_LaunchAppRequest> launchAppRequests = <_LaunchAppRequest>[];
  final List<_InstallCertRequest> installCertRequests = <_InstallCertRequest>[];
  final List<_InstallAppRequest> installAppRequests = <_InstallAppRequest>[];
  final List<_UninstallAppRequest> uninstallAppRequests = <_UninstallAppRequest>[];

  @override
  Future<List<String>> listApps() async {
    return isInstalled ? <String>[FakeBuildableUwpApp.packageFamily] : <String>[];
  }

  @override
  Future<String/*?*/> getPackageFamilyName(String packageName) async {
    getPackageFamilyRequests.add(_GetPackageFamilyRequest(packageName));
    return isInstalled ? FakeBuildableUwpApp.packageFamily : null;
  }

  @override
  Future<int/*?*/> launchApp(String packageFamily, List<String> args) async {
    launchAppRequests.add(_LaunchAppRequest(packageFamily, args));
    return 42;
  }

  @override
  Future<bool> isSignatureValid(String packagePath) async {
    return hasValidSignature;
  }

  @override
  Future<bool> installCertificate(String certificatePath) async {
    installCertRequests.add(_InstallCertRequest(certificatePath));
    return true;
  }

  @override
  Future<bool> installApp(String packageUri, List<String> dependencyUris) async {
    installAppRequests.add(_InstallAppRequest(packageUri, dependencyUris));
    isInstalled = true;
    return true;
  }

  @override
  Future<bool> uninstallApp(String packageFamily) async {
    uninstallAppRequests.add(_UninstallAppRequest(packageFamily));
    isInstalled = false;
    return true;
  }
}

class _GetPackageFamilyRequest {
  const _GetPackageFamilyRequest(this.packageId);

  final String packageId;
}

class _LaunchAppRequest {
  const _LaunchAppRequest(this.packageFamily, this.args);

  final String packageFamily;
  final List<String> args;
}

class _InstallCertRequest {
  const _InstallCertRequest(this.certificatePath);

  final String certificatePath;
}


class _InstallAppRequest {
  const _InstallAppRequest(this.packageUri, this.dependencyUris);

  final String packageUri;
  final List<String> dependencyUris;
}

class _UninstallAppRequest {
  const _UninstallAppRequest(this.packageFamily);

  final String packageFamily;
}
