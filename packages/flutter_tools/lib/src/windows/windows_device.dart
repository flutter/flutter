// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../features.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_windows.dart';
import 'native_api.dart';
import 'windows_workflow.dart';

/// A device that represents a desktop Windows target.
class WindowsDevice extends DesktopDevice {
  WindowsDevice({
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
  }) : super(
      'windows',
      platformType: PlatformType.windows,
      ephemeral: false,
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      operatingSystemUtils: operatingSystemUtils,
  );

  @override
  bool isSupported() => true;

  @override
  String get name => 'Windows';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.windows.existsSync();
  }

  @override
  Future<void> buildForDevice(
    covariant WindowsApp package, {
    String mainPath,
    BuildInfo buildInfo,
  }) async {
    await buildWindows(
      FlutterProject.current().windows,
      buildInfo,
      target: mainPath,
    );
  }

  @override
  String executablePathForDevice(covariant WindowsApp package, BuildMode buildMode) {
    return package.executable(buildMode);
  }
}

// A device that represents a desktop Windows UWP target.
class WindowsUWPDevice extends Device {
  WindowsUWPDevice({
    @required Logger logger,
    @required NativeApi nativeApi,
    @required ProcessManager processManager,
  }) : _logger = logger,
       _nativeApi = nativeApi,
       _processManager = processManager,
       super(
        'windows-uwp',
        platformType: PlatformType.windows,
        ephemeral: false,
        category: Category.desktop,
      );

  final Logger _logger;
  final NativeApi _nativeApi;
  final ProcessManager _processManager;

  ApplicationInstance _applicationInstance;
  Process _loopback;

  @override
  bool isSupported() => false;

  @override
  String get name => 'Windows (UWP)';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_uwp_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    // TODO(flutter): update with detection once FlutterProject knows
    // about the UWP structure.
    return false;
  }

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isAppInstalled(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> installApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to uninstall the application.
  @override
  Future<bool> uninstallApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => 'winuwp';

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;

  @override
  DeviceLogReader getLogReader({
    ApplicationPackage app,
    bool includePastLogs = false,
  }) {
    return NoOpDeviceLogReader('winuwp');
  }

  @override
  void clearLogs() {}

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    @required DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs = const <String, dynamic>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    if (!prebuiltApplication) {
      await buildWindows(
        FlutterProject.current().windows,
        debuggingOptions.buildInfo,
        target: mainPath,
      );
    }
    final BuildMode buildMode = debuggingOptions?.buildInfo?.mode;
    final String amuid = _amuidForApplication(package, buildMode);
    if (amuid == null) {
      _logger.printError('Unable to find executable to run');
      return LaunchResult.failed();
    }
    /// This attempts to open an elevated command prompt to open
    /// the firewall to allow the tool and the UWP device to connect. This will require
    /// the use to accept a command prompt to allow the operation.
    _loopback = await _processManager.start(<String>[
      r'C:\Users\Jonah\flutter\packages\flutter_tools\bin\port-opener.bat', amuid,
    ]);

    _applicationInstance = _nativeApi.launchApp(amuid);
    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async {
    if (_applicationInstance != null) {
      _applicationInstance.dispose();
      _applicationInstance = null;
      return true;
    }
    return false;
  }

  @override
  Future<void> dispose() async {
    await portForwarder?.dispose();
    _loopback?.kill();
  }

  String _amuidForApplication(ApplicationPackage package, BuildMode buildMode) {
    return 'abcd';
    throw UnsupportedError('Not currently known how to look up AMUID for winuwp devices.');
  }
}

class WindowsDevices extends PollingDeviceDiscovery {
  WindowsDevices({
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
    @required WindowsWorkflow windowsWorkflow,
    @required FeatureFlags featureFlags,
    @required NativeApi nativeApi,
  }) : _fileSystem = fileSystem,
      _logger = logger,
      _processManager = processManager,
      _operatingSystemUtils = operatingSystemUtils,
      _windowsWorkflow = windowsWorkflow,
      _featureFlags = featureFlags,
      _nativeApi = nativeApi,
      super('windows devices');

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;
  final WindowsWorkflow _windowsWorkflow;
  final FeatureFlags _featureFlags;
  final NativeApi _nativeApi;

  @override
  bool get supportsPlatform => _windowsWorkflow.appliesToHostPlatform;

  @override
  bool get canListAnything => _windowsWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      WindowsDevice(
        fileSystem: _fileSystem,
        logger: _logger,
        processManager: _processManager,
        operatingSystemUtils: _operatingSystemUtils,
      ),
      if (_featureFlags.isWindowsUwpEnabled)
        WindowsUWPDevice(
          nativeApi: _nativeApi,
          logger: _logger,
          processManager: _processManager,
        )
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
