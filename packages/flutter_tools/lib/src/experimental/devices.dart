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

import '../../flutter_tools_core.dart' as core;
import '../../generic_extension_protocol.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../vmservice.dart';
import 'build_targets.dart';
import 'extension_discovery.dart';

/// Retrieve the [ExtensionDeviceManager] from the context.
ExtensionDeviceManager? get extensionDeviceManager => context.get<ExtensionDeviceManager>();

Category parseCategory(String? category) => switch (category) {
  'mobile' => Category.mobile,
  'web' => Category.web,
  _ => Category.desktop,
};

/// A client-side [core.Device] implementation that delegates all commands to an extension isolate.
class HostDevice implements core.Device {
  HostDevice(
    this.id,
    this._extension, {
    required this.name,
    required this.category,
    required this.isEmulator,
    required this.platform,
    required this.buildTarget,
    required bool isSupportedVal,
    required bool isRunnableVal,
    this.connectionInterface = DeviceConnectionInterface.attached,
  }) : _isSupportedVal = isSupportedVal,
       _isRunnableVal = isRunnableVal;

  final ToolExtension _extension;
  final bool _isSupportedVal;
  final bool _isRunnableVal;
  final DeviceConnectionInterface connectionInterface;

  @override
  final String id;
  @override
  final String name;
  @override
  final String category;
  @override
  final bool isEmulator;
  @override
  final String platform;
  @override
  final String buildTarget;

  @override
  Future<bool> isSupported() async => _isSupportedVal;

  @override
  bool isRunnable() => _isRunnableVal;

  @override
  bool isSupportedForProject(Uri projectRoot) => true;

  @override
  Future<void> installApp(Uri appBundlePath) async {
    await _extension.callMethod(
      core.DeviceService.installAppMethod,
      params: <String, Object?>{'deviceId': id, 'appBundlePath': appBundlePath.toFilePath()},
    );
  }

  @override
  Future<void> launchApp(Uri appBundlePath, List<String> args) async {
    await _extension.callMethod(
      core.DeviceService.launchAppMethod,
      params: <String, Object?>{
        'deviceId': id,
        'appBundlePath': appBundlePath.toFilePath(),
        'args': args,
      },
    );
  }

  @override
  Future<Uri> getVmServiceUri() async {
    final Object? result = await _extension.callMethod(
      core.DeviceService.getVmServiceUriMethod,
      params: <String, Object?>{'deviceId': id},
    );
    if (result is String) {
      return Uri.parse(result);
    }
    throw StateError('Failed to get VM Service URI: invalid response');
  }

  @override
  Future<void> stopApp() async {
    await _extension.callMethod(
      core.DeviceService.stopAppMethod,
      params: <String, Object?>{'deviceId': id},
    );
  }

  @override
  Stream<String> getLogReader() {
    return _extension.notifications.expand(
      (Notification n) => switch (n) {
        Notification(
          method: core.DeviceService.logNotificationMethod,
          params: {'deviceId': final String dId, 'message': final String msg},
        )
            when dId == id =>
          <String>[msg],
        _ => const <String>[],
      },
    );
  }
}

/// Manages querying devices from active extensions.
base class ExtensionDeviceManager extends core.DeviceService {
  ExtensionDeviceManager({
    required ToolExtensionManager extensionManager,
    Logger? logger,
    Platform? platform,
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger ?? globals.logger,
         extensionManager: extensionManager,
         platform: platform ?? globals.platform,
       );

  final ExtensionDiscoveryHelper _discoveryHelper;

  @override
  Future<List<core.Device>> discoverDevices() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return const <core.Device>[];
    }

    final devices = <core.Device>[];
    final List<ToolExtension> extensions = await _discoveryHelper.getExtensionsSupporting(
      core.DeviceService.serviceNamespace,
    );

    for (final extension in extensions) {
      try {
        final Object? devicesResult = await extension
            .callMethod(core.DeviceService.discoverDevicesMethod)
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
              devices.add(
                HostDevice(
                  deviceData['id']! as String,
                  extension,
                  name: deviceData['name']! as String,
                  category: deviceData['category'] as String? ?? 'desktop',
                  isEmulator: deviceData['isEmulator'] as bool? ?? false,
                  platform: deviceData['platform'] as String? ?? 'linux-x64',
                  buildTarget: deviceData['buildTarget'] as String? ?? 'assemble_linux_app',
                  isSupportedVal: deviceData['isSupported'] as bool? ?? true,
                  isRunnableVal: deviceData['isRunnable'] as bool? ?? true,
                  connectionInterface: connectionInterface,
                ),
              );
            }
          }
        }
      } on Object catch (e) {
        _discoveryHelper.logger.printTrace('Failed to discover devices from extension: $e');
      }
    }
    return devices;
  }

  @override
  Future<void> launchEmulator(String emulatorId) async {
    // Not implemented for extension devices.
  }
}

