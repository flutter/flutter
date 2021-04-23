// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../cache.dart';
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
    @required ProcessManager processManager,
    @required Logger logger,
    @required NativeApi nativeApi,
    @required OperatingSystemUtils operatingSystemUtils,
  }) : _logger = logger,
       _processManager = processManager,
       _nativeApi = nativeApi,
       _operatingSystemUtils = operatingSystemUtils,
      super(
       'winuwp',
        platformType: PlatformType.windows,
        ephemeral: false,
        category: Category.desktop,
      );

  final ProcessManager _processManager;
  final Logger _logger;
  final NativeApi _nativeApi;
  final OperatingSystemUtils _operatingSystemUtils;

  int _processId;

  @override
  bool isSupported() => true;

  @override
  String get name => 'Windows (UWP)';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.windows_uwp_x64;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    // TODO(flutter): update with detection once FlutterProject knows
    // about the UWP structure.
    return true;
  }

  @override
  void clearLogs() { }

  @override
  Future<void> dispose() async { }

  @override
  Future<String> get emulatorId => null;

  @override
  FutureOr<DeviceLogReader> getLogReader({covariant ApplicationPackage app, bool includePastLogs = false}) {
    return NoOpDeviceLogReader('winuwp');
  }

  @override
  Future<bool> installApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    await _processManager.run(<String>[
      'powershell.exe',
      r'build\winuwp\AppPackages\helloreloaded\helloreloaded_1.1.0.0_Debug_Test\Add-AppDevPackage.ps1'
    ]);
    return true;
  }

  @override
  Future<bool> isAppInstalled(covariant ApplicationPackage app, {String userIdentifier}) async => false;

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) async => false;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => '';

  @override
  Future<LaunchResult> startApp(covariant ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    final FlutterProject project = FlutterProject.current();
    if (!prebuiltApplication) {
      await buildWindowsUwp(
        project.windowsUwp,
        debuggingOptions.buildInfo,
        target: mainPath,
      );
    }
    if (!await isAppInstalled(package)) {
      await installApp(package);
    }

    final String guid = project.windowsUwp.packageGuid;
    if (guid == null) {
      _logger.printError('Could not find PACKAGE_GUID in ${project.windowsUwp.runnerCmakeFile.path}');
      return LaunchResult.failed();
    }
    final ProcessResult result = await _processManager.run(<String>[
      'powershell.exe',
      '${Cache.flutterRoot}\\packages\\flutter_tools\\bin\\getaumidfromname.ps1',
      '-Name', guid,
    ]);
    if (result.exitCode != 0) {
      _logger.printError('Failed to retrieve AUMID for project: ${result.stderr}');
      return LaunchResult.failed();
    }

    final String aumidstring = result.stdout.toString().trim();
    final String pfn = aumidstring.split('!').first;

    if (debuggingOptions.buildInfo.mode.isRelease) {
      _processId = _nativeApi.launchApp(aumidstring, <String>[]);
      return LaunchResult.succeeded();
    }

    /// If the terminal is attached, prompt the user to open the firewall port.
    if (_logger.terminal.stdinHasTerminal) {
      await _logger.terminal.promptForCharInput(<String>['Y', 'y'], logger: _logger,
        prompt: 'To continue start an admin cmd prompt and run the following command:\n'
        '   checknetisolation loopbackexempt -is -n=$pfn\n'
        'Press "y" once this is complete.'
      );
    }

    /// Currently we do not have a way to discover the VM Service URI.
    final int port = debuggingOptions.deviceVmServicePort
        ?? await _operatingSystemUtils.findFreePort();
    _processId = _nativeApi.launchApp(aumidstring, <String>[
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
    ]);
    return LaunchResult.succeeded(observatoryUri: Uri.parse('http://localhost:$port'));
  }

  @override
  Future<bool> stopApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    if (_processId != null) {
      return _processManager.killPid(_processId);
    }
    return false;
  }

  @override
  Future<bool> uninstallApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return true;
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
          logger: _logger,
          processManager: _processManager,
          nativeApi: _nativeApi,
          operatingSystemUtils: _operatingSystemUtils,
        )
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];
}
