// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Device discovery and device implementation for tool extensions.
///
/// This library enables discovering and interacting with custom devices
/// provided by active tool extensions.
library experimental.devices;

import 'dart:async';

import 'package:file/file.dart';

import '../../generic_extension_protocol.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../flutter_plugins.dart';
import '../flutter_tools_core/build.dart' as core;
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../vmservice.dart';
import 'extension_discovery.dart';

/// A [DeviceDiscovery] implementation that delegates discovery to active tool extensions.
///
/// This class queries active [ToolExtension]s for devices they manage and
/// registers them as [ExtensionBackedDevice]s.
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

  /// Discovers devices by querying all active tool extensions that support the
  /// 'device' service.
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
                  extension,
                  category: _parseCategory(deviceData['category'] as String?),
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
///
/// This class represents a device that is managed by a tool extension.
/// Operations like installing, launching, and stopping apps are delegated
/// to the extension over RPC.
class ExtensionBackedDevice extends Device {
  ExtensionBackedDevice(
    super.id,
    this._extension, {
    required super.category,
    required super.logger,
    required this.name,
    this.buildTargetName,
    this.connectionInterface = DeviceConnectionInterface.attached,
    this.extensionManager,
    this.platformName,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
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

  /// Checks if the device supports the given project.
  ///
  /// For Linux devices, it checks if the project has a linux directory.
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

  /// Returns the target platform of the device.
  ///
  /// Maps the platform name from the extension to a [TargetPlatform],
  /// or falls back to category-based defaults if parsing fails.
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

  /// Installs the app on the device by calling `device.installApp` on the extension.
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

  /// Starts the app on the device.
  ///
  /// If [prebuiltApplication] is false and the device supports building,
  /// it first delegates the build to the extension before launching.
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
      // Step 1: Verify tool extension build service support
      // Query capabilities to check if the extension supports the 'build' service.
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

      // Step 2: Query build targets
      // Invoke 'build.getTargets' over the tool extension RPC to verify the target is supported
      // by the extension and extract target platform config (like pluginPlatformKey).
      core.Target? foundTarget;
      try {
        final Object? targetsResult = await _extension
            .callMethod('build.getTargets')
            .timeout(const Duration(seconds: 5));
        if (targetsResult is! List) {
          throwToolExit('Tool extension does not expose build targets.');
        }
        final List<core.ExtensionBuildTarget> targets = core.ExtensionBuildTarget.listFromJson(
          targetsResult,
        );
        final List<core.Target> matching = targets
            .where((core.Target t) => t.name == buildTarget)
            .toList();
        if (matching.isNotEmpty) {
          foundTarget = matching.first;
        } else {
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

      // Step 3: Extract local engine overrides
      // Propagate engine paths if compiling against a local engine build.
      final LocalEngineInfo? localEngineInfo = globals.artifacts?.localEngineInfo;
      if (localEngineInfo != null) {
        final String targetOutPath = localEngineInfo.targetOutPath;
        environmentConfig['FLUTTER_ENGINE'] = globals.fs.path.dirname(
          globals.fs.path.dirname(targetOutPath),
        );
        environmentConfig['LOCAL_ENGINE'] = localEngineInfo.localTargetName;
        environmentConfig['LOCAL_ENGINE_HOST'] = localEngineInfo.localHostName;
      }

      // Step 4: Host-side plugin resolution
      // If the target platform supports plugins (has a pluginPlatformKey), resolve plugins
      // on the host and package them as ExtensionPlugin DTOs for the extension to compile natively.
      final resolvedPlugins = <core.ExtensionPlugin>[];
      final String? pluginPlatformKey = foundTarget.pluginPlatformKey;
      if (pluginPlatformKey != null) {
        await refreshPluginsList(project);
        final List<Plugin> plugins = await findPlugins(project);
        final List<Plugin> resolved = resolvePluginImplementationsForPlatform(
          plugins,
          pluginPlatformKey,
        );
        for (final plugin in resolved) {
          final PluginPlatform platformConfig = plugin.platforms[pluginPlatformKey]!;
          resolvedPlugins.add(
            core.ExtensionPlugin(
              configuration: platformConfig.toMap(),
              name: plugin.name,
              path: plugin.path,
            ),
          );
        }
      }

      final buildEnv = core.BuildEnvironment(
        cacheDir: globals.cache.getRoot().uri,
        defines: environmentConfig,
        flutterAssetsDir: project.directory
            .childDirectory('build')
            .childDirectory('flutter_assets')
            .uri,
        outputDirectory: buildDirectory.uri,
        plugins: resolvedPlugins,
        projectRoot: project.directory.uri,
      );

      String? buildExecutablePath;

      // Step 5: Invoke build over tool extension RPC
      // Delegate compilation to the extension isolate.
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

  /// Stops the app on the device by calling `device.stopApp` on the extension.
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
