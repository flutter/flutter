// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_core/json.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../application_package.dart';
import '../artifacts.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../build_system/targets/extension.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../project.dart';
import 'extension_build_manager.dart';
import 'extension_device_log_reader.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

export 'extension_device_log_reader.dart';

/// Resolves an [ApplicationPackage] for [device], delegating directly to
/// [ExtensionBackedDevice.resolveApplicationPackage] for extension-backed
/// devices without evaluating [factoryBuilder], and delegating to
/// [ApplicationPackageFactory.getPackageForPlatform] on the factory returned by
/// [factoryBuilder] otherwise.
Future<ApplicationPackage?> getApplicationPackageForDevice(
  Device device, {
  required ApplicationPackageFactory? Function() factoryBuilder,
  File? applicationBinary,
  BuildInfo? buildInfo,
}) async {
  if (device is ExtensionBackedDevice) {
    return device.resolveApplicationPackage(
      applicationBinary: applicationBinary,
      buildInfo: buildInfo,
    );
  }
  final TargetPlatform targetPlatform = await device.targetPlatform;
  return factoryBuilder()?.getPackageForPlatform(
    targetPlatform,
    applicationBinary: applicationBinary,
    buildInfo: buildInfo,
  );
}

/// An [ApplicationPackage] representing an application targeting a custom tool
/// extension device.
class ExtensionBackedApplicationPackage extends ApplicationPackage {
  ExtensionBackedApplicationPackage({required super.id, this.bundleUri, String? name})
    : name = name ?? id;

  /// Expected application bundle `file:` [Uri] resolved by the owning
  /// extension, or `null` when the bundle location cannot be determined without
  /// building.
  final Uri? bundleUri;

  @override
  final String name;
}

/// A prebuilt [ExtensionBackedApplicationPackage] supplied via
/// `--use-application-binary`.
class PrebuiltExtensionBackedApplicationPackage extends ExtensionBackedApplicationPackage
    implements PrebuiltApplicationPackage {
  PrebuiltExtensionBackedApplicationPackage({
    required this.applicationPackage,
    required super.id,
    Uri? bundleUri,
    String? name,
  }) : super(
         bundleUri: bundleUri ?? applicationPackage.absolute.uri,
         name: name ?? applicationPackage.basename,
       );

  @override
  final FileSystemEntity applicationPackage;
}

/// A host-side [DeviceService] client adapter delegating RPC queries to an [ExtensionConnection].
final class ExtensionDeviceClient extends DeviceService {
  ExtensionDeviceClient(this.connection, {required this._logger});

  /// The active extension isolate connection.
  final ExtensionConnection connection;
  final Logger _logger;

  Future<List<TargetDevice>> _fetchDevices() async {
    _logger.printTrace(
      'ExtensionDeviceClient fetching devices via RPC ("${DeviceService.getDevicesMethod}")...',
    );
    final Object? rawResult = await connection
        .sendRequest(DeviceService.getDevicesMethod)
        .timeout(const Duration(seconds: 5));
    final List<TargetDevice> devices = TargetDevice.listFromJson(rawResult);
    _logger.printTrace('ExtensionDeviceClient received ${devices.length} device(s) via RPC.');
    return devices;
  }

