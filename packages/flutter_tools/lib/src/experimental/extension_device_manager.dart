// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_core/json.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../build_system/targets/extension.dart';
import '../cache.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../emulator.dart';
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
  Future<String?> getEmulatorPlatform() async {
    _logger.printTrace(
      'ExtensionDeviceClient fetching emulator platform via RPC '
      '("${DeviceService.getEmulatorPlatformMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(DeviceService.getEmulatorPlatformMethod);
    if (rawResult == null) {
      return null;
    }
    if (rawResult case final String platform) {
      return platform;
    }
    throw FormatException(
      'Expected String or null from ${DeviceService.getEmulatorPlatformMethod}, '
      'got ${rawResult.runtimeType}.',
    );
  }

  @override
  Future<List<TargetEmulator>> getEmulators() async {
    _logger.printTrace(
      'ExtensionDeviceClient fetching emulators via RPC ("${DeviceService.getEmulatorsMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(DeviceService.getEmulatorsMethod);
    final List<TargetEmulator> emulators = TargetEmulator.listFromJson(rawResult);
    _logger.printTrace('ExtensionDeviceClient received ${emulators.length} emulator(s) via RPC.');
    return emulators;
  }

  @override
  Future<void> launchEmulator({required String emulatorId, bool coldBoot = false}) async {
    _logger.printTrace(
      'ExtensionDeviceClient launching emulator "$emulatorId" (coldBoot: $coldBoot) via RPC '
      '("${DeviceService.launchEmulatorMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.launchEmulatorMethod,
      params: <String, Object?>{
        DeviceService.emulatorIdParam: emulatorId,
        DeviceService.coldBootParam: coldBoot,
      },
      // Launching an emulator may wait on external simulator startup.
      timeout: null,
    );
  }

  @override
  Future<TargetEmulator> createEmulator({String? name}) async {
    final String? normalizedName = name != null && name.isNotEmpty ? name : null;
    _logger.printTrace(
      'ExtensionDeviceClient creating emulator (name: $normalizedName) via RPC '
      '("${DeviceService.createEmulatorMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.createEmulatorMethod,
      params: <String, Object?>{DeviceService.emulatorNameParam: ?normalizedName},
      // Creating an emulator image or instance may exceed the default RPC timeout.
      timeout: null,
    );
    if (rawResult is! Map<String, Object?>) {
      throw FormatException(
        'Expected Map<String, Object?> from ${DeviceService.createEmulatorMethod}, '
        'got ${rawResult.runtimeType}.',
      );
    }
    return TargetEmulator.fromJson(rawResult);
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
    this._cache,
    this._config,
  }) : super('tool_extension');

  final Artifacts? _artifacts;
  final Cache? _cache;
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
            artifacts: _artifacts,
            buildManager: _extensionBuildManager,
            cache: _cache,
            config: _config,
            connection: service.connection,
            deviceService: service,
            fileSystem: _fileSystem,
            logger: _logger,
            targetDevice: targetDevice,
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
    this._cache,
    this._config,
  }) : super(
         _targetDevice.id,
         category: _targetDevice.category,
         ephemeral: _targetDevice.ephemeral,
         platformType: PlatformType.custom,
       );

  final Artifacts? _artifacts;
  final ExtensionBuildManager _buildManager;
  final Cache? _cache;
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
    // (e.g. dartDefines, flavor), https://github.com/flutter/flutter/issues/190753.
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
    if (target == null) {
      logger.printError('No tool extension provides build target "$buildTargetName" for $name.');
      return LaunchResult.failed();
    }

    final Directory projectDir = _fileSystem.currentDirectory;
    final Directory buildOutputDir = projectDir.childDirectory(
      _config != null ? getBuildDirectory(_config, _fileSystem) : 'build',
    );
    final Directory outputDir = target.outputDir.contains('{')
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
    final Map<String, String> resolvedArtifacts = _artifacts != null
        ? resolveExtensionBuildTargetArtifacts(
            artifacts: _artifacts,
            buildMode: buildMode,
            target: target,
          )
        : const <String, String>{};

    final String flutterRootPath = _cache?.flutterRoot ?? projectDir.path;

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

