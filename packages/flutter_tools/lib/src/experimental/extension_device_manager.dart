// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_core/json.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../build_system/targets/extension.dart';
import '../cache.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../project.dart';
import '../vmservice.dart';
import 'extension_build_manager.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// A host-side [DeviceService] client adapter delegating RPC queries to an [ExtensionConnection].
final class ExtensionDeviceClient extends DeviceService {
  /// Creates an [ExtensionDeviceClient] wrapping the host [connection].
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
      final Object? rawResult = await connection
          .sendRequest(
            DeviceService.isSupportedForProjectMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: deviceId,
              DeviceService.projectParam: project.toMap(),
            },
          )
          .timeout(const Duration(seconds: 5));
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
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
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
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
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
  Future<bool> stopApp({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping app on "$deviceId" via RPC '
      '("${DeviceService.stopAppMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.stopAppMethod,
        params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
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
  Future<void> startLogStream({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient starting log stream for "$deviceId" via RPC '
      '("${DeviceService.startLogStreamMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.startLogStreamMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
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

/// A [DeviceLogReader] that streams log lines from a tool extension isolate
/// via [DeviceService.logEntryNotificationMethod] notifications.
class ExtensionDeviceLogReader extends DeviceLogReader {
  ExtensionDeviceLogReader._({
    required this._connection,
    required this._deviceId,
    required this._deviceService,
    required this._logger,
    required this.name,
  }) {
    // Defer flushing buffered lines to a microtask so that if multiple
    // subscribers attach to the broadcast stream in the same synchronous turn,
    // all of them receive the initial buffered lines rather than only the first
    // subscriber that triggered onListen synchronously.
    _logLinesController = StreamController<String>.broadcast(
      onListen: () => scheduleMicrotask(_flushPendingLines),
    );
  }

  /// Creates an [ExtensionDeviceLogReader] and starts the device log stream on
  /// the extension isolate.
  static Future<ExtensionDeviceLogReader> create({
    required ExtensionConnection connection,
    required String deviceId,
    required DeviceService deviceService,
    required Logger logger,
    required String name,
  }) async {
    final reader = ExtensionDeviceLogReader._(
      connection: connection,
      deviceId: deviceId,
      deviceService: deviceService,
      logger: logger,
      name: name,
    );
    await reader._startLogStream();
    return reader;
  }

  static const _maxPendingLines = 1000;

  final ExtensionConnection _connection;
  final String _deviceId;
  final DeviceService _deviceService;
  final Logger _logger;
  final _pendingLines = <String>[];

  @override
  final String name;

  late final StreamController<String> _logLinesController;
  StreamSubscription<Map<String, Object?>>? _notificationSubscription;
  bool _closeAfterFlush = false;
  bool _isDisposed = false;

  @override
  Stream<String> get logLines => _logLinesController.stream;

  void _flushPendingLines() {
    if (_isDisposed || _logLinesController.isClosed) {
      return;
    }
    if (_pendingLines.isNotEmpty) {
      _pendingLines.forEach(_logLinesController.add);
      _pendingLines.clear();
    }
    if (_closeAfterFlush) {
      unawaited(_logLinesController.close());
    }
  }

  Future<void> _startLogStream() async {
    try {
      _notificationSubscription = _connection
          .onNotification(DeviceService.logEntryNotificationMethod)
          .listen(
            (Map<String, Object?> params) {
              if (_isDisposed || _logLinesController.isClosed) {
                return;
              }
              if (params[DeviceService.deviceIdParam] == _deviceId) {
                if (params[DeviceService.lineKey] case final String line) {
                  if (_logLinesController.hasListener) {
                    _logLinesController.add(line);
                  } else if (_pendingLines.length < _maxPendingLines) {
                    _pendingLines.add(line);
                  }
                }
              }
            },
            onDone: () {
              if (_isDisposed || _logLinesController.isClosed) {
                return;
              }
              if (_pendingLines.isEmpty) {
                unawaited(_logLinesController.close());
              } else {
                _closeAfterFlush = true;
              }
            },
          );
      await _deviceService.startLogStream(deviceId: _deviceId);
    } on Object catch (error) {
      _logger.printWarning('Failed to start log stream for extension device "$_deviceId": $error');
      if (!_isDisposed) {
        _isDisposed = true;
        await _notificationSubscription?.cancel();
        _notificationSubscription = null;
        if (!_logLinesController.isClosed) {
          await _logLinesController.close();
        }
      }
    }
  }

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {}

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _pendingLines.clear();
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    try {
      await _deviceService.stopLogStream(deviceId: _deviceId);
    } on Object {
      // Ignore errors when stopping log streams during disposal.
    }
    await _logLinesController.close();
  }
}

/// A host-side [DeviceDiscovery] mechanism that discovers devices registered by active extensions.
class ExtensionDevices extends PollingDeviceDiscovery {
  /// Creates an [ExtensionDevices] instance.
  ExtensionDevices({
    required this._extensionBuildManager,
    required this._extensionManager,
    required this._fileSystem,
    required this._logger,
    this._artifacts,
    this._config,
  }) : super('tool_extension');

  final Artifacts? _artifacts;
  final Config? _config;
  final ExtensionBuildManager _extensionBuildManager;
  final ExtensionManager _extensionManager;
  final FileSystem _fileSystem;
  final Logger _logger;
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
    _logger.printTrace('ExtensionDevices polling active tool extension devices...');
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      _logger.printTrace('ExtensionDevices found 0 active device extensions.');
      _disposeCachedDevices();
      return <Device>[];
    }

    final List<(ExtensionDeviceClient, List<TargetDevice>?)> devicesPerService = await Future.wait(
      deviceServices.whereType<ExtensionDeviceClient>().map((ExtensionDeviceClient service) async {
        try {
          final List<TargetDevice> devices = await service._fetchDevices();
          return (service, devices);
        } on Object catch (e, st) {
          _logger.printTrace('Error querying device extension service: $e\n$st');
          return (service, null);
        }
      }),
    );

    final targetDevices = <ExtensionBackedDevice>[];
    final seenKeys = <(ExtensionConnection, String)>{};
    final failedConnections = <ExtensionConnection>{};

    for (final (ExtensionDeviceClient service, List<TargetDevice>? devices) in devicesPerService) {
      if (devices == null) {
        failedConnections.add(service.connection);
        continue;
      }
      for (final TargetDevice targetDevice in devices) {
        final (ExtensionConnection connection, String deviceId) key = (
          service.connection,
          targetDevice.id,
        );
        if (!seenKeys.add(key)) {
          continue;
        }

        final ExtensionBackedDevice? existingDevice = _devicesByKey[key];
        final ExtensionBackedDevice device;
        if (existingDevice != null && !existingDevice._disposed) {
          existingDevice._targetDevice = targetDevice;
          device = existingDevice;
        } else {
          device = ExtensionBackedDevice(
            buildManager: _extensionBuildManager,
            connection: service.connection,
            deviceService: service,
            fileSystem: _fileSystem,
            logger: _logger,
            targetDevice: targetDevice,
            artifacts: _artifacts,
            config: _config,
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

    _logger.printTrace('ExtensionDevices retrieved ${targetDevices.length} target device(s).');
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
  /// Creates an [ExtensionBackedDevice] wrapping a [TargetDevice].
  ExtensionBackedDevice({
    required this._buildManager,
    required this.connection,
    required this._deviceService,
    required this._fileSystem,
    required super.logger,
    required this._targetDevice,
    this._artifacts,
    this._config,
  }) : super(
         _targetDevice.id,
         category: _targetDevice.category,
         ephemeral: _targetDevice.ephemeral,
         platformType: PlatformType.custom,
       );

  final Artifacts? _artifacts;
  final ExtensionBuildManager _buildManager;
  final Config? _config;
  final ExtensionConnection connection;
  final DeviceService _deviceService;
  final FileSystem _fileSystem;
  TargetDevice _targetDevice;
  Future<ExtensionDeviceLogReader>? _logReader;
  bool _disposed = false;

  @override
  String get name => _targetDevice.name;

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

  @override
  Future<DeviceLogReader> getLogReader({ApplicationPackage? app, bool includePastLogs = false}) {
    if (_disposed) {
      return Future<DeviceLogReader>.value(NoOpDeviceLogReader(name));
    }
    return _logReader ??= ExtensionDeviceLogReader.create(
      connection: connection,
      deviceId: id,
      deviceService: _deviceService,
      logger: logger,
      name: name,
    );
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

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async => true;

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
    // (e.g. dartDefines, flavor), https://github.com/flutter/flutter/issues/190746.
    final BuildMode buildMode = debuggingOptions.buildInfo.mode;

    if (prebuiltApplication) {
      logger.printError(
        'Prebuilt application bundles are not supported yet for tool extension devices.',
      );
      return LaunchResult.failed();
    }

    final String? buildTargetName = _targetDevice.buildTarget;
    if (buildTargetName == null) {
      logger.printError('Device $name does not specify a buildTarget for launching applications.');
      return LaunchResult.failed();
    }

    final String targetMainPath = mainPath ?? 'lib/main.dart';
    logger.printTrace('Building application using extension target "$buildTargetName"...');

    final List<ExtensionBuildTarget> targets = await _buildManager.getBuildTargets();
    final ExtensionBuildTarget? target = targets
        .where((ExtensionBuildTarget t) => t.name == buildTargetName)
        .firstOrNull;

    final Directory projectDir = _fileSystem.currentDirectory;
    final Directory outputDir;
    final Map<String, String> resolvedArtifacts;
    if (target != null) {
      final Directory buildOutputDir = projectDir.childDirectory(
        _config != null ? getBuildDirectory(_config, _fileSystem) : 'build',
      );
      outputDir = target.outputDir.contains('{')
          ? resolveExtensionOutputDir(
              buildMode: buildMode,
              buildOutputDir: buildOutputDir,
              fileSystem: _fileSystem,
              projectDir: projectDir,
              target: target,
            )
          : _fileSystem.directory(
              _fileSystem.path.isRelative(target.outputDir)
                  ? _fileSystem.path.join(projectDir.path, target.outputDir)
                  : target.outputDir,
            );
      resolvedArtifacts = _artifacts != null
          ? resolveExtensionBuildTargetArtifacts(
              artifacts: _artifacts,
              buildMode: buildMode,
              target: target,
            )
          : const <String, String>{};
    } else {
      outputDir = projectDir.childDirectory('build');
      resolvedArtifacts = const <String, String>{};
    }

    final String flutterRootPath = Cache.flutterRoot ?? projectDir.path;

    final ExtensionBuildResult result = await _buildManager.build(
      buildMode: buildMode,
      flutterRoot: _fileSystem.directory(flutterRootPath).uri,
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
      return LaunchResult.failed();
    }
    final Uri? executableUri = result.executableUri;
    if (executableUri == null || !executableUri.isValidFileUri) {
      logger.printError(
        'Extension build target "$buildTargetName" did not return a valid executableUri.',
      );
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
    return _deviceService.stopApp(deviceId: id);
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;
}