  @override
  Future<List<TargetDevice>> getDevices() async {
    try {
      return await _fetchDevices();
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to get devices: $err\n$stack');
    }
    return const <TargetDevice>[];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient checking project support for "$deviceId" via RPC '
      '("${DeviceService.isSupportedForProjectMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.isSupportedForProjectMethod,
        params: <String, Object?>{
          DeviceService.deviceIdParam: deviceId,
          DeviceService.projectParam: project.toMap(),
        },
      );
      if (rawResult case final bool supported) {
        return supported;
      }
    } on Object catch (err, stack) {
      _logger.printTrace(
        'ExtensionDeviceClient failed to check project support for "$deviceId": $err\n$stack',
      );
    }
    return false;
  }

  @override
  Future<ExtensionApplicationPackage?> resolveApplication(
    ExtensionApplicationResolutionContext context,
  ) async {
    _logger.printTrace(
      'ExtensionDeviceClient resolving application for "${context.deviceId}" via RPC '
      '("${DeviceService.resolveApplicationMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.resolveApplicationMethod,
      params: context.toMap(),
      timeout: null,
    );
    if (rawResult == null) {
      return null;
    }
    if (rawResult case final Map<String, Object?> map) {
      return ExtensionApplicationPackage.fromJson(map);
    }
    final message =
        'ExtensionDeviceClient received invalid response for '
        '"${DeviceService.resolveApplicationMethod}": expected Map<String, Object?> or null, '
        'got ${rawResult.runtimeType}.';
    _logger.printError(message);
    throw FormatException(message);
  }

  @override
  Future<void> installApp({
    required Uri bundleUri,
    required String deviceId,
    bool prebuiltApplication = false,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient installing app "$bundleUri" on "$deviceId" via RPC '
      '("${DeviceService.installAppMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.installAppMethod,
      params: <String, Object?>{
        DeviceService.bundleUriParam: bundleUri.toString(),
        DeviceService.deviceIdParam: deviceId,
        if (prebuiltApplication) DeviceService.prebuiltApplicationParam: prebuiltApplication,
      },
      timeout: null,
    );
  }

  @override
  Future<void> uninstallApp({required String appId, required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient uninstalling app "$appId" from "$deviceId" via RPC '
      '("${DeviceService.uninstallAppMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.uninstallAppMethod,
      params: <String, Object?>{
        DeviceService.appIdParam: appId,
        DeviceService.deviceIdParam: deviceId,
      },
      timeout: null,
    );
  }

  @override
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient checking if app "$appId" is installed on "$deviceId" via RPC '
      '("${DeviceService.isAppInstalledMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.isAppInstalledMethod,
      params: <String, Object?>{
        DeviceService.appIdParam: appId,
        DeviceService.deviceIdParam: deviceId,
      },
      timeout: null,
    );
    if (rawResult case final bool installed) {
      return installed;
    }
    final message =
        'ExtensionDeviceClient received invalid response for '
        '"${DeviceService.isAppInstalledMethod}": expected bool, got ${rawResult.runtimeType}.';
    _logger.printError(message);
    throw FormatException(message);
  }

  @override
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    _logger.printTrace(
      'ExtensionDeviceClient taking screenshot on "$deviceId" to "$outputFileUri" via RPC '
      '("${DeviceService.takeScreenshotMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.takeScreenshotMethod,
      params: <String, Object?>{
        DeviceService.deviceIdParam: deviceId,
        DeviceService.outputFileUriParam: outputFileUri.toString(),
      },
      timeout: null,
    );
  }

  @override
  Future<void> startScreenRecording({
    required String deviceId,
    required Uri outputFileUri,
    Duration? duration,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient starting screen recording on "$deviceId" to "$outputFileUri" via RPC '
      '("${DeviceService.startScreenRecordingMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.startScreenRecordingMethod,
      params: <String, Object?>{
        DeviceService.deviceIdParam: deviceId,
        DeviceService.durationMsParam: ?duration?.inMilliseconds,
        DeviceService.outputFileUriParam: outputFileUri.toString(),
      },
      timeout: null,
    );
  }

  @override
  Future<Uri> waitForScreenRecording({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient awaiting screen recording completion on "$deviceId" via RPC '
      '("${DeviceService.waitForScreenRecordingMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.waitForScreenRecordingMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
      timeout: null,
    );
    return _parseRecordingFileUri(rawResult, DeviceService.waitForScreenRecordingMethod);
  }

  @override
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping screen recording on "$deviceId" via RPC '
      '("${DeviceService.stopScreenRecordingMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.stopScreenRecordingMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
      timeout: null,
    );
    return _parseRecordingFileUri(rawResult, DeviceService.stopScreenRecordingMethod);
  }

  Uri _parseRecordingFileUri(Object? rawResult, String method) {
    if (rawResult case final String rawUri) {
      final Uri? uri = Uri.tryParse(rawUri);
      if (uri != null && uri.isValidFileUri) {
        return uri;
      }
      final message = 'ExtensionDeviceClient received invalid file URI for "$method": "$rawUri".';
      _logger.printError(message);
      throw FormatException(message);
    }
    final message =
        'ExtensionDeviceClient received invalid response for "$method": '
        'expected String, got ${rawResult.runtimeType}.';
    _logger.printError(message);
    throw FormatException(message);
  }

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient launching app "$executableUri" on "$deviceId" via RPC '
      '("${DeviceService.launchAppMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.launchAppMethod,
        params: <String, Object?>{
          DeviceService.debuggingOptionsParam: debuggingOptions.toMap(),
          DeviceService.deviceIdParam: deviceId,
          DeviceService.executableUriParam: executableUri.toString(),
        },
        timeout: null,
      );
      if (rawResult case final bool launched) {
        return launched;
      }
      _logger.printError(
        'ExtensionDeviceClient received invalid response for "${DeviceService.launchAppMethod}": '
        'expected bool, got ${rawResult.runtimeType}.',
      );
    } on Object catch (err, stack) {
      _logger.printError('ExtensionDeviceClient failed to launch app on "$deviceId": $err');
      _logger.printTrace('$stack');
    }
    return false;
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient getting VM Service URI for "$deviceId" via RPC '
      '("${DeviceService.getVmServiceUriMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.getVmServiceUriMethod,
        params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
        timeout: null,
      );
      if (rawResult case {DeviceService.vmServiceUriKey: final String uriStr}) {
        final Uri? parsed = Uri.tryParse(uriStr);
        if (parsed != null) {
          return parsed;
        }
        _logger.printError(
          'ExtensionDeviceClient received invalid VM Service URI for "$deviceId": "$uriStr".',
        );
        return null;
      }
      if (rawResult case {DeviceService.vmServiceUriKey: null}) {
        return null;
      }
      _logger.printError(
        'ExtensionDeviceClient received invalid response for "${DeviceService.getVmServiceUriMethod}": '
        'expected Map with String or null "${DeviceService.vmServiceUriKey}", got ${rawResult.runtimeType}.',
      );
    } on Object catch (err, stack) {
      _logger.printError(
        'ExtensionDeviceClient failed to get VM Service URI for "$deviceId": $err',
      );
      _logger.printTrace('$stack');
    }
    return null;
  }

  @override
  Future<bool> stopApp({required String deviceId, String? appId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping app on "$deviceId" via RPC '
      '("${DeviceService.stopAppMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.stopAppMethod,
        params: <String, Object?>{
          DeviceService.appIdParam: ?appId,
          DeviceService.deviceIdParam: deviceId,
        },
        timeout: null,
      );
      if (rawResult case final bool stopped) {
        return stopped;
      }
      _logger.printError(
        'ExtensionDeviceClient received invalid response for "${DeviceService.stopAppMethod}": '
        'expected bool, got ${rawResult.runtimeType}.',
      );
    } on Object catch (err, stack) {
      _logger.printError('ExtensionDeviceClient failed to stop app on "$deviceId": $err');
      _logger.printTrace('$stack');
    }
    return false;
  }

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient starting log stream for "$deviceId" via RPC '
      '("${DeviceService.startLogStreamMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.startLogStreamMethod,
      params: <String, Object?>{
        DeviceService.appIdParam: ?appId,
        DeviceService.deviceIdParam: deviceId,
      },
    );
  }

  @override
  Future<void> stopLogStream({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping log stream for "$deviceId" via RPC '
      '("${DeviceService.stopLogStreamMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.stopLogStreamMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
    );
  }
}

