// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
    @required Platform platform,
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @visibleForTesting BundleBuilderFactory builderFactory = _defaultBundleBuilder,
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
  Future<String> get emulatorId async => null;

  final DesktopLogReader _logReader = DesktopLogReader();

  @override
  FutureOr<DeviceLogReader> getLogReader({covariant ApplicationPackage app, bool includePastLogs = false}) => _logReader;

  @override
  Future<bool> installApp(covariant ApplicationPackage app, {String userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(covariant ApplicationPackage app, {String userIdentifier}) async => false;

  @override
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app) async => false;

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

  Process _process;
  Directory _assetDirectory;

  @override
  Future<LaunchResult> startApp(covariant ApplicationPackage package, {
    String mainPath,
    String route,
    @required DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    _assetDirectory = _fileSystem.systemTempDirectory
      .createTempSync('flutter_preview.');

    // Build assets and perform initial compilation.
    Status status;
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
        _assetDirectory.childDirectory('data').childDirectory('flutter_assets'),
      );
    } finally {
      status.stop();
    }

    // Merge with precompiled executable.
    final Directory precompiledDirectory = _fileSystem.directory(_fileSystem.path.join(Cache.flutterRoot, 'artifacts_temp', 'Debug'));
    copyDirectory(precompiledDirectory, _assetDirectory);

    final Process process = await _processManager.start(
      <String>[
        _assetDirectory.childFile('splash').path,
      ],
    );
    _process = process;
    _logReader.initializeProcess(process);

    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(_logReader,
      devicePort: debuggingOptions?.deviceVmServicePort,
      hostPort: debuggingOptions?.hostVmServicePort,
      ipv6: ipv6,
      logger: _logger,
    );
    try {
      final Uri observatoryUri = await observatoryDiscovery.uri;
      if (observatoryUri != null) {
        return LaunchResult.succeeded(observatoryUri: observatoryUri);
      }
      _logger.printError(
        'Error waiting for a debug connection: '
        'The log reader stopped unexpectedly.',
      );
    } on Exception catch (error) {
      _logger.printError('Error waiting for a debug connection: $error');
    } finally {
      await observatoryDiscovery.cancel();
    }
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return _process?.kill();
  }

  @override
  Future<TargetPlatform> get targetPlatform async {
    if (_platform.isWindows) {
      return TargetPlatform.windows_x64;
    }
    return TargetPlatform.tester;
  }

  @override
  Future<bool> uninstallApp(covariant ApplicationPackage app, {String userIdentifier}) async {
    return true;
  }

  @override
  DevFSWriter createDevFSWriter(covariant ApplicationPackage app, String userIdentifier) {
    return LocalDevFSWriter(fileSystem: _fileSystem);
  }
}
