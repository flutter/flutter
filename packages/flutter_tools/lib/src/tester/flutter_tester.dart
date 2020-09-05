// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../convert.dart';
import '../device.dart';
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

  @override
  File get packagesFile => _directory.childFile('.packages');
}

/// The device interface for running on the flutter_tester shell.
///
/// Normally this is only used as the runner for `flutter test`, but it can
/// also be used as a regular device when `--show-test-device` is provided
/// to the flutter command.
// TODO(scheglov): This device does not currently work with full restarts.
class FlutterTesterDevice extends Device {
  FlutterTesterDevice(String deviceId, {
    @required ProcessManager processManager,
    @required FlutterVersion flutterVersion,
    @required Logger logger,
    @required String buildDirectory,
    @required FileSystem fileSystem,
    @required Artifacts artifacts,
  }) : _processManager = processManager,
       _flutterVersion = flutterVersion,
       _logger = logger,
       _buildDirectory = buildDirectory,
       _fileSystem = fileSystem,
       _artifacts = artifacts,
       super(
        deviceId,
        platformType: null,
        category: null,
        ephemeral: false,
      );

  final ProcessManager _processManager;
  final FlutterVersion _flutterVersion;
  final Logger _logger;
  final String _buildDirectory;
  final FileSystem _fileSystem;
  final Artifacts _artifacts;

  Process _process;
  final DevicePortForwarder _portForwarder = const NoOpDevicePortForwarder();

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

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

  final _FlutterTesterDeviceLogReader _logReader =
      _FlutterTesterDeviceLogReader();

  @override
  DeviceLogReader getLogReader({
    ApplicationPackage app,
    bool includePastLogs = false,
  }) {
    return _logReader;
  }

  @override
  Future<bool> installApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  @override
  Future<bool> isAppInstalled(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    @required String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    final BuildInfo buildInfo = debuggingOptions.buildInfo;
    if (!buildInfo.isDebug) {
      _logger.printError('This device only supports debug mode.');
      return LaunchResult.failed();
    }

    final String assetDirPath = _fileSystem.path.join(_buildDirectory, 'flutter_assets');
    final String applicationKernelFilePath = getKernelPathForTransformerOptions(
      _fileSystem.path.join(_buildDirectory, 'flutter-tester-app.dill'),
      trackWidgetCreation: buildInfo.trackWidgetCreation,
    );
    // Build assets and perform initial compilation.
    await BundleBuilder().build(
      buildInfo: buildInfo,
      mainPath: mainPath,
      assetDirPath: assetDirPath,
      applicationKernelFilePath: applicationKernelFilePath,
      precompiledSnapshot: false,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      platform: getTargetPlatformForName(getNameForHostPlatform(getCurrentHostPlatform())),
      treeShakeIcons: buildInfo.treeShakeIcons,
    );

    final List<String> command = <String>[
      _artifacts.getArtifactPath(Artifact.flutterTester),
      '--run-forever',
      '--non-interactive',
      '--enable-dart-profiling',
      '--packages=${debuggingOptions.buildInfo.packagesPath}',
      '--flutter-assets-dir=$assetDirPath',
      if (debuggingOptions.startPaused)
        '--start-paused',
      if (debuggingOptions.disableServiceAuthCodes)
        '--disable-service-auth-codes',
      if (debuggingOptions.hasObservatoryPort)
        '--observatory-port=${debuggingOptions.hostVmServicePort}',
      applicationKernelFilePath
    ];

    ProtocolDiscovery observatoryDiscovery;
    try {
      _logger.printTrace(command.join(' '));
      _process = await _processManager.start(command,
        environment: <String, String>{
          'FLUTTER_TEST': 'true',
        },
      );
      _process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(_logReader.addLine);
      _process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(_logReader.addLine);

      if (!debuggingOptions.debuggingEnabled) {
        return LaunchResult.succeeded();
      }

      observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(),
        hostPort: debuggingOptions.hostVmServicePort,
        devicePort: debuggingOptions.deviceVmServicePort,
        ipv6: ipv6,
      );

      final Uri observatoryUri = await observatoryDiscovery.uri;
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
    String userIdentifier,
  }) async {
    _process?.kill();
    _process = null;
    return true;
  }

  @override
  Future<bool> uninstallApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  Future<void> dispose() async {
    _logReader?.dispose();
    await _portForwarder?.dispose();
  }
}

class FlutterTesterDevices extends PollingDeviceDiscovery {
  FlutterTesterDevices({
    @required FileSystem fileSystem,
    @required Artifacts artifacts,
    @required ProcessManager processManager,
    @required Logger logger,
    @required FlutterVersion flutterVersion,
    @required Config config,
  }) : _testerDevice = FlutterTesterDevice(
        kTesterDeviceId,
        fileSystem: fileSystem,
        artifacts: artifacts,
        processManager: processManager,
        buildDirectory: getBuildDirectory(config, fileSystem),
        logger: logger,
        flutterVersion: flutterVersion,
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
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    return showFlutterTesterDevice ? <Device>[_testerDevice] : <Device>[];
  }
}

class _FlutterTesterDeviceLogReader extends DeviceLogReader {
  final StreamController<String> _logLinesController =
      StreamController<String>.broadcast();

  @override
  int get appPid => 0;

  @override
  Stream<String> get logLines => _logLinesController.stream;

  @override
  String get name => 'flutter tester log reader';

  void addLine(String line) => _logLinesController.add(line);

  @override
  void dispose() {}
}