/// A host-side [DeviceDiscovery] mechanism that discovers devices registered by active extensions.
class ExtensionDevices extends PollingDeviceDiscovery {
  ExtensionDevices({
    required this._extensionBuildManager,
    required this._extensionManager,
    required this._toolContext,
  }) : super('tool_extension');

  final ExtensionBuildManager _extensionBuildManager;
  final ExtensionManager _extensionManager;
  final ToolContext _toolContext;
  final _devicesByKey = <(ExtensionConnection, String), ExtensionBackedDevice>{};

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  List<String> get wellKnownIds => const <String>[];

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    final Logger logger = _toolContext.logger;
    logger.printTrace('ExtensionDevices polling active tool extension devices...');
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      logger.printTrace('ExtensionDevices found 0 active device extensions.');
      _disposeCachedDevices();
      return <Device>[];
    }

    final List<(ExtensionDeviceClient, List<TargetDevice>?)> devicesPerService = await Future.wait(
      deviceServices.whereType<ExtensionDeviceClient>().map((ExtensionDeviceClient service) async {
        try {
          final List<TargetDevice> devices = await service._fetchDevices();
          return (service, devices);
        } on Object catch (e, st) {
          logger.printTrace('Error querying device extension service: $e\n$st');
          return (service, null);
        }
      }),
    );

    final failedConnections = <ExtensionConnection>{};
    final seenKeys = <(ExtensionConnection, String)>{};
    final targetDevices = <Device>[];
    for (final (ExtensionDeviceClient service, List<TargetDevice>? devices) in devicesPerService) {
      if (devices == null) {
        failedConnections.add(service.connection);
        continue;
      }
      for (final TargetDevice targetDevice in devices) {
        final (ExtensionConnection, String) key = (service.connection, targetDevice.id);
        if (!seenKeys.add(key)) {
          continue;
        }
        final ExtensionBackedDevice? existing = _devicesByKey[key];
        final ExtensionBackedDevice device;
        if (existing != null && !existing._disposed) {
          existing._targetDevice = targetDevice;
          device = existing;
        } else {
          device = ExtensionBackedDevice(
            buildManager: _extensionBuildManager,
            connection: service.connection,
            deviceService: service,
            targetDevice: targetDevice,
            toolContext: _toolContext,
          );
          _devicesByKey[key] = device;
        }
        targetDevices.add(device);
      }
    }

    final removedKeys = <(ExtensionConnection, String)>[
      for (final (ExtensionConnection connection, String deviceId) in _devicesByKey.keys)
        if (!seenKeys.contains((connection, deviceId)) && !failedConnections.contains(connection))
          (connection, deviceId),
    ];
    for (final key in removedKeys) {
      final ExtensionBackedDevice? removedDevice = _devicesByKey.remove(key);
      if (removedDevice != null) {
        unawaited(removedDevice.dispose());
      }
    }

    logger.printTrace('ExtensionDevices retrieved ${targetDevices.length} target device(s).');
    return targetDevices;
  }

  void _disposeCachedDevices() {
    for (final ExtensionBackedDevice device in _devicesByKey.values) {
      unawaited(device.dispose());
    }
    _devicesByKey.clear();
  }

  @override
  void dispose() {
    super.dispose();
    _disposeCachedDevices();
  }

  @override
  Future<List<String>> getDiagnostics() async => <String>[];
}

