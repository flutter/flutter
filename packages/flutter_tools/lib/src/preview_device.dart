// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'build_info.dart';
import 'bundle_builder.dart';
import 'cache.dart';
import 'desktop_device.dart';
import 'devfs.dart';
import 'device.dart';
import 'device_port_forwarder.dart';
import 'project.dart';
import 'protocol_discovery.dart';

typedef BundleBuilderFactory = BundleBuilder Function();

BundleBuilder _defaultBundleBuilder() {
  return BundleBuilder();
}

class PreviewDeviceDiscovery extends DeviceDiscovery {
  PreviewDeviceDiscovery({
    required Platform platform,
    required Artifacts artifacts,
    required FileSystem fileSystem,
    required Logger logger,
    required ProcessManager processManager,
  }) : _artifacts = artifacts,
       _logger = logger,
       _processManager = processManager,
       _fileSystem = fileSystem,
       _platform = platform;

  final Platform _platform;
  final Artifacts _artifacts;
  final Logger _logger;
  final ProcessManager _processManager;
  final FileSystem _fileSystem;

  @override
  bool get canListAnything => _platform.isWindows;

  @override
  Future<List<Device>> devices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) async => <Device>[
    if (_platform.isWindows)
      PreviewDevice(
        artifacts: _artifacts,
        fileSystem: _fileSystem,
        logger: _logger,
        processManager: _processManager,
      )
  ];

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) {
    return devices();
  }

  @override
  bool get supportsPlatform => true;

  @override
  List<String> get wellKnownIds => <String>['preview'];
}

/// A device type that runs a prebuilt desktop binary alongside a locally compiled kernel file.
///
/// This could be used to support debug local development without plugins on machines that
/// have not completed the SDK setup. These features are not fully implemented and the
/// device is not currently discoverable.
class PreviewDevice extends Device {
  PreviewDevice({
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required Artifacts artifacts,
    @visibleForTesting BundleBuilderFactory builderFactory = _defaultBundleBuilder,
  }) : _processManager = processManager,
       _logger = logger,
       _fileSystem = fileSystem,
       _bundleBuilderFactory = builderFactory,
       _artifacts = artifacts,
       super('preview', ephemeral: false, category: Category.desktop, platformType: PlatformType.custom);

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final BundleBuilderFactory _bundleBuilderFactory;
  final Artifacts _artifacts;

  @override
  void clearLogs() { }

  @override
  Future<void> dispose() async { }

  @override
  Future<String?> get emulatorId async => null;

  final DesktopLogReader _logReader = DesktopLogReader();

  @override
  FutureOr<DeviceLogReader> getLogReader({ApplicationPackage? app, bool includePastLogs = false}) => _logReader;

  @override
  Future<bool> installApp(ApplicationPackage? app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  String get name => 'preview';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => 'preview';

  Process? _process;

  @override
  Future<LaunchResult> startApp(ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs = const <String, dynamic>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    final Directory assetDirectory = _fileSystem.systemTempDirectory
      .createTempSync('flutter_preview.');

    // Build assets and perform initial compilation.
    Status? status;
    try {
      status = _logger.startProgress('Compiling application for preview...');
      await _bundleBuilderFactory().build(
        buildInfo: debuggingOptions.buildInfo,
        mainPath: mainPath,
        platform: TargetPlatform.windows_x64,
        assetDirPath: getAssetBuildDirectory(),
      );
      copyDirectory(_fileSystem.directory(
        getAssetBuildDirectory()),
        assetDirectory.childDirectory('data').childDirectory('flutter_assets'),
      );
    } finally {
      status?.stop();
    }

    // Merge with precompiled executable.
    final Directory precompiledDirectory = _fileSystem.directory(_fileSystem.path.join(Cache.flutterRoot!, 'artifacts_temp', 'Debug'));
    copyDirectory(precompiledDirectory, assetDirectory);

    final String windowsPath = _artifacts
      .getArtifactPath(Artifact.windowsDesktopPath, platform: TargetPlatform.windows_x64, mode: BuildMode.debug);
    final File windowsDll = _fileSystem.file(_fileSystem.path.join(windowsPath, 'flutter_windows.dll'));
    final File icu = _fileSystem.file(_fileSystem.path.join(windowsPath, 'icudtl.dat'));
    windowsDll.copySync(assetDirectory.childFile('flutter_windows.dll').path);
    icu.copySync(assetDirectory.childDirectory('data').childFile('icudtl.dat').path);

    final Process process = await _processManager.start(
      <String>[
        assetDirectory.childFile('flutter_preview').path,
      ],
    );
    _process = process;
    _logReader.initializeProcess(process);

    final ProtocolDiscovery vmServiceDiscovery = ProtocolDiscovery.vmService(_logReader,
      devicePort: debuggingOptions.deviceVmServicePort,
      hostPort: debuggingOptions.hostVmServicePort,
      ipv6: ipv6,
      logger: _logger,
    );
    try {
      final Uri? vmServiceUri = await vmServiceDiscovery.uri;
      if (vmServiceUri != null) {
        return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
      }
      _logger.printError(
        'Error waiting for a debug connection: '
        'The log reader stopped unexpectedly.',
      );
    } on Exception catch (error) {
      _logger.printError('Error waiting for a debug connection: $error');
    } finally {
      await vmServiceDiscovery.cancel();
    }
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    return _process?.kill() ?? false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async {
    return TargetPlatform.windows_x64;
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async {
    return true;
  }

  @override
  DevFSWriter createDevFSWriter(ApplicationPackage? app, String? userIdentifier) {
    return LocalDevFSWriter(fileSystem: _fileSystem);
  }
}
