// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../bundle_builder.dart';
import '../desktop_device.dart';
import '../devfs.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import '../version.dart';

class FlutterTesterApp extends ApplicationPackage {
  factory FlutterTesterApp.fromCurrentDirectory(FileSystem fileSystem) {
    return FlutterTesterApp._(fileSystem.currentDirectory);
  }

  FlutterTesterApp._(Directory directory)
    : _directory = directory,
      super(id: directory.path);

  final Directory _directory;

  @override
  String get name => _directory.basename;
}

/// The device interface for running on the flutter_tester shell.
///
/// Normally this is only used as the runner for `flutter test`, but it can
/// also be used as a regular device when `--show-test-device` is provided
/// to the flutter command.
class FlutterTesterDevice extends Device {
  FlutterTesterDevice(String deviceId, {
    required ProcessManager processManager,
    required FlutterVersion flutterVersion,
    required Logger logger,
    required FileSystem fileSystem,
    required Artifacts artifacts,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _processManager = processManager,
       _flutterVersion = flutterVersion,
       _logger = logger,
       _fileSystem = fileSystem,
       _artifacts = artifacts,
       _operatingSystemUtils = operatingSystemUtils,
       super(
        deviceId,
        platformType: null,
        category: null,
        ephemeral: false,
      );

  final ProcessManager _processManager;
  final FlutterVersion _flutterVersion;
  final Logger _logger;
  final FileSystem _fileSystem;
  final Artifacts _artifacts;
  final OperatingSystemUtils _operatingSystemUtils;

  Process? _process;
  final DevicePortForwarder _portForwarder = const NoOpDevicePortForwarder();

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  String get name => 'Flutter test device';

  @override
  DevicePortForwarder get portForwarder => _portForwarder;

  @override
  Future<String> get sdkNameAndVersion async {
    final FlutterVersion flutterVersion = _flutterVersion;
    return 'Flutter ${flutterVersion.frameworkRevisionShort}';
  }

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode == BuildMode.debug;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.tester;

  @override
  void clearLogs() { }

  final DesktopLogReader _logReader = DesktopLogReader();

  @override
  DeviceLogReader getLogReader({
    ApplicationPackage? app,
    bool includePastLogs = false,
  }) {
    return _logReader;
  }

  @override
  Future<bool> installApp(
    ApplicationPackage app, {
    String? userIdentifier,
  }) async => true;

  @override
  Future<bool> isAppInstalled(
    ApplicationPackage app, {
    String? userIdentifier,
  }) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    final BuildInfo buildInfo = debuggingOptions.buildInfo;
    if (!buildInfo.isDebug) {
      _logger.printError('This device only supports debug mode.');
      return LaunchResult.failed();
    }

    final Directory assetDirectory = _fileSystem.systemTempDirectory
      .createTempSync('flutter_tester.');
    final String applicationKernelFilePath = getKernelPathForTransformerOptions(
      _fileSystem.path.join(assetDirectory.path, 'flutter-tester-app.dill'),
      trackWidgetCreation: buildInfo.trackWidgetCreation,
    );

    // Build assets and perform initial compilation.
    await BundleBuilder().build(
      buildInfo: buildInfo,
      mainPath: mainPath,
      applicationKernelFilePath: applicationKernelFilePath,
      platform: getTargetPlatformForName(getNameForHostPlatform(_operatingSystemUtils.hostPlatform)),
      assetDirPath: assetDirectory.path,
    );

    final List<String> command = <String>[
      _artifacts.getArtifactPath(Artifact.flutterTester),
      '--run-forever',
      '--non-interactive',
      '--enable-dart-profiling',
      '--packages=${debuggingOptions.buildInfo.packagesPath}',
      '--flutter-assets-dir=${assetDirectory.path}',
      if (debuggingOptions.startPaused)
        '--start-paused',
      if (debuggingOptions.disableServiceAuthCodes)
        '--disable-service-auth-codes',
      if (debuggingOptions.hasObservatoryPort)
        '--observatory-port=${debuggingOptions.hostVmServicePort}',
      applicationKernelFilePath
    ];

    ProtocolDiscovery? observatoryDiscovery;
    try {
      _logger.printTrace(command.join(' '));
      _process = await _processManager.start(command,
        environment: <String, String>{
          'FLUTTER_TEST': 'true',
        },
      );
      if (!debuggingOptions.debuggingEnabled) {
        return LaunchResult.succeeded();
      }

      observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(),
        hostPort: debuggingOptions.hostVmServicePort,
        devicePort: debuggingOptions.deviceVmServicePort,
        ipv6: ipv6,
        logger: _logger,
      );
      _logReader.initializeProcess(_process!);

      final Uri? observatoryUri = await observatoryDiscovery.uri;
      if (observatoryUri != null) {
        return LaunchResult.succeeded(observatoryUri: observatoryUri);
      }
      _logger.printError(
        'Failed to launch $package: '
        'The log reader failed unexpectedly.',
      );
    } on Exception catch (error) {
      _logger.printError('Failed to launch $package: $error');
    } finally {
      await observatoryDiscovery?.cancel();
    }
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(
    ApplicationPackage app, {
    String? userIdentifier,
  }) async {
    _process?.kill();
    _process = null;
    return true;
  }

  @override
  Future<bool> uninstallApp(
    ApplicationPackage app, {
    String? userIdentifier,
  }) async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  DevFSWriter createDevFSWriter(
    covariant ApplicationPackage app,
    String? userIdentifier,
  ) {
    return LocalDevFSWriter(
      fileSystem: _fileSystem,
    );
  }

  @override
  Future<void> dispose() async {
    _logReader.dispose();
    await _portForwarder.dispose();
  }
}

class FlutterTesterDevices extends PollingDeviceDiscovery {
  FlutterTesterDevices({
    required FileSystem fileSystem,
    required Artifacts artifacts,
    required ProcessManager processManager,
    required Logger logger,
    required FlutterVersion flutterVersion,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _testerDevice = FlutterTesterDevice(
        kTesterDeviceId,
        fileSystem: fileSystem,
        artifacts: artifacts,
        processManager: processManager,
        logger: logger,
        flutterVersion: flutterVersion,
        operatingSystemUtils: operatingSystemUtils,
      ),
       super('Flutter tester');

  static const String kTesterDeviceId = 'flutter-tester';

  static bool showFlutterTesterDevice = false;

  final FlutterTesterDevice _testerDevice;

  @override
  bool get canListAnything => true;

  @override
  bool get supportsPlatform => true;

  @override
  Future<List<Device>> pollingGetDevices({ Duration? timeout }) async {
    return showFlutterTesterDevice ? <Device>[_testerDevice] : <Device>[];
  }

  @override
  List<String> get wellKnownIds => const <String>[kTesterDeviceId];
}