/// A host-side [Device] wrapper representing a target device backed by a tool extension.
class ExtensionBackedDevice extends Device {
  ExtensionBackedDevice({
    required this._buildManager,
    required this.connection,
    required this._deviceService,
    required this._targetDevice,
    required ToolContext super.toolContext,
  }) : super(
         _targetDevice.id,
         category: _targetDevice.category,
         ephemeral: _targetDevice.ephemeral,
         logger: toolContext.logger,
         platformType: PlatformType.custom,
       );

  final ExtensionBuildManager _buildManager;
  final ExtensionConnection connection;
  final DeviceService _deviceService;
  TargetDevice _targetDevice;
  Future<ExtensionDeviceLogReader>? _logReader;
  bool _disposed = false;

  @override
  String get name => _targetDevice.name;

  /// Whether this device supports installing and uninstalling application
  /// packages via `flutter install`.
  @override
  bool get supportsInstall => _targetDevice.supportsInstall;

  @override
  Future<bool> isSupported() async => _targetDevice.isSupported;

  @override
  Future<bool> isSupportedForProject(FlutterProject flutterProject) => _deviceService
      .isSupportedForProject(deviceId: id, project: flutterProject.toExtensionProject());

  @override
  Future<CpuArch> get cpuArch async => CpuArch.unknown;

  @override
  Future<String> get sdkNameAndVersion async =>
      _targetDevice.sdkNameAndVersion ?? 'Tool Extension Device';

  @override
  Future<String> get targetPlatformDisplayName async => _targetDevice.targetPlatform ?? 'custom';