/// A [DeviceDiscovery] implementation that delegates discovery to active tool extensions.
class ExtensionDeviceDiscovery extends DeviceDiscovery {
  ExtensionDeviceDiscovery(
    ToolExtensionManager extensionManager, {
    required Logger logger,
    Platform? platform,
    ExtensionDeviceManager? deviceManager,
  }) : _logger = logger,
       _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger,
         extensionManager: extensionManager,
         platform: platform,
       ),
       _deviceManager =
           deviceManager ??
           extensionDeviceManager ??
           ExtensionDeviceManager(
             extensionManager: extensionManager,
             logger: logger,
             platform: platform,
           );

  final Logger _logger;
  final ExtensionDiscoveryHelper _discoveryHelper;
  final ExtensionDeviceManager _deviceManager;

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

    try {
      final List<core.Device> coreDevices = await _deviceManager.discoverDevices();
      for (final coreDevice in coreDevices) {
        discoveredDevices.add(ExtensionBackedDevice(coreDevice, logger: _logger));
      }
    } on Object catch (e) {
      _logger.printTrace('Failed to discover devices: $e');
    }

    if (filter != null) {
      return filter.filterDevices(discoveredDevices);
    }
    return discoveredDevices;
  }
}

/// A client-side [Device] implementation that delegates all commands to a core.Device (HostDevice).
class ExtensionBackedDevice extends Device {
  ExtensionBackedDevice(this._device, {required super.logger})
    : connectionInterface = _device is HostDevice
          ? _device.connectionInterface
          : DeviceConnectionInterface.attached,
      super(
        _device.id,
        platformType: PlatformType.custom,
        ephemeral: true,
        category: parseCategory(_device.category),
      ) {
    _logReader = ExtensionDeviceLogReader(
      logLines: _device.getLogReader(),
      name: '$name log reader',
    );
  }

  final core.Device _device;

  @override
  final DeviceConnectionInterface connectionInterface;

  @override
  String get name => _device.name;

  late final ExtensionDeviceLogReader _logReader;

  @override
  Future<bool> isSupported() async => _device.isSupported();

  @override
  bool isSupportedForProject(FlutterProject project) {
    if (!_device.isSupportedForProject(project.directory.uri)) {
      return false;
    }
    if (_device.buildTarget == 'assemble_linux_app' ||
        _device.platform == 'linux-x64' ||
        _device.name.toLowerCase().contains('linux')) {
      return project.linux.existsSync();
    }
    return true;
  }

  @override
  Future<bool> get isLocalEmulator async => _device.isEmulator;

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
    final String platformName = _device.platform;
    try {
      return TargetPlatform.fromName(platformName);
    } on Exception {
      // Fallback
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
    final String? appName = app.name;
    if (appName == null) {
      throwToolExit('Application package name is null, cannot install.');
    }
    try {
      await _device.installApp(Uri.file(appName));
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
      final ExtensionBuildTargetManager? buildManager = extensionBuildTargetManager;
      if (buildManager == null) {
        throwToolExit('ExtensionBuildTargetManager not found in context.');
      }

      final String buildTarget = _device.buildTarget;

      core.Target? foundTarget;
      try {
        final List<core.Target> targets = await buildManager.getTargets();
        if (targets.isEmpty) {
          throwToolExit('Tool extension does not support the "build" service.');
        }
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

      final LocalEngineInfo? localEngineInfo = globals.artifacts?.localEngineInfo;
      if (localEngineInfo != null) {
        final String targetOutPath = localEngineInfo.targetOutPath;
        environmentConfig['FLUTTER_ENGINE'] = globals.fs.path.dirname(
          globals.fs.path.dirname(targetOutPath),
        );
        environmentConfig['LOCAL_ENGINE'] = localEngineInfo.localTargetName;
        environmentConfig['LOCAL_ENGINE_HOST'] = localEngineInfo.localHostName;
      }

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

      try {
        final Map<String, Object?> buildResultMap = await buildManager.buildTarget(
          buildTarget,
          buildEnv,
        );
        final buildResult = core.BuildResult.fromJson(buildResultMap);
        // CRITICAL FIX: Verify buildResult.success as in Workspace 1!
        if (!buildResult.success) {
          throwToolExit('Build compilation failed: ${buildResult.errorMessage ?? "Unknown error"}');
        }
        buildExecutablePath = buildResult.executablePath;
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

    if (executablePath == null) {
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

    if (executablePath == null && package == null) {
      throwToolExit('No executable path or application package provided to launch.');
    }
    final String? launchPath = executablePath ?? package?.name;
    if (launchPath == null) {
      throwToolExit('Application package name is null, cannot launch.');
    }

    try {
      final appUri = Uri.file(launchPath);
      await _device.launchApp(appUri, debuggingOptions.dartEntrypointArgs);
      final Uri vmServiceUri = await _device.getVmServiceUri();
      return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
    } on Object {
      return LaunchResult.failed();
    }
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    try {
      await _device.stopApp();
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