/// A host-side [Emulator] wrapper representing a target emulator backed by a tool extension.
@immutable
class ExtensionEmulator extends Emulator {
  /// Creates an [ExtensionEmulator] wrapping a [TargetEmulator].
  ExtensionEmulator({
    required this._deviceService,
    required this._logger,
    required TargetEmulator targetEmulator,
  }) : _targetEmulator = targetEmulator,
       super(targetEmulator.id, true);

  final DeviceService _deviceService;
  final Logger _logger;
  final TargetEmulator _targetEmulator;

  @override
  String get name => _targetEmulator.name;

  @override
  String? get manufacturer => _targetEmulator.manufacturer;

  @override
  Category get category => _targetEmulator.category ?? Category.other;

  @override
  PlatformType get platformType => PlatformType.custom;

  @override
  Future<void> launch({bool coldBoot = false}) async {
    final String prefix = ExtensionEmulators._extensionErrorPrefix(_deviceService);
    try {
      await _deviceService.launchEmulator(emulatorId: id, coldBoot: coldBoot);
    } on json_rpc.RpcException catch (err, stack) {
      _logger.printTrace('$stack');
      final String detail = err.message.trim();
      throwToolExit(
        detail.isEmpty
            ? '${prefix}Failed to launch emulator "$id".'
            : '${prefix}Failed to launch emulator "$id": $detail',
      );
    } on Object catch (err, stack) {
      _logger.printTrace('$stack');
      final String detail = '$err'.trim();
      throwToolExit(
        detail.isEmpty
            ? '${prefix}Failed to launch emulator "$id".'
            : '${prefix}Failed to launch emulator "$id": $detail',
      );
    }
  }
}

/// A host-side [EmulatorDiscovery] mechanism that discovers emulators registered by active extensions.
class ExtensionEmulators extends EmulatorDiscovery {
  ExtensionEmulators({required this._extensionManager, required this._logger});

  final ExtensionManager _extensionManager;
  final Logger _logger;
  Future<Map<String, DeviceService>>? _createProvidersFuture;
  Future<List<Emulator>>? _prefetchedEmulators;

  static String _describeExtension(DeviceService service) => switch (service) {
    ExtensionDeviceClient(connection: ExtensionConnection(:final String extensionName)) =>
      'tool extension "$extensionName"',
    _ => 'tool extension',
  };

  static String _extensionErrorPrefix(DeviceService service) => switch (service) {
    ExtensionDeviceClient(connection: ExtensionConnection(:final String extensionName)) =>
      'Extension "$extensionName": ',
    _ => '',
  };

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  bool get canLaunchAnything => true;

  /// Returns whether any active extension supports emulator creation or
  /// currently provides emulators, caching any queried emulator list for the
  /// immediately following [emulators] read.
  Future<bool> hasEmulatorSources() async {
    if ((await getCreatePlatforms()).isNotEmpty) {
      return true;
    }
    final Future<List<Emulator>> future = _queryEmulators();
    _prefetchedEmulators = future;
    return (await future).isNotEmpty;
  }

  @override
  Future<List<Emulator>> get emulators {
    final Future<List<Emulator>>? prefetched = _prefetchedEmulators;
    if (prefetched != null) {
      _prefetchedEmulators = null;
      return prefetched;
    }
    return _queryEmulators();
  }

  Future<List<Emulator>> _queryEmulators() async {
    _logger.printTrace('ExtensionEmulators querying active tool extension emulators...');
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      _logger.printTrace('ExtensionEmulators found 0 active device extensions.');
      return <Emulator>[];
    }

