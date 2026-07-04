// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../../generic_extension_protocol.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../cmake.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../flutter_plugins.dart';
import '../flutter_tools_core/build.dart' as core;
import '../globals.dart' as globals;
import '../project.dart';
import '../vmservice.dart';
import 'extension_discovery.dart';

/// A [DeviceDiscovery] implementation that delegates discovery to active tool extensions.
class ExtensionDeviceDiscovery extends DeviceDiscovery {
  ExtensionDeviceDiscovery(ToolExtensionManager extensionManager, {required Logger logger})
    : _extensionManager = extensionManager,
      _logger = logger,
      _discoveryHelper = ExtensionDiscoveryHelper(
        logger: logger,
        extensionManager: extensionManager,
      );

  final ToolExtensionManager _extensionManager;
  final Logger _logger;
  final ExtensionDiscoveryHelper _discoveryHelper;

  /// Whether the host platform enables tool extension device discovery.
  @override
  bool get supportsPlatform => _discoveryHelper.isPrototypeEnabled;

  @override
  bool get canListAnything => true;

  @override
  List<String> get wellKnownIds => const <String>[];

  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) async {
    return discoverDevices(filter: filter);
  }

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
    bool forWirelessDiscovery = false,
  }) async {
    final discoveredDevices = <Device>[];

    final List<ToolExtension> extensions = await _discoveryHelper.getExtensionsSupporting('device');

    for (final extension in extensions) {
      try {
        final Object? devicesResult = await extension
            .callMethod('device.discoverDevices')
            .timeout(const Duration(seconds: 5));
        if (devicesResult is List) {
          for (final Object? item in devicesResult) {
            if (item is Map) {
              final Map<String, Object?> deviceData = item.cast<String, Object?>();
              final interfaceName = deviceData['connectionInterface'] as String?;
              DeviceConnectionInterface connectionInterface = DeviceConnectionInterface.attached;
              if (interfaceName != null) {
                try {
                  connectionInterface = getDeviceConnectionInterfaceForName(interfaceName);
                } on Object {
                  connectionInterface = DeviceConnectionInterface.attached;
                }
              }
              discoveredDevices.add(
                ExtensionBackedDevice(
                  deviceData['id']! as String,
                  category: _parseCategory(deviceData['category'] as String?),
                  extension: extension,
                  logger: _logger,
                  name: deviceData['name']! as String,
                  buildTargetName: deviceData['buildTarget'] as String?,
                  connectionInterface: connectionInterface,
                  extensionManager: _extensionManager,
                  platformName: deviceData['platform'] as String?,
                ),
              );
            }
          }
        }
      } on Object {
        // Ignore failures from individual extensions.
      }
    }

    if (filter != null) {
      return filter.filterDevices(discoveredDevices);
    }
    return discoveredDevices;
  }

  Category _parseCategory(String? category) => switch (category) {
    'mobile' => Category.mobile,
    'web' => Category.web,
    _ => Category.desktop,
  };
}

