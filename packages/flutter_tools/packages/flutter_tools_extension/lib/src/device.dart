// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices and emulators,
/// managing application execution, and streaming device logs.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  static const String _getDevicesRpcMethod = 'getDevices';
  static const String _isSupportedForProjectRpcMethod = 'isSupportedForProject';
  static const String _getEmulatorPlatformRpcMethod = 'getEmulatorPlatform';
  static const String _getEmulatorsRpcMethod = 'getEmulators';
  static const String _launchEmulatorRpcMethod = 'launchEmulator';
  static const String _createEmulatorRpcMethod = 'createEmulator';
  static const String _launchAppRpcMethod = 'launchApp';
  static const String _getVmServiceUriRpcMethod = 'getVmServiceUri';
  static const String _stopAppRpcMethod = 'stopApp';
  static const String _startLogStreamRpcMethod = 'startLogStream';
  static const String _stopLogStreamRpcMethod = 'stopLogStream';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = '$serviceNamespace.$_getDevicesRpcMethod';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod =
      '$serviceNamespace.$_isSupportedForProjectRpcMethod';

  /// RPC method identifier to query the platform identifier for creating emulators.
  static const String getEmulatorPlatformMethod =
      '$serviceNamespace.$_getEmulatorPlatformRpcMethod';

  /// RPC method identifier to query contributed target emulators.
  static const String getEmulatorsMethod = '$serviceNamespace.$_getEmulatorsRpcMethod';

  /// RPC method identifier to launch a contributed target emulator.
  static const String launchEmulatorMethod = '$serviceNamespace.$_launchEmulatorRpcMethod';

  /// RPC method identifier to create a new target emulator.
  static const String createEmulatorMethod = '$serviceNamespace.$_createEmulatorRpcMethod';

  /// RPC method identifier to launch an application on a target device.
  static const String launchAppMethod = '$serviceNamespace.$_launchAppRpcMethod';

  /// RPC method identifier to retrieve the VM service URI for a running application.
  static const String getVmServiceUriMethod = '$serviceNamespace.$_getVmServiceUriRpcMethod';

  /// RPC method identifier to stop a running application on a target device.
  static const String stopAppMethod = '$serviceNamespace.$_stopAppRpcMethod';

  /// RPC method identifier to start streaming log output for a target device.
  static const String startLogStreamMethod = '$serviceNamespace.$_startLogStreamRpcMethod';

  /// RPC method identifier to stop streaming log output for a target device.
  static const String stopLogStreamMethod = '$serviceNamespace.$_stopLogStreamRpcMethod';

  /// JSON-RPC 2.0 notification method emitted by the extension for each device
  /// log line.
  static const String logEntryNotificationMethod = '$serviceNamespace.logEntry';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the serialized [ExtensionFlutterProject].
  static const String projectParam = 'project';

  /// RPC parameter key for the target emulator ID.
  static const String emulatorIdParam = 'emulatorId';

  /// RPC parameter key for whether to cold boot the target emulator.
  static const String coldBootParam = 'coldBoot';

  /// RPC parameter key for the optional emulator name passed to [createEmulator].
  static const String emulatorNameParam = 'name';

  /// RPC parameter key for the executable URI to launch.
  static const String executableUriParam = 'executableUri';

  /// RPC parameter key for debugging options.
  static const String debuggingOptionsParam = 'debuggingOptions';

  /// RPC response key for the VM service URI.
  static const String vmServiceUriKey = 'vmServiceUri';

  /// JSON key for the log line text in [logEntryNotificationMethod]
  /// notifications.
  static const String lineKey = 'line';

  // Platform identifiers are passed on the command line via `--platform <name>`,
  // so restrict them to lowercase ASCII identifiers starting with a letter and
  // containing only letters, digits, underscores, or hyphens.
  static final RegExp _validPlatformNamePattern = RegExp(r'^[a-z][a-z0-9_-]*$');

  /// Returns whether [name] is a syntactically valid emulator creation platform
  /// identifier (`^[a-z][a-z0-9_-]*$`) for `flutter emulators --create --platform <name>`.
  static bool isValidPlatformName(String name) => _validPlatformNamePattern.hasMatch(name);

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for [project].
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  });

  /// Returns the optional platform identifier under which this extension
  /// supports creating emulators via
  /// `flutter emulators --create --platform <platform>` (for example,
  /// `'custom_embedder'`), or `null` when emulator creation via
  /// [createEmulator] is not supported by this extension.
  ///
  /// When non-null, must satisfy [isValidPlatformName].
  Future<String?> getEmulatorPlatform() async => null;

  /// Returns all available emulators or simulators managed by this extension.
  ///
  /// Defaults to returning an empty list for extensions that only provide
  /// physical or stationary target devices.
  Future<List<TargetEmulator>> getEmulators() async => const <TargetEmulator>[];

  /// Launches a specific device emulator for the custom platform (for
  /// `flutter emulators`), optionally performing a [coldBoot].
  ///
  /// Throws [UnsupportedError] when launching emulators is not supported by
  /// this extension, or [ToolExtensionException] if launching fails.
  Future<void> launchEmulator({required String emulatorId, bool coldBoot = false}) async {
    throw UnsupportedError('Launching emulator $emulatorId is not supported.');
  }

  /// Creates a new device emulator instance and returns its [TargetEmulator]
  /// descriptor (for `flutter emulators --create [--name <name>]
  /// [--platform <platform>]` and `flutter daemon` `emulator.create`).
  ///
  /// The returned [TargetEmulator.id] is reported to the user and IDE daemon as
  /// the created emulator identifier. Throws [UnsupportedError] when emulator
  /// creation is not supported by this extension, or [ToolExtensionException]
  /// if creation fails.
  Future<TargetEmulator> createEmulator({String? name}) async {
    throw UnsupportedError('Creating emulators is not supported.');
  }

  /// Launches the application at [executableUri] on the device with [deviceId]
  /// using the given [debuggingOptions].
  ///
  /// [executableUri] is guaranteed to be an absolute `file:` URI pointing to
  /// the built application binary or bundle. Returns `true` once the
  /// application process has been started, or `false` if launching failed.
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  });

  /// Returns the VM Service URI for a running application on [deviceId].
  ///
  /// Called by the host tool after [launchApp] succeeds when
  /// [ExtensionDebuggingOptions.debuggingEnabled] is `true`. Implementations
  /// may await VM Service discovery from the running process before returning,
  /// or return `null` if the process exits or VM Service discovery fails.
  Future<Uri?> getVmServiceUri({required String deviceId});

  /// Stops any running application on [deviceId].
  ///
  /// Returns `true` if a running application was stopped, or `false` if no
  /// application was running on [deviceId] or stopping it failed.
  Future<bool> stopApp({required String deviceId});

  /// Starts streaming log output for the device identified by [deviceId].
  ///
  /// Invoked by the host tool when a log consumer (such as `flutter logs` or
  /// `flutter run`) begins reading logs from [deviceId]. Implementations should
  /// return once log streaming has been initiated rather than awaiting the
  /// lifetime of the stream, and forward each log line (without a trailing
  /// newline) to the host by calling [emitLogLine].
  Future<void> startLogStream({required String deviceId}) async {}

  /// Stops streaming log output for the device identified by [deviceId].
  ///
  /// Invoked by the host tool when the device log reader is disposed.
  Future<void> stopLogStream({required String deviceId}) async {}

  /// Sends a [logEntryNotificationMethod] JSON-RPC notification containing a
  /// single log [line] (excluding any trailing newline) from [deviceId] to the
  /// host tool.
  void emitLogLine({required String deviceId, required String line}) {
    sendNotification(logEntryNotificationMethod, <String, Object?>{
      deviceIdParam: deviceId,
      lineKey: line,
    });
  }

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getDevicesRpcMethod: _getDevicesRpc,
      _isSupportedForProjectRpcMethod: _isSupportedForProjectRpc,
      _getEmulatorPlatformRpcMethod: _getEmulatorPlatformRpc,
      _getEmulatorsRpcMethod: _getEmulatorsRpc,
      _launchEmulatorRpcMethod: _launchEmulatorRpc,
      _createEmulatorRpcMethod: _createEmulatorRpc,
      _launchAppRpcMethod: _launchAppRpc,
      _getVmServiceUriRpcMethod: _getVmServiceUriRpc,
      _stopAppRpcMethod: _stopAppRpc,
      _startLogStreamRpcMethod: _startLogStreamRpc,
      _stopLogStreamRpcMethod: _stopLogStreamRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getDevicesRpc(Map<String, Object?> _) async {
    final List<TargetDevice> devices = await getDevices();
    return devices.map((TargetDevice device) => device.toMap()).toList();
  }

  Future<bool> _isSupportedForProjectRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final ExtensionFlutterProject project;
    try {
      final Map<String, Object?> projectMap = params.requiredField<Map<String, Object?>>(
        projectParam,
      );
      project = ExtensionFlutterProject.fromJson(projectMap);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return isSupportedForProject(deviceId: deviceId, project: project);
  }

  Future<String?> _getEmulatorPlatformRpc(Map<String, Object?> _) => getEmulatorPlatform();

  Future<List<Map<String, Object?>>> _getEmulatorsRpc(Map<String, Object?> _) async {
    final List<TargetEmulator> emulators = await getEmulators();
    return emulators.map((TargetEmulator e) => e.toMap()).toList();
  }

  Future<Object?> _launchEmulatorRpc(Map<String, Object?> params) async {
    final String emulatorId;
    final bool coldBoot;
    try {
      emulatorId = params.requiredField<String>(emulatorIdParam);
      if (emulatorId.isEmpty) {
        throw const FormatException('Invalid "$emulatorIdParam": must not be empty.');
      }
      coldBoot = params.optionalField<bool>(coldBootParam, defaultValue: false);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    await launchEmulator(emulatorId: emulatorId, coldBoot: coldBoot);
    return null;
  }

  Future<Map<String, Object?>> _createEmulatorRpc(Map<String, Object?> params) async {
    final String? name;
    try {
      name = params.nullableField<String>(emulatorNameParam);
      if (name != null && name.isEmpty) {
        throw const FormatException('Invalid "$emulatorNameParam": must not be empty.');
      }
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final TargetEmulator created = await createEmulator(name: name);
    return created.toMap();
  }

  String _parseDeviceId(Map<String, Object?> params) {
    final String deviceId;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    if (deviceId.isEmpty) {
      throw RpcException.invalidParams('Parameter "$deviceIdParam" must not be empty.');
    }
    return deviceId;
  }

  Future<bool> _launchAppRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final String executableUriStr;
    final Map<String, Object?> optionsMap;
    try {
      executableUriStr = params.requiredField<String>(executableUriParam);
      optionsMap = params.requiredField<Map<String, Object?>>(debuggingOptionsParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final Uri executableUri = _parseExecutableUri(executableUriStr);
    final ExtensionDebuggingOptions debuggingOptions = _parseDebuggingOptions(optionsMap);
    return launchApp(
      debuggingOptions: debuggingOptions,
      deviceId: deviceId,
      executableUri: executableUri,
    );
  }

  static Uri _parseExecutableUri(String executableUriStr) {
    final Uri? uri = Uri.tryParse(executableUriStr);
    if (uri == null || !uri.isValidFileUri) {
      throw RpcException.invalidParams(
        'Invalid "$executableUriParam" parameter for $launchAppMethod: must be an absolute "file:" URI.',
      );
    }
    return uri;
  }

  static ExtensionDebuggingOptions _parseDebuggingOptions(Map<String, Object?> options) {
    try {
      return ExtensionDebuggingOptions.fromJson(options);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(
        'Invalid "$debuggingOptionsParam" parameter for $launchAppMethod: ${e.message}',
      );
    }
  }

  Future<Map<String, Object?>> _getVmServiceUriRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final Uri? uri = await getVmServiceUri(deviceId: deviceId);
    return <String, Object?>{vmServiceUriKey: uri?.toString()};
  }

  Future<bool> _stopAppRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    return stopApp(deviceId: deviceId);
  }

  Future<Object?> _startLogStreamRpc(Map<String, Object?> params) async {
    await startLogStream(deviceId: _parseDeviceId(params));
    return null;
  }

  Future<Object?> _stopLogStreamRpc(Map<String, Object?> params) async {
    await stopLogStream(deviceId: _parseDeviceId(params));
    return null;
  }
}
