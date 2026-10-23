// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices and managing
/// device application installation and screen capture.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  static const String _getDevicesRpcMethod = 'getDevices';
  static const String _isSupportedForProjectRpcMethod = 'isSupportedForProject';
  static const _installAppRpcMethod = 'installApp';
  static const _uninstallAppRpcMethod = 'uninstallApp';
  static const _isAppInstalledRpcMethod = 'isAppInstalled';
  static const _takeScreenshotRpcMethod = 'takeScreenshot';
  static const _startScreenRecordingRpcMethod = 'startScreenRecording';
  static const _stopScreenRecordingRpcMethod = 'stopScreenRecording';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = '$serviceNamespace.$_getDevicesRpcMethod';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod =
      '$serviceNamespace.$_isSupportedForProjectRpcMethod';

  /// RPC method identifier to install an application bundle on a target device.
  static const installAppMethod = '$serviceNamespace.$_installAppRpcMethod';

  /// RPC method identifier to uninstall an application from a target device.
  static const uninstallAppMethod = '$serviceNamespace.$_uninstallAppRpcMethod';

  /// RPC method identifier to check whether an application is installed on a target device.
  static const isAppInstalledMethod = '$serviceNamespace.$_isAppInstalledRpcMethod';

  /// RPC method identifier to capture a screenshot from a target device.
  static const takeScreenshotMethod = '$serviceNamespace.$_takeScreenshotRpcMethod';

  /// RPC method identifier to start a screen recording on a target device.
  static const startScreenRecordingMethod = '$serviceNamespace.$_startScreenRecordingRpcMethod';

  /// RPC method identifier to stop an active screen recording on a target device.
  static const stopScreenRecordingMethod = '$serviceNamespace.$_stopScreenRecordingRpcMethod';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the serialized [ExtensionFlutterProject].
  static const String projectParam = 'project';

  /// RPC parameter key for the application bundle URI.
  static const bundleUriParam = 'bundleUri';

  /// RPC parameter key for the application package identifier.
  static const appIdParam = 'appId';

  /// RPC parameter key for the capture output file URI.
  static const outputFileUriParam = 'outputFileUri';

  /// RPC parameter key for the optional screen recording duration in milliseconds.
  static const durationMsParam = 'durationMs';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for [project].
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  });

  /// Installs the application bundle at [bundleUri] onto the device with [deviceId].
  ///
  /// [bundleUri] is guaranteed to be an absolute `file:` URI pointing to the
  /// built application binary or bundle. Returns `true` if installation
  /// succeeded, or `false` if installation failed or is unsupported.
  Future<bool> installApp({required Uri bundleUri, required String deviceId}) async => false;

  /// Uninstalls the application identified by [appId] from the device with [deviceId].
  ///
  /// Returns `true` if uninstallation succeeded, or `false` if uninstallation
  /// failed or is unsupported.
  Future<bool> uninstallApp({required String appId, required String deviceId}) async => false;

  /// Returns whether the application identified by [appId] is currently
  /// installed on the device with [deviceId].
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async => false;

  /// Captures a screenshot from the device with [deviceId] and writes it to
  /// [outputFileUri].
  ///
  /// Throws an [UnsupportedError] by default if the device does not support
  /// taking screenshots.
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    throw UnsupportedError('Screenshots are not supported on $deviceId.');
  }

  /// Starts a screen recording on the device with [deviceId], writing the
  /// captured video to [outputFileUri] and optionally stopping after [duration].
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

  /// Stops an active screen recording on the device with [deviceId] and returns
  /// the `file:` [Uri] of the recorded output file.
  ///
  /// Throws an [UnsupportedError] by default if the device does not support
  /// screen recording.
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    throw UnsupportedError('Screen recording is not supported on $deviceId.');
  }

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getDevicesRpcMethod: _getDevicesRpc,
      _isSupportedForProjectRpcMethod: _isSupportedForProjectRpc,
      _installAppRpcMethod: _installAppRpc,
      _uninstallAppRpcMethod: _uninstallAppRpc,
      _isAppInstalledRpcMethod: _isAppInstalledRpc,
      _takeScreenshotRpcMethod: _takeScreenshotRpc,
      _startScreenRecordingRpcMethod: _startScreenRecordingRpc,
      _stopScreenRecordingRpcMethod: _stopScreenRecordingRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getDevicesRpc(Map<String, Object?> _) async {
    final List<TargetDevice> devices = await getDevices();
    return devices.map((TargetDevice device) => device.toMap()).toList();
  }

  Future<bool> _isSupportedForProjectRpc(Map<String, Object?> params) async {
    final String deviceId;
    final ExtensionFlutterProject project;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
      final Map<String, Object?> projectMap = params.requiredField<Map<String, Object?>>(
        projectParam,
      );
      project = ExtensionFlutterProject.fromJson(projectMap);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return isSupportedForProject(deviceId: deviceId, project: project);
  }

  Future<bool> _installAppRpc(Map<String, Object?> params) async {
    final String deviceId;
    final Uri bundleUri;
    try {
      deviceId = _requireNonEmptyString(params, deviceIdParam);
      bundleUri = _requireFileUri(params, bundleUriParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return installApp(bundleUri: bundleUri, deviceId: deviceId);
  }

  Future<bool> _uninstallAppRpc(Map<String, Object?> params) async {
    final String deviceId;
    final String appId;
    try {
      deviceId = _requireNonEmptyString(params, deviceIdParam);
      appId = _requireNonEmptyString(params, appIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return uninstallApp(appId: appId, deviceId: deviceId);
  }

  Future<bool> _isAppInstalledRpc(Map<String, Object?> params) async {
    final String deviceId;
    final String appId;
    try {
      deviceId = _requireNonEmptyString(params, deviceIdParam);
      appId = _requireNonEmptyString(params, appIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return isAppInstalled(appId: appId, deviceId: deviceId);
  }

  Future<void> _takeScreenshotRpc(Map<String, Object?> params) async {
    final String deviceId;
    final Uri outputFileUri;
    try {
      deviceId = _requireNonEmptyString(params, deviceIdParam);
      outputFileUri = _requireFileUri(params, outputFileUriParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    await takeScreenshot(deviceId: deviceId, outputFileUri: outputFileUri);
  }

  Future<void> _startScreenRecordingRpc(Map<String, Object?> params) async {
    final String deviceId;
    final Uri outputFileUri;
    final int? durationMs;
    try {
      deviceId = _requireNonEmptyString(params, deviceIdParam);
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

  Future<String> _stopScreenRecordingRpc(Map<String, Object?> params) async {
    final String deviceId;
    try {
      deviceId = _requireNonEmptyString(params, deviceIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final Uri recordingUri = await stopScreenRecording(deviceId: deviceId);
    return recordingUri.toString();
  }

  static String _requireNonEmptyString(Map<String, Object?> params, String key) {
    final String value = params.requiredField<String>(key);
    if (value.isEmpty) {
      throw FormatException('Invalid "$key": must not be empty.');
    }
    return value;
  }

  static Uri _requireFileUri(Map<String, Object?> params, String key) {
    final String rawUri = params.requiredField<String>(key);
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri == null || !uri.isValidFileUri) {
      throw FormatException('Invalid "$key": must be an absolute "file:" URI.');
    }
    return uri;
  }
}