  @override
  Future<TargetPlatform> get targetPlatform async {
    final String? platformName = _targetDevice.targetPlatform;
    if (platformName != null) {
      try {
        return TargetPlatform.fromName(platformName);
      } on Object {
        // Fall through if unrecognized target platform name supplied.
      }
    }
    return TargetPlatform.unsupported;
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  DevicePortForwarder? get portForwarder => null;

  /// Resolves an [ApplicationPackage] for this device via
  /// [DeviceService.resolveApplication].
  ///
  /// Falls back to the project's `pubspec.yaml` `name` as `id` and
  /// [applicationBinary] as `bundleUri` when `resolveApplication` returns `null`
  /// or fails with JSON-RPC `-32601` (`METHOD_NOT_FOUND`).
  Future<ApplicationPackage?> resolveApplicationPackage({
    File? applicationBinary,
    BuildInfo? buildInfo,
  }) async {
    final ToolContext(:FileSystem fs, :FlutterProjectFactory projectFactory) = toolContext;
    final FlutterProject project = projectFactory.fromDirectory(fs.currentDirectory);

    final Uri? applicationBinaryUri;
    if (applicationBinary != null) {
      applicationBinaryUri = _resolveArtifactUri(fs, applicationBinary);
      if (!applicationBinaryUri.isValidArtifactUri) {
        logger.printError('Invalid application binary path: ${applicationBinary.path}');
        return null;
      }
    } else {
      applicationBinaryUri = null;
    }

    final BuildMode buildMode = buildInfo?.mode ?? BuildMode.debug;
    final String? rawFlavor = buildInfo?.flavor;
    final String? flavor = rawFlavor != null && rawFlavor.isNotEmpty ? rawFlavor : null;
    final context = ExtensionApplicationResolutionContext(
      applicationBinaryUri: applicationBinaryUri,
      buildMode: buildMode,
      deviceId: id,
      flavor: flavor,
      project: project.toExtensionProject(),
    );

    ExtensionApplicationPackage? resolved;
    try {
      resolved = await _deviceService.resolveApplication(context);
    } on json_rpc.RpcException catch (err, stack) {
      if (err.code == error_code.METHOD_NOT_FOUND) {
        logger.printTrace(
          'Extension "${connection.extensionName}" does not implement '
          '"${DeviceService.resolveApplicationMethod}"; falling back to pubspec app name.',
        );
      } else {
        logger.printError(
          'Failed to resolve application for "$id" ("${connection.extensionName}"): $err',
        );
        logger.printTrace('$stack');
        return null;
      }
    } on Exception catch (err, stack) {
      logger.printError(
        'Failed to resolve application for "$id" ("${connection.extensionName}"): $err',
      );
      logger.printTrace('$stack');
      return null;
    }

    final String fallbackAppName = project.manifest.appName.isNotEmpty
        ? project.manifest.appName
        : project.directory.basename;
    final String appId = resolved?.appId ?? fallbackAppName;
    final Uri? bundleUri = resolved?.bundleUri ?? applicationBinaryUri;

    if (applicationBinary != null) {
      final FileSystemEntity resolvedEntity = bundleUri != null
          ? _resolveArtifactEntity(fs, bundleUri)
          : (fs.isDirectorySync(applicationBinary.path)
                ? fs.directory(applicationBinary.path)
                : applicationBinary);
      return PrebuiltExtensionBackedApplicationPackage(
        applicationPackage: resolvedEntity,
        bundleUri: bundleUri,
        id: appId,
        name: applicationBinary.basename,
      );
    }
    return ExtensionBackedApplicationPackage(
      bundleUri: bundleUri,
      id: appId,
      name: fallbackAppName,
    );
  }

  @override
  Future<DeviceLogReader> getLogReader({
    ApplicationPackage? app,
    bool includePastLogs = false,
  }) async {
    if (_disposed) {
      return NoOpDeviceLogReader(name);
    }
    final String? resolvedAppId = app != null && app.id.isNotEmpty ? app.id : null;
    while (true) {
      final Future<ExtensionDeviceLogReader>? existingFuture = _logReader;
      if (existingFuture == null) {
        break;
      }
      final ExtensionDeviceLogReader existingReader = await existingFuture;
      if (_disposed) {
        await existingReader.dispose();
        return NoOpDeviceLogReader(name);
      }
      if (!existingReader.isDisposed) {
        if (existingReader.appId != resolvedAppId) {
          if (!existingReader.hasActiveSubscriber) {
            await existingReader.reconfigureAppId(resolvedAppId, clearPendingLines: true);
          } else if (existingReader.appId != null && resolvedAppId == null) {
            await existingReader.reconfigureAppId(null);
          }
        }
        return existingReader;
      }
      if (identical(_logReader, existingFuture)) {
        _logReader = null;
        break;
      }
    }

    late final Future<ExtensionDeviceLogReader> readerFuture;
    readerFuture = ExtensionDeviceLogReader.create(
      appId: resolvedAppId,
      connection: connection,
      deviceId: id,
      deviceService: _deviceService,
      logger: logger,
      name: name,
      onDispose: () {
        if (identical(_logReader, readerFuture)) {
          _logReader = null;
        }
      },
    );
    _logReader = readerFuture;
    final ExtensionDeviceLogReader reader = await readerFuture;
    if (_disposed) {
      await reader.dispose();
      return NoOpDeviceLogReader(name);
    }
    return reader;
  }

  @override
  void clearLogs() {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    final Future<ExtensionDeviceLogReader>? logReaderFuture = _logReader;
    _logReader = null;
    try {
      final ExtensionDeviceLogReader? reader = await logReaderFuture;
      await reader?.dispose();
    } on Object {
      // Ignore errors if log reader creation failed.
    }
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  /// Validates that [app] points to an existing application bundle on disk
  /// before standalone installation, logging an actionable error if missing.
  bool hasValidInstallBundle(ApplicationPackage app) {
    if (!supportsInstall) {
      return true;
    }
    return _requireExistingBundleUri(app) != null;
  }

  Uri? _requireExistingBundleUri(ApplicationPackage app) {
    final FileSystem fs = toolContext.fs;
    final prebuiltApplication = app is PrebuiltApplicationPackage;
    final Uri? bundleUri = switch (app) {
      ExtensionBackedApplicationPackage(:final Uri? bundleUri) => bundleUri,
      PrebuiltApplicationPackage(:final FileSystemEntity applicationPackage) => _resolveArtifactUri(
        fs,
        applicationPackage,
      ),
      _ => null,
    };
    final String? bundlePath = bundleUri != null && bundleUri.isValidArtifactUri
        ? fs.path.fromUri(bundleUri)
        : null;
    final bool bundleExists =
        bundlePath != null && (fs.isFileSync(bundlePath) || fs.isDirectorySync(bundlePath));
    if (!bundleExists) {
      if (prebuiltApplication) {
        logger.printError(
          'Prebuilt application binary does not exist'
          '${bundlePath != null ? ': $bundlePath' : '.'}',
        );
      } else {
        final String? buildTarget = _targetDevice.buildTarget;
        final buildHint = buildTarget != null
            ? 'Run "flutter build $buildTarget" first, or pass "--use-application-binary".'
            : 'Build the application first, or pass "--use-application-binary".';
        logger.printError(
          'Application bundle for "${app.id}" was not found'
          '${bundlePath != null ? ' at $bundlePath' : ''}. $buildHint',
        );
      }
      return null;
    }
    return bundleUri;
  }

  static Uri _resolveArtifactUri(FileSystem fs, FileSystemEntity entity) {
    final String normalizedPath = fs.path.normalize(entity.absolute.path);
    if (entity is Directory || fs.isDirectorySync(normalizedPath)) {
      return fs.directory(normalizedPath).uri;
    }
    return fs.file(normalizedPath).uri;
  }

  static FileSystemEntity _resolveArtifactEntity(FileSystem fs, Uri uri) {
    final String path = fs.path.fromUri(uri);
    if (uri.path.endsWith('/') || fs.isDirectorySync(path)) {
      return fs.directory(path);
    }
    return fs.file(path);
  }

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async {
    if (!supportsInstall) {
      return true;
    }
    final Uri? bundleUri = _requireExistingBundleUri(app);
    if (bundleUri == null) {
      return false;
    }
    try {
      await _deviceService.installApp(
        bundleUri: bundleUri,
        deviceId: id,
        prebuiltApplication: app is PrebuiltApplicationPackage,
      );
      return true;
    } on Exception catch (err, stack) {
      logger.printError(
        'Failed to install application "${app.id}" on "$id" '
        '("${connection.extensionName}"): $err',
      );
      logger.printTrace('$stack');
      return false;
    }
  }

  Future<Uri?> _buildForLaunch({required BuildMode buildMode, String? mainPath}) async {
    final String? buildTargetName = _targetDevice.buildTarget;
    if (buildTargetName == null) {
      logger.printError('Device $name does not specify a buildTarget for launching applications.');
      return null;
    }

    final String targetMainPath = mainPath ?? 'lib/main.dart';
    logger.printTrace('Building application using extension target "$buildTargetName"...');

    final List<ExtensionBuildTarget> targets = await _buildManager.getBuildTargets();
    final ExtensionBuildTarget? target = targets
        .where((ExtensionBuildTarget t) => t.name == buildTargetName)
        .firstOrNull;
    if (target == null) {
      logger.printError('No tool extension provides build target "$buildTargetName" for $name.');
      return null;
    }

    final ToolContext(:Artifacts artifacts, :Cache cache, :Config config, :FileSystem fs) =
        toolContext;
    final Directory projectDir = fs.currentDirectory;
    final Directory buildOutputDir = projectDir.childDirectory(getBuildDirectory(config, fs));
    final Directory outputDir = target.outputDir.contains('{')
        ? resolveExtensionOutputDir(
            buildMode: buildMode,
            buildOutputDir: buildOutputDir,
            fileSystem: fs,
            projectDir: projectDir,
            target: target,
          )
        : fs.directory(
            fs.path.isRelative(target.outputDir)
                ? fs.path.join(projectDir.path, target.outputDir)
                : target.outputDir,
          );
    final Map<String, String> resolvedArtifacts = resolveExtensionBuildTargetArtifacts(
      artifacts: artifacts,
      buildMode: buildMode,
      target: target,
    );

    final ExtensionBuildResult result = await _buildManager.build(
      buildMode: buildMode,
      flutterRoot: fs.directory(cache.flutterRoot).uri,
      mainPath: targetMainPath,
      outputDir: outputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolvedArtifacts,
      targetName: buildTargetName,
    );
    if (!result.success) {
      final String? errorMessage = result.errorMessage;
      logger.printError(
        errorMessage != null && errorMessage.isNotEmpty
            ? 'Build failed: $errorMessage'
            : 'Build failed.',
      );
      return null;
    }
    final Uri? executableUri = result.executableUri;
    if (executableUri == null || !executableUri.isValidFileUri) {
      logger.printError(
        'Extension build target "$buildTargetName" did not return a valid executableUri.',
      );
      return null;
    }
    return executableUri;
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    required DebuggingOptions debuggingOptions,
    bool ipv6 = false,
    String? mainPath,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    String? route,
    String? userIdentifier,
  }) async {
    // TODO(bkonyi): Forward additional BuildInfo and DebuggingOptions fields
    // (e.g. dartDefines, flavor), https://github.com/flutter/flutter/issues/190753.
    final BuildMode buildMode = debuggingOptions.buildInfo.mode;

    if (prebuiltApplication) {
      logger.printError(
        'Prebuilt application bundles are not supported yet for tool extension devices.',
      );
      return LaunchResult.failed();
    }

    final Uri? executableUri = await _buildForLaunch(buildMode: buildMode, mainPath: mainPath);
    if (executableUri == null) {
      return LaunchResult.failed();
    }

    final bool debuggingEnabled = debuggingOptions.debuggingEnabled;
    final bool launched = await _deviceService.launchApp(
      debuggingOptions: ExtensionDebuggingOptions(
        buildMode: buildMode,
        debuggingEnabled: debuggingEnabled,
      ),
      deviceId: id,
      executableUri: executableUri,
    );
    if (!launched) {
      logger.printError('Failed to launch application on $name.');
      return LaunchResult.failed();
    }

    if (debuggingEnabled) {
      final Uri? vmServiceUri = await _deviceService.getVmServiceUri(deviceId: id);
      if (vmServiceUri == null) {
        logger.printError('Error waiting for a debug connection.');
        return LaunchResult.failed();
      }
      return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
    }

    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    final String? appId = app != null && app.id.isNotEmpty ? app.id : null;
    return _deviceService.stopApp(appId: appId, deviceId: id);
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async {
    if (!supportsInstall) {
      return true;
    }
    if (app.id.isEmpty) {
      logger.printError(
        'Cannot uninstall application from "$id": application package ID is empty.',
      );
      return false;
    }
    try {
      await _deviceService.uninstallApp(appId: app.id, deviceId: id);
      return true;
    } on Exception catch (err, stack) {
      logger.printError(
        'Failed to uninstall application "${app.id}" from "$id" '
        '("${connection.extensionName}"): $err',
      );
      logger.printTrace('$stack');
      return false;
    }
  }

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async {
    if (!supportsInstall) {
      return false;
    }
    if (app.id.isEmpty) {
      logger.printError(
        'Cannot check installation status on "$id": application package ID is empty.',
      );
      return false;
    }
    try {
      return await _deviceService.isAppInstalled(appId: app.id, deviceId: id);
    } on Exception catch (err, stack) {
      logger.printError(
        'Failed to check if application "${app.id}" is installed on "$id" '
        '("${connection.extensionName}"): $err',
      );
      logger.printTrace('$stack');
      return false;
    }
  }

  @override
  bool get supportsScreenshot => _targetDevice.supportsScreenshot;

  @override
  Future<void> takeScreenshot(File outputFile) =>
      _deviceService.takeScreenshot(deviceId: id, outputFileUri: outputFile.absolute.uri);
}
