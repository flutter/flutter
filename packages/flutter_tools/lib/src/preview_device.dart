// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'application_package.dart';
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

/// A device type that runs a prebuilt desktop binary alongside a locally compiled kernel file.
///
/// This could be used to support debug local development without plugins on machines that
/// have not completed the SDK setup. These features are not fully implemented and the
/// device is not currently discoverable.
class PreviewDevice extends Device {
  PreviewDevice({
    required final Platform platform,
    required final ProcessManager processManager,
    required final Logger logger,
    required final FileSystem fileSystem,
    @visibleForTesting final BundleBuilderFactory builderFactory = _defaultBundleBuilder,
  }) : _platform = platform,
       _processManager = processManager,
       _logger = logger,
       _fileSystem = fileSystem,
       _bundleBuilderFactory = builderFactory,
       super('preview', ephemeral: false, category: Category.desktop, platformType: PlatformType.custom);

  final Platform _platform;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final BundleBuilderFactory _bundleBuilderFactory;

  @override
  void clearLogs() { }

  @override
  Future<void> dispose() async { }

  @override
  Future<String?> get emulatorId async => null;

  final DesktopLogReader _logReader = DesktopLogReader();

  @override
  FutureOr<DeviceLogReader> getLogReader({final ApplicationPackage? app, final bool includePastLogs = false}) => _logReader;

  @override
  Future<bool> installApp(final ApplicationPackage? app, {final String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(final ApplicationPackage app, {final String? userIdentifier}) async => false;

  @override
  Future<bool> isLatestBuildInstalled(final ApplicationPackage app) async => false;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(final FlutterProject flutterProject) => true;

  @override
  String get name => 'preview';

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => 'preview';

  Process? _process;

  @override
  Future<LaunchResult> startApp(final ApplicationPackage? package, {
    final String? mainPath,
    final String? route,
    required final DebuggingOptions debuggingOptions,
    final Map<String, dynamic> platformArgs = const <String, dynamic>{},
    final bool prebuiltApplication = false,
    final bool ipv6 = false,
    final String? userIdentifier,
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
        platform: TargetPlatform.tester,
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

    final Process process = await _processManager.start(
      <String>[
        assetDirectory.childFile('splash').path,
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
  Future<bool> stopApp(final ApplicationPackage? app, {final String? userIdentifier}) async {
    return _process?.kill() ?? false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async {
    if (_platform.isWindows) {
      return TargetPlatform.windows_x64;
    }
    return TargetPlatform.tester;
  }

  @override
  Future<bool> uninstallApp(final ApplicationPackage app, {final String? userIdentifier}) async {
    return true;
  }

  @override
  DevFSWriter createDevFSWriter(final ApplicationPackage? app, final String? userIdentifier) {
    return LocalDevFSWriter(fileSystem: _fileSystem);
  }
}