    final List<List<Emulator>> emulatorsPerService = await Future.wait(
      deviceServices.map((DeviceService service) async {
        try {
          final List<TargetEmulator> emulators = await service.getEmulators();
          return <Emulator>[
            for (final TargetEmulator targetEmulator in emulators)
              ExtensionEmulator(
                deviceService: service,
                logger: _logger,
                targetEmulator: targetEmulator,
              ),
          ];
        } on Object catch (e, st) {
          _logger.printWarning('Failed to query emulators from ${_describeExtension(service)}: $e');
          _logger.printTrace('$st');
          return const <Emulator>[];
        }
      }),
    );

    final targetEmulators = <Emulator>[
      for (final List<Emulator> emulatorList in emulatorsPerService) ...emulatorList,
    ];

    _logger.printTrace('ExtensionEmulators retrieved ${targetEmulators.length} emulator(s).');
    return targetEmulators;
  }

  /// Returns the validated platform identifiers under which active extensions
  /// support creating emulators.
  Future<List<String>> getCreatePlatforms() async =>
      (await _getCreateProviders()).keys.toList(growable: false);

  /// Creates a new emulator on the extension registered for [platform], or
  /// returns `null` if no active extension provides [platform].
  Future<CreateEmulatorResult?> createEmulator({required String platform, String? name}) async {
    final DeviceService? service = (await _getCreateProviders())[platform];
    if (service == null) {
      return null;
    }
    final String? normalizedName = name != null && name.isNotEmpty ? name : null;
    final String prefix = _extensionErrorPrefix(service);
    try {
      final TargetEmulator created = await service.createEmulator(name: normalizedName);
      return CreateEmulatorResult(created.id, success: true);
    } on json_rpc.RpcException catch (err, stack) {
      _logger.printTrace(
        'Failed to create emulator via ${_describeExtension(service)}: $err\n$stack',
      );
      final String detail = err.message.trim();
      return CreateEmulatorResult(
        normalizedName ?? '',
        success: false,
        error: detail.isEmpty ? '${prefix}Failed to create emulator.' : '$prefix$detail',
      );
    } on Object catch (err, stack) {
      _logger.printTrace(
        'Failed to create emulator via ${_describeExtension(service)}: $err\n$stack',
      );
      final String detail = '$err'.trim();
      return CreateEmulatorResult(
        normalizedName ?? '',
        success: false,
        error: detail.isEmpty ? '${prefix}Failed to create emulator.' : '$prefix$detail',
      );
    }
  }

  Future<Map<String, DeviceService>> _getCreateProviders() =>
      _createProvidersFuture ??= _loadCreateProviders();

  Future<Map<String, DeviceService>> _loadCreateProviders() async {
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      return const <String, DeviceService>{};
    }

    final List<(DeviceService, String?)> results = await Future.wait(
      deviceServices.map((DeviceService service) async {
        try {
          return (service, await service.getEmulatorPlatform());
        } on Object catch (e, st) {
          _logger.printWarning(
            'Failed to query emulator platform from ${_describeExtension(service)}: $e',
          );
          _logger.printTrace('$st');
          return (service, null);
        }
      }),
    );

    final providers = <String, DeviceService>{};
    for (final (DeviceService service, String? platform) in results) {
      if (platform == null) {
        continue;
      }
      final String description = _describeExtension(service);
      if (platform == EmulatorManager.androidPlatform) {
        _logger.printWarning(
          'Ignoring emulator platform "$platform" from $description: '
          '"${EmulatorManager.androidPlatform}" is reserved for built-in Android emulators.',
        );
        continue;
      }
      if (!DeviceService.isValidPlatformName(platform)) {
        _logger.printWarning(
          'Ignoring invalid emulator platform "$platform" from $description: '
          'platform identifiers must match lowercase ASCII letters, digits, underscores, or hyphens.',
        );
        continue;
      }
      final DeviceService? existing = providers[platform];
      if (existing != null) {
        _logger.printWarning(
          'Duplicate emulator platform "$platform" registered by $description and '
          '${_describeExtension(existing)}; keeping ${_describeExtension(existing)}.',
        );
        continue;
      }
      providers[platform] = service;
    }
    return providers;
  }
}
