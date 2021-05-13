// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../features.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_windows.dart';
import 'uwptool.dart';
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
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
    @required UwpTool uwptool,
  }) : _logger = logger,
       _processManager = processManager,
       _operatingSystemUtils = operatingSystemUtils,
       _fileSystem = fileSystem,
       _uwptool = uwptool,
       super(
         'winuwp',
         platformType: PlatformType.windows,
         ephemeral: false,
         category: Category.desktop,
       );

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _operatingSystemUtils;
  final UwpTool _uwptool;
  BuildMode _buildMode;

  int _processId;

  @override
  bool isSupported() => true;

  @override
  String get name => 'Windows (UWP)';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_uwp_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.windowsUwp.existsSync();
  }

  @override
  void clearLogs() { }

  @override
  Future<void> dispose() async { }

  @override
  Future<String> get emulatorId => null;

  @override
  FutureOr<DeviceLogReader> getLogReader({covariant BuildableUwpApp app, bool includePastLogs = false}) {
    return NoOpDeviceLogReader('winuwp');
  }

  @override
  Future<bool> installApp(covariant BuildableUwpApp app, {String userIdentifier}) async {
    /// The cmake build generates an install powershell script.
    /// build\winuwp\runner_uwp\AppPackages\<app-name>\<app-name>_<app-version>_<cmake-config>\Add-AppDevPackage.ps1
    final String binaryName = app.name;
    final String packageVersion = app.projectVersion;
    if (packageVersion == null) {
      return false;
    }
    final String config = toTitleCase(getNameForBuildMode(_buildMode ?? BuildMode.debug));
    final String generated = '${binaryName}_${packageVersion}_${config}_Test';
    final String buildDirectory = _fileSystem.path.join(
        'build', 'winuwp', 'runner_uwp', 'AppPackages', binaryName, generated);
    return _uwptool.installApp(buildDirectory);
  }

  @override
  Future<bool> isAppInstalled(covariant ApplicationPackage app, {String userIdentifier}) async {
    final String packageName = app.id;
    return await _uwptool.getPackageFamilyName(packageName) != null;
  }

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) async => false;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => '';

  @override
  Future<LaunchResult> startApp(covariant BuildableUwpApp package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    _buildMode = debuggingOptions.buildInfo.mode;
    if (!prebuiltApplication) {
      await buildWindowsUwp(
        package.project,
        debuggingOptions.buildInfo,
        target: mainPath,
      );
    }
    if (!await isAppInstalled(package) && !await installApp(package)) {
      _logger.printError('Failed to install app package');
      return LaunchResult.failed();
    }

    final String packageName = package.id;
    if (packageName == null) {
      _logger.printError('Could not find PACKAGE_GUID in ${package.project.runnerCmakeFile.path}');
      return LaunchResult.failed();
    }

    final String packageFamily = await _uwptool.getPackageFamilyName(packageName);

    if (debuggingOptions.buildInfo.mode.isRelease) {
      _processId = await _uwptool.launchApp(packageFamily, <String>[]);
      return _processId != null ? LaunchResult.succeeded() : LaunchResult.failed();
    }

    /// If the terminal is attached, prompt the user to open the firewall port.
    if (_logger.terminal.stdinHasTerminal) {
      await _logger.terminal.promptForCharInput(<String>['Y', 'y'], logger: _logger,
        prompt: 'To continue start an admin cmd prompt and run the following command:\n'
        '   checknetisolation loopbackexempt -is -n=$packageFamily\n'
        'Press "Y/y" once this is complete.'
      );
    }

    /// Currently we do not have a way to discover the VM Service URI.
    final int port = debuggingOptions.deviceVmServicePort ?? await _operatingSystemUtils.findFreePort();
    final List<String> args = <String>[
      '--observatory-port=$port',
      '--disable-service-auth-codes',
      '--enable-dart-profiling',
      if (debuggingOptions.startPaused) '--start-paused',
      if (debuggingOptions.useTestFonts) '--use-test-fonts',
      if (debuggingOptions.debuggingEnabled) ...<String>[
        '--enable-checked-mode',
        '--verify-entry-points',
      ],
      if (debuggingOptions.enableSoftwareRendering) '--enable-software-rendering',
      if (debuggingOptions.skiaDeterministicRendering) '--skia-deterministic-rendering',
      if (debuggingOptions.traceSkia) '--trace-skia',
      if (debuggingOptions.traceAllowlist != null) '--trace-allowlist="${debuggingOptions.traceAllowlist}"',
      if (debuggingOptions.endlessTraceBuffer) '--endless-trace-buffer',
      if (debuggingOptions.dumpSkpOnShaderCompilation) '--dump-skp-on-shader-compilation',
      if (debuggingOptions.verboseSystemLogs) '--verbose-logging',
      if (debuggingOptions.cacheSkSL) '--cache-sksl',
      if (debuggingOptions.purgePersistentCache) '--purge-persistent-cache',
      if (platformArgs['trace-startup'] as bool ?? false) '--trace-startup',
    ];
    _processId = await _uwptool.launchApp(packageFamily, args);
    if (_processId == null) {
      return LaunchResult.failed();
    }
    return LaunchResult.succeeded(observatoryUri: Uri.parse('http://localhost:$port'));
  }

  @override
  Future<bool> stopApp(covariant BuildableUwpApp app, {String userIdentifier}) async {
    if (_processId != null) {
      return _processManager.killPid(_processId);
    }
    return false;
  }

  @override
  Future<bool> uninstallApp(covariant BuildableUwpApp app, {String userIdentifier}) async {
    final String packageName = app.id;
    if (packageName == null) {
      _logger.printError('Could not find PACKAGE_GUID in ${app.project.runnerCmakeFile.path}');
      return false;
    }
    final String packageFamily = await _uwptool.getPackageFamilyName(packageName);
    if (packageFamily == null) {
      // App is not installed.
      return true;
    }
    return _uwptool.uninstallApp(packageFamily);
  }

  @override
  FutureOr<bool> supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;
}

class WindowsDevices extends PollingDeviceDiscovery {
  WindowsDevices({
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required OperatingSystemUtils operatingSystemUtils,
    @required WindowsWorkflow windowsWorkflow,
    @required FeatureFlags featureFlags,
    @required UwpTool uwptool,
  }) : _fileSystem = fileSystem,
      _logger = logger,
      _processManager = processManager,
      _operatingSystemUtils = operatingSystemUtils,
      _windowsWorkflow = windowsWorkflow,
      _featureFlags = featureFlags,
      _uwptool = uwptool,
      super('windows devices');

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;
  final WindowsWorkflow _windowsWorkflow;
  final FeatureFlags _featureFlags;
  final UwpTool _uwptool;

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
          fileSystem: _fileSystem,
          logger: _logger,
          processManager: _processManager,
          operatingSystemUtils: _operatingSystemUtils,
          uwptool: _uwptool,
        )
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
