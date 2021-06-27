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

  // Returns `true` if the specified file is a valid package based on file extension.
  bool _isValidPackage(String packagePath) {
    const List<String> validPackageExtensions = <String>[
      '.appx', '.msix',                // Architecture-specific application.
      '.appxbundle', '.msixbundle',    // Architecture-independent application.
      '.eappx', '.emsix',              // Encrypted architecture-specific application.
      '.eappxbundle', '.emsixbundle',  // Encrypted architecture-independent application.
    ];
    return validPackageExtensions.any(packagePath.endsWith);
  }

  // Walks the build directory for any dependent packages for the specified architecture.
  List<String> _getPackagePaths(String directory) {
    if (!_fileSystem.isDirectorySync(directory)) {
      return <String>[];
    }
    final List<String> packagePaths = <String>[];
    for (final FileSystemEntity entity in _fileSystem.directory(directory).listSync()) {
      if (entity.statSync().type != FileSystemEntityType.file) {
        continue;
      }
      final String packagePath = entity.absolute.path;
      if (_isValidPackage(packagePath)) {
        packagePaths.add(packagePath);
      }
    }
    return packagePaths;
  }

  // Walks the build directory for any dependent packages for the specified architecture.
  String/*?*/ _getAppPackagePath(String buildDirectory) {
    final List<String> packagePaths = _getPackagePaths(buildDirectory);
    return packagePaths.isNotEmpty ? packagePaths.first : null;
  }

  // Walks the build directory for any dependent packages for the specified architecture.
  List<String> _getDependencyPaths(String buildDirectory, String architecture) {
    final String depsDirectory = _fileSystem.path.join(buildDirectory, 'Dependencies', architecture);
    return _getPackagePaths(depsDirectory);
  }

  String _getPackageName(String binaryName, String version, String config, {String/*?*/ architecture}) {
    final List<String> components = <String>[
      binaryName,
      version,
      if (architecture != null) architecture,
      config,
    ];
    return components.join('_');
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
    final String binaryDir = _fileSystem.path.absolute(
        _fileSystem.path.join('build', 'winuwp', 'runner_uwp', 'AppPackages', binaryName));
    final String config = toTitleCase(getNameForBuildMode(_buildMode ?? BuildMode.debug));

    // If a multi-architecture package exists, install that; otherwise install
    // the single-architecture package.
    final List<String> packageNames = <String>[
      // Multi-archtitecture package.
      _getPackageName(binaryName, packageVersion, config),
      // Single-archtitecture package.
      _getPackageName(binaryName, packageVersion, config, architecture: 'x64'),
    ];
    String packageName;
    String buildDirectory;
    String packagePath;
    for (final String name in packageNames) {
      packageName = name;
      buildDirectory = _fileSystem.path.join(binaryDir, '${packageName}_Test');
      if (_fileSystem.isDirectorySync(buildDirectory)) {
        packagePath = _getAppPackagePath(buildDirectory);
        if (packagePath != null && _fileSystem.isFileSync(packagePath)) {
          break;
        }
      }
    }
    if (packagePath == null) {
      _logger.printError('Failed to locate app package to install');
      return false;
    }

    // Verify package signature.
    if (!await _uwptool.isSignatureValid(packagePath)) {
      // If signature is invalid, install the developer certificate.
      final String certificatePath = _fileSystem.path.join(buildDirectory, '$packageName.cer');
      if (_logger.terminal.stdinHasTerminal) {
        final String response = await _logger.terminal.promptForCharInput(
          <String>['Y', 'y', 'N', 'n'],
          logger: _logger,
          prompt: 'Install developer certificate.\n'
          '\n'
          'Windows UWP apps are signed with a developer certificate during the build\n'
          'process. On the first install of an app with a signature from a new\n'
          'certificate, the certificate must be installed.\n'
          '\n'
          'If desired, this certificate can later be removed by launching the \n'
          '"Manage Computer Certificates" control panel from the Start menu and deleting\n'
          'the "CMake Test Cert" certificate from the "Trusted People" > "Certificates"\n'
          'section.\n'
          '\n'
          'Press "Y" to continue, or "N" to cancel.',
          displayAcceptedCharacters: false,
        );
        if (response == 'N' || response == 'n') {
          return false;
        }
      }
      await _uwptool.installCertificate(certificatePath);
    }

    // Install the application and dependencies.
    final String packageUri = Uri.file(packagePath).toString();
    final List<String> dependencyUris = _getDependencyPaths(buildDirectory, 'x64')
        .map((String path) => Uri.file(path).toString())
        .toList();
    return _uwptool.installApp(packageUri, dependencyUris);
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
    if (await isAppInstalled(package) && !await uninstallApp(package)) {
      _logger.printError('Failed to uninstall previous app package');
      return LaunchResult.failed();
    }
    if (!await installApp(package)) {
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
      final String response = await _logger.terminal.promptForCharInput(
        <String>['Y', 'y', 'N', 'n'],
        logger: _logger,
        prompt: 'Enable Flutter debugging from localhost.\n'
        '\n'
        'Windows UWP apps run in a sandboxed environment. To enable Flutter debugging\n'
        'and hot reload, you will need to enable inbound connections to the app from the\n'
        'Flutter tool running on your machine. To do so:\n'
        '  1. Launch PowerShell as an Administrator\n'
        '  2. Enter the following command:\n'
        '     checknetisolation loopbackexempt -is -n=$packageFamily\n'
        '\n'
        'Press "Y" once this is complete, or "N" to abort.',
        displayAcceptedCharacters: false,
      );
      if (response == 'N' || response == 'n') {
        return LaunchResult.failed();
      }
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
      if (debuggingOptions.traceSkiaAllowlist != null) '--trace-skia-allowlist="${debuggingOptions.traceSkiaAllowlist}"',
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

  @override
  List<String> get wellKnownIds => const <String>['windows', 'winuwp'];
}