/// A client-side [Device] implementation that delegates all commands to an extension isolate.
class ExtensionBackedDevice extends Device {
  ExtensionBackedDevice(
    super.id, {
    required super.category,
    required ToolExtension extension,
    required super.logger,
    required this.name,
    this.buildTargetName,
    this.connectionInterface = DeviceConnectionInterface.attached,
    this.extensionManager,
    this.platformName,
  }) : _extension = extension,
       _logger = logger,
       _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger,
         extensionManager: extensionManager ?? ToolExtensionManager(),
       ),
       super(platformType: PlatformType.custom, ephemeral: true) {
    _logReader = ExtensionDeviceLogReader(
      logLines: _extension.notifications.expand(
        (Notification n) => switch (n) {
          Notification(
            method: 'device.log',
            params: {'deviceId': final String dId, 'message': final String msg},
          )
              when dId == id =>
            <String>[msg],
          _ => const <String>[],
        },
      ),
      name: '$name log reader',
    );
  }

  final ToolExtension _extension;
  final Logger _logger;
  final ToolExtensionManager? extensionManager;
  final ExtensionDiscoveryHelper _discoveryHelper;

  final String? platformName;
  final String? buildTargetName;

  @override
  final DeviceConnectionInterface connectionInterface;

  @override
  final String name;

  late final ExtensionDeviceLogReader _logReader;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool isSupportedForProject(FlutterProject project) {
    if (buildTargetName == 'assemble_linux_app' ||
        platformName == 'linux-x64' ||
        name.toLowerCase().contains('linux')) {
      return project.linux.existsSync();
    }
    return true;
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  DevicePortForwarder? get portForwarder => null;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => false;

  @override
  Future<TargetPlatform> get targetPlatform async {
    if (platformName case final String name) {
      try {
        return TargetPlatform.fromName(name);
      } on Exception {
        // Fallback to category switch on parsing failure
      }
    }
    return switch (category) {
      Category.mobile => TargetPlatform.android,
      Category.web => TargetPlatform.web_javascript,
      Category.desktop || null => TargetPlatform.linux_x64,
    };
  }

  @override
  Future<String> get sdkNameAndVersion async => 'Extension Custom SDK';

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async {
    try {
      await _extension
          .callMethod(
            'device.installApp',
            params: <String, Object?>{'deviceId': id, 'appBundlePath': app.name},
          )
          .timeout(const Duration(seconds: 10));
      return true;
    } on Exception catch (e) {
      throwToolExit('Failed to install app on extension device: $e');
    }
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    required DebuggingOptions debuggingOptions,
    String? mainPath,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    String? route,
    String? userIdentifier,
  }) async {
    final TargetPlatform platform = await targetPlatform;
    final String buildModeName = debuggingOptions.buildInfo.mode.cliName;
    final String platformName = platform.osName;
    final FlutterProject project = FlutterProject.current();
    final cmakeProject = GenericCmakeProject(project, platformName);
    final Directory buildDirectory = globals.fs.directory(
      globals.fs.path.join(
        project.directory.path,
        getBuildDirectory(),
        platform.getName(),
        id,
        buildModeName,
      ),
    );

    String? executablePath;

    if (!prebuiltApplication) {
      // 1. Verify that 'build' service is supported by checking capabilities.
      final bool isSupported;
      try {
        isSupported = await _discoveryHelper.isServiceSupported(
          _extension,
          'build',
          throwOnFailure: true,
        );
      } on Object catch (e) {
        throwToolExit('Failed to query capabilities: $e');
      }

      if (!isSupported) {
        throwToolExit('Tool extension does not support the "build" service.');
      }

      final String buildTarget = buildTargetName ?? 'assemble_linux_app';

      // 2. Query 'build.getTargets' to verify target is supported.
      try {
        final Object? targetsResult = await _extension
            .callMethod('build.getTargets')
            .timeout(const Duration(seconds: 5));
        if (targetsResult is! List) {
          throwToolExit('Tool extension does not expose build targets.');
        }
        final bool hasTarget = targetsResult.any(
          (Object? t) => t is Map && t['name'] == buildTarget,
        );
        if (!hasTarget) {
          throwToolExit('Tool extension does not expose build target "$buildTarget".');
        }
      } on Object catch (e) {
        if (e is ToolExit) {
          rethrow;
        }
        throwToolExit('Failed to query build targets: $e');
      }

      final Map<String, String> environmentConfig = debuggingOptions.buildInfo
          .toEnvironmentConfig();
      environmentConfig['FLUTTER_TARGET'] = mainPath ?? 'lib/main.dart';
      environmentConfig['FLUTTER_TARGET_PLATFORM'] = platform.getName();
      environmentConfig['FLUTTER_BUILD_MODE'] = buildModeName;
      environmentConfig['CMAKE_BUILD_TYPE'] = sentenceCase(buildModeName);

      // 3. Extract local engine overrides
      final LocalEngineInfo? localEngineInfo = globals.artifacts?.localEngineInfo;
      if (localEngineInfo != null) {
        final String targetOutPath = localEngineInfo.targetOutPath;
        environmentConfig['FLUTTER_ENGINE'] = globals.fs.path.dirname(
          globals.fs.path.dirname(targetOutPath),
        );
        environmentConfig['LOCAL_ENGINE'] = localEngineInfo.localTargetName;
        environmentConfig['LOCAL_ENGINE_HOST'] = localEngineInfo.localHostName;
      }

      // 4. Host preparations (write CMake configuration & plugin symlinks if CMake project exists)
      if (cmakeProject.existsSync()) {
        writeGeneratedCmakeConfig(
          Cache.flutterRoot!,
          cmakeProject,
          debuggingOptions.buildInfo,
          environmentConfig,
          _logger,
        );
        createPluginSymlinks(
          project,
          customCMakeProject: cmakeProject,
          customPlatformKey: platformName,
        );
      } else {
        _logger.printTrace(
          'Extension device platform "$platformName" does not use host CMake configuration.',
        );
      }

      final buildEnv = core.BuildEnvironment(
        cacheDir: globals.cache.getRoot().uri,
        defines: environmentConfig,
        flutterAssetsDir: project.directory
            .childDirectory('build')
            .childDirectory('flutter_assets')
            .uri,
        outputDirectory: buildDirectory.uri,
        projectRoot: project.directory.uri,
      );

      String? buildExecutablePath;

      // 5. Invoke build.build
      try {
        final Object? buildResult = await _extension
            .callMethod(
              'build.build',
              params: <String, Object?>{'targetName': buildTarget, 'environment': buildEnv.toMap()},
            )
            .timeout(const Duration(seconds: 60));

        if (buildResult case final Map<Object?, Object?> rawMap) {
          final result = core.BuildResult.fromJson(rawMap.cast<String, Object?>());
          if (!result.success) {
            throwToolExit('Build compilation failed: ${result.errorMessage ?? "Unknown error"}');
          }
          buildExecutablePath = result.executablePath;
        } else {
          throwToolExit('Build compilation failed: invalid response format.');
        }
      } on Object catch (e) {
        if (e is ToolExit) {
          rethrow;
        }
        throwToolExit('Build compilation failed with exception: $e');
      }

      if (buildExecutablePath != null) {
        executablePath = globals.fs.file(Uri.parse(buildExecutablePath).toFilePath()).path;
      }
    }

    // 6. Fallback if not resolved from build result (or if prebuiltApplication is true)
    if (executablePath == null) {
      // Fallback 1: Resolve CMake binary dynamically
      if (!prebuiltApplication && cmakeProject.existsSync()) {
        executablePath = globals.fs.path.join(
          buildDirectory.path,
          'bundle',
          project.manifest.appName,
        );
      }
    }

    if (executablePath != null) {
      executablePath = globals.fs.path.absolute(executablePath);
    }

    try {
      await _extension
          .callMethod(
            'device.launchApp',
            params: <String, Object?>{
              'deviceId': id,
              'appBundlePath': executablePath ?? package?.name,
              'args': debuggingOptions.dartEntrypointArgs,
            },
          )
          .timeout(const Duration(seconds: 5));

      final Object? uriString = await _extension
          .callMethod('device.getVmServiceUri', params: <String, Object?>{'deviceId': id})
          .timeout(const Duration(seconds: 5));
      if (uriString is! String) {
        return LaunchResult.failed();
      }
      final Uri vmServiceUri = Uri.parse(uriString);
      return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
    } on Object {
      return LaunchResult.failed();
    }
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    try {
      await _extension
          .callMethod('device.stopApp', params: <String, Object?>{'deviceId': id})
          .timeout(const Duration(seconds: 5));
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) =>
      _logReader;

  @override
  void clearLogs() {}

  @override
  Future<void> dispose() async {
    _logReader.dispose();
  }
}

/// A [DeviceLogReader] implementation that listens to notifications from the extension.
class ExtensionDeviceLogReader extends DeviceLogReader {
  ExtensionDeviceLogReader({required this.logLines, required this.name});

  @override
  final Stream<String> logLines;

  @override
  final String name;

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {}

  @override
  void dispose() {}
}
