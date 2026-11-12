// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'build.dart';
library;

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices, managing
/// application installation and execution, capturing device screens, and
/// streaming device logs.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  static const String _getDevicesRpcMethod = 'getDevices';
  static const String _isSupportedForProjectRpcMethod = 'isSupportedForProject';
  static const String _resolveApplicationRpcMethod = 'resolveApplication';
  static const String _installAppRpcMethod = 'installApp';
  static const String _uninstallAppRpcMethod = 'uninstallApp';
  static const String _isAppInstalledRpcMethod = 'isAppInstalled';
  static const String _takeScreenshotRpcMethod = 'takeScreenshot';
  static const String _startScreenRecordingRpcMethod = 'startScreenRecording';
  static const String _waitForScreenRecordingRpcMethod = 'waitForScreenRecording';
  static const String _stopScreenRecordingRpcMethod = 'stopScreenRecording';
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

  /// RPC method identifier to resolve the platform application identity and
  /// expected bundle location for a target device.
  static const String resolveApplicationMethod = '$serviceNamespace.$_resolveApplicationRpcMethod';

  /// RPC method identifier to install an application bundle on a target device.
  static const String installAppMethod = '$serviceNamespace.$_installAppRpcMethod';

  /// RPC method identifier to uninstall an application from a target device.
  static const String uninstallAppMethod = '$serviceNamespace.$_uninstallAppRpcMethod';

  /// RPC method identifier to check whether an application is installed on a target device.
  static const String isAppInstalledMethod = '$serviceNamespace.$_isAppInstalledRpcMethod';

  /// RPC method identifier to capture a screenshot from a target device.
  static const String takeScreenshotMethod = '$serviceNamespace.$_takeScreenshotRpcMethod';

  /// RPC method identifier to start a screen recording on a target device.
  static const String startScreenRecordingMethod =
      '$serviceNamespace.$_startScreenRecordingRpcMethod';

  /// RPC method identifier to await completion of an active screen recording on
  /// a target device.
  static const String waitForScreenRecordingMethod =
      '$serviceNamespace.$_waitForScreenRecordingRpcMethod';

  /// RPC method identifier to stop an active screen recording on a target device.
  static const String stopScreenRecordingMethod =
      '$serviceNamespace.$_stopScreenRecordingRpcMethod';

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

  /// RPC parameter key for the application bundle URI.
  static const String bundleUriParam = 'bundleUri';

  /// RPC parameter key for the application package identifier.
  static const String appIdParam = 'appId';

  /// RPC parameter key indicating whether the bundle is a user-supplied prebuilt application.
  static const String prebuiltApplicationParam = 'prebuiltApplication';

  /// RPC parameter key for the capture output file URI.
  static const String outputFileUriParam = 'outputFileUri';

  /// RPC parameter key for the optional screen recording duration in milliseconds.
  static const String durationMsParam = 'durationMs';

  /// RPC parameter key for the executable URI to launch.
  static const String executableUriParam = 'executableUri';

  /// RPC parameter key for debugging options.
  static const String debuggingOptionsParam = 'debuggingOptions';

  /// RPC response key for the VM service URI.
  static const String vmServiceUriKey = 'vmServiceUri';

  /// JSON key for the log line text in [logEntryNotificationMethod]
  /// notifications.
  static const String lineKey = 'line';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for [project].
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  });

  /// Resolves the platform-specific application identifier and expected bundle
  /// location for [context] to back a host-side `ApplicationPackage`.
  ///
  /// Returns `null` when the extension does not provide custom manifest or
  /// bundle resolution, in which case the host falls back to a synthesized
  /// `ApplicationPackage` using the project's `pubspec.yaml` `name` as `id`
  /// and [ExtensionApplicationResolutionContext.applicationBinaryUri] as
  /// `bundleUri`.
  Future<ExtensionApplicationPackage?> resolveApplication(
    ExtensionApplicationResolutionContext context,
  ) async => null;

  /// Installs the compiled application bundle at [bundleUri] to [deviceId]
  /// without launching it (for `flutter install`; required when
  /// [TargetDevice.supportsInstall] is `true`).
  ///
  /// When [prebuiltApplication] is `true`
  /// (`flutter install --use-application-binary`), [bundleUri] points to a
  /// user-supplied prebuilt package file rather than the output of
  /// [BuildTarget.build].
  ///
  /// Throws [UnsupportedError] by default when application installation is not
  /// supported on [deviceId].
  Future<void> installApp({
    required Uri bundleUri,
    required String deviceId,
    bool prebuiltApplication = false,
  }) async {
    throw UnsupportedError('App installation is not supported on $deviceId.');
  }

  /// Uninstalls the application identified by [appId] from [deviceId] (required
  /// when [TargetDevice.supportsInstall] is `true`).
  ///
  /// Throws [UnsupportedError] by default when application uninstallation is
  /// not supported on [deviceId].
  Future<void> uninstallApp({required String appId, required String deviceId}) async {
    throw UnsupportedError('App uninstallation is not supported on $deviceId.');
  }

  /// Returns `true` if the application identified by [appId] is currently
  /// installed on [deviceId] (required when [TargetDevice.supportsInstall] is
  /// `true`).
  ///
  /// Throws [UnsupportedError] by default when checking application
  /// installation status is not supported on [deviceId].
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    throw UnsupportedError('Checking app installation status is not supported on $deviceId.');
  }

  /// Captures a screenshot from the device with [deviceId] and writes it to
  /// [outputFileUri].
  ///
  /// Throws an [UnsupportedError] by default if the device does not support
  /// taking screenshots.
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    throw UnsupportedError('Screenshots are not supported on $deviceId.');
  }

  /// Starts a screen recording on the device with [deviceId], writing the
  /// captured video to [outputFileUri] and optionally capping its length at
  /// [duration].
  ///
  /// Implementations should return once recording has been initiated so the
  /// host tool can await completion via [waitForScreenRecording] while
  /// remaining able to terminate the recording early via [stopScreenRecording].
  ///
  /// Throws an [UnsupportedError] by default if the device does not support
  /// screen recording.
  Future<void> startScreenRecording({
    required String deviceId,
    required Uri outputFileUri,
    Duration? duration,
  }) async {
    throw UnsupportedError('Screen recording is not supported on $deviceId.');
  }

  /// Waits for an active screen recording on the device with [deviceId] to
  /// finish (whether capped by `duration` or stopped via [stopScreenRecording])
  /// and returns the `file:` [Uri] of the finalized output file.
  ///
  /// Throws an [UnsupportedError] by default if the device does not support
  /// screen recording.
  Future<Uri> waitForScreenRecording({required String deviceId}) async {
    throw UnsupportedError('Screen recording is not supported on $deviceId.');
  }

  /// Stops an active screen recording on the device with [deviceId] and returns
  /// the `file:` [Uri] of the finalized output file.
  ///
  /// Throws an [UnsupportedError] by default if the device does not support
  /// screen recording.
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    throw UnsupportedError('Screen recording is not supported on $deviceId.');
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

  /// Stops the running application on [deviceId].
  ///
  /// When [appId] is non-null, implementations may scope termination to that
  /// specific application; when [appId] is `null`, implementations stop the
  /// active or most recently launched Flutter application on [deviceId].
  ///
  /// Returns `true` if a running application was stopped, or `false` if no
  /// application was running on [deviceId] or stopping it failed.
  Future<bool> stopApp({required String deviceId, String? appId});

  /// Starts streaming log output for the device identified by [deviceId],
  /// optionally filtered to [appId] when non-null.
  ///
  /// Invoked by the host tool when a log consumer (such as `flutter logs` or
  /// `flutter run`) begins reading logs from [deviceId]. Implementations should
  /// return once log streaming has been initiated rather than awaiting the
  /// lifetime of the stream, and forward each log line (without a trailing
  /// newline) to the host by calling [emitLogLine].
  Future<void> startLogStream({required String deviceId, String? appId}) async {}

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
      _resolveApplicationRpcMethod: _resolveApplicationRpc,
      _installAppRpcMethod: _installAppRpc,
      _uninstallAppRpcMethod: _uninstallAppRpc,
      _isAppInstalledRpcMethod: _isAppInstalledRpc,
      _takeScreenshotRpcMethod: _takeScreenshotRpc,
      _startScreenRecordingRpcMethod: _startScreenRecordingRpc,
      _waitForScreenRecordingRpcMethod: _waitForScreenRecordingRpc,
      _stopScreenRecordingRpcMethod: _stopScreenRecordingRpc,
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

  Future<Map<String, Object?>?> _resolveApplicationRpc(Map<String, Object?> params) async {
    final ExtensionApplicationResolutionContext context;
    try {
      context = ExtensionApplicationResolutionContext.fromJson(params);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final ExtensionApplicationPackage? resolved = await resolveApplication(context);
    return resolved?.toMap();
  }

  Future<Object?> _installAppRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final Uri bundleUri;
    final bool prebuiltApplication;
    try {
      bundleUri = _requireArtifactUri(params, bundleUriParam);
      prebuiltApplication = params.optionalField<bool>(
        prebuiltApplicationParam,
        defaultValue: false,
      );
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    await installApp(
      bundleUri: bundleUri,
      deviceId: deviceId,
      prebuiltApplication: prebuiltApplication,
    );
    return null;
  }

  Future<Object?> _uninstallAppRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final String appId = _parseRequiredAppId(params);
    await uninstallApp(appId: appId, deviceId: deviceId);
    return null;
  }

  Future<bool> _isAppInstalledRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final String appId = _parseRequiredAppId(params);
    return isAppInstalled(appId: appId, deviceId: deviceId);
  }

  Future<void> _takeScreenshotRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final Uri outputFileUri;
    try {
      outputFileUri = _requireFileUri(params, outputFileUriParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    await takeScreenshot(deviceId: deviceId, outputFileUri: outputFileUri);
  }

  Future<void> _startScreenRecordingRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final Uri outputFileUri;
    final int? durationMs;
    try {
      outputFileUri = _requireFileUri(params, outputFileUriParam);
      durationMs = params.nullableField<int>(durationMsParam);
      if (durationMs != null && durationMs < 0) {
        throw const FormatException('Invalid "$durationMsParam": must be non-negative.');
      }
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    await startScreenRecording(
      deviceId: deviceId,
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
      outputFileUri: outputFileUri,
    );
  }

  Future<String> _waitForScreenRecordingRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final Uri recordingUri = await waitForScreenRecording(deviceId: deviceId);
    if (!recordingUri.isValidFileUri) {
      throw StateError(
        'waitForScreenRecording returned an invalid file URI "$recordingUri" '
        '(expected an absolute "file:" file URI).',
      );
    }
    return recordingUri.toString();
  }

  Future<String> _stopScreenRecordingRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final Uri recordingUri = await stopScreenRecording(deviceId: deviceId);
    if (!recordingUri.isValidFileUri) {
      throw StateError(
        'stopScreenRecording returned an invalid file URI "$recordingUri" '
        '(expected an absolute "file:" file URI).',
      );
    }
    return recordingUri.toString();
  }

  static Uri _requireArtifactUri(Map<String, Object?> params, String key) {
    final String rawUri = params.requiredField<String>(key);
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri == null || !uri.isValidArtifactUri) {
      throw FormatException('Invalid "$key": must be a non-root absolute "file:" URI.');
    }
    return uri;
  }

  static Uri _requireFileUri(Map<String, Object?> params, String key) {
    final String rawUri = params.requiredField<String>(key);
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri == null || !uri.isValidFileUri) {
      throw FormatException('Invalid "$key": must be an absolute "file:" URI.');
    }
    return uri;
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

  String _parseRequiredAppId(Map<String, Object?> params) {
    final String appId;
    try {
      appId = params.requiredField<String>(appIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    if (appId.isEmpty) {
      throw RpcException.invalidParams('Parameter "$appIdParam" must not be empty.');
    }
    return appId;
  }

  String? _parseOptionalAppId(Map<String, Object?> params) {
    final String? appId;
    try {
      appId = params.nullableField<String>(appIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    if (appId != null && appId.isEmpty) {
      throw RpcException.invalidParams('Parameter "$appIdParam" must not be empty.');
    }
    return appId;
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
    final String? appId = _parseOptionalAppId(params);
    return stopApp(appId: appId, deviceId: deviceId);
  }

  Future<Object?> _startLogStreamRpc(Map<String, Object?> params) async {
    final String deviceId = _parseDeviceId(params);
    final String? appId = _parseOptionalAppId(params);
    await startLogStream(appId: appId, deviceId: deviceId);
    return null;
  }

  Future<Object?> _stopLogStreamRpc(Map<String, Object?> params) async {
    await stopLogStream(deviceId: _parseDeviceId(params));
    return null;
  }
}
