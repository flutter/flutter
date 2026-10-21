// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:meta/meta.dart';

/// Typedef for an extension RPC handler function.
typedef ExtensionRpcHandler = FutureOr<Object?> Function(Map<String, Object?> params);

/// Callback signature for sending a JSON-RPC 2.0 notification from an extension
/// service to the host tool.
typedef ExtensionNotificationSender = void Function(String method, Map<String, Object?> params);

/// Enumeration of standard tool extension service namespaces.
enum ExtensionService {
  /// Health check and diagnostic validation service (`diagnostics.*` RPCs).
  diagnostics,

  /// Feature flag and configuration option service (`config.*` RPCs).
  config,

  /// Project, app, and plugin template service (`template.*` RPCs).
  template,

  /// Target device discovery and execution service (`device.*` RPCs).
  device,

  /// Custom target build service (`build.*` RPCs).
  build,

  /// Platform artifact download and cache service (`artifact.*` RPCs).
  artifact,

  /// Ephemeral and build directory cleanup service (`clean.*` RPCs).
  clean;

  /// Resolves an [ExtensionService] from its namespace string, or `null` if unknown.
  static ExtensionService? tryFromNamespace(String namespace) => values.asNameMap()[namespace];
}

/// Severity level for structured log messages emitted by a tool extension.
enum ExtensionLogLevel {
  /// Standard informational status log message.
  info,

  /// Non-fatal warning log message.
  warning,

  /// Error log message.
  error,

  /// Verbose diagnostic trace log message.
  trace;

  /// Resolves an [ExtensionLogLevel] from its wire [name].
  ///
  /// Throws a [FormatException] if [name] is not a recognized log level.
  static ExtensionLogLevel fromName(String name) {
    final ExtensionLogLevel? level = values.asNameMap()[name];
    if (level == null) {
      throw FormatException('Unknown ExtensionLogLevel: "$name".');
    }
    return level;
  }
}

/// Represents a logical service exposed by a Flutter Tool Extension.
///
/// Extension authors implement this class to group related RPC endpoints under
/// a specific [namespace] (e.g. `diagnostics`, `configuration`, `device`, `build`, `templates`).
abstract class ToolExtensionService {
  /// Reserved JSON-RPC 2.0 notification method for structured log messages
  /// emitted by an extension to the host tool.
  static const logNotificationMethod = 'extension.log';

  /// Reserved JSON-RPC 2.0 notification method for reporting long-running
  /// request progress from an extension to the host tool.
  static const progressNotificationMethod = 'extension.progress';

  /// Reserved JSON-RPC 2.0 notification method for sending liveness heartbeats
  /// from an extension to the host tool during a long-running request.
  static const heartbeatNotificationMethod = 'extension.heartbeat';

  /// Reserved JSON-RPC 2.0 notification method sent by the host tool to
  /// cooperatively cancel an in-flight extension request.
  static const cancelRequestNotificationMethod = 'extension.cancelRequest';

  /// JSON key for the log severity level in [logNotificationMethod] notifications.
  static const levelKey = 'level';

  /// JSON key for the timestamp in [logNotificationMethod] notifications.
  static const timestampKey = 'timestamp';

  /// JSON key for the request identifier in progress, heartbeat, and
  /// cancellation notifications.
  static const requestIdKey = 'requestId';

  /// JSON key for the optional human-readable progress message in
  /// [progressNotificationMethod] notifications.
  static const messageKey = 'message';

  /// JSON key for the optional fractional progress value (`0.0` to `1.0`) in
  /// [progressNotificationMethod] notifications.
  static const progressKey = 'progress';

  /// Internal JSON-RPC notification sender callback used by [sendNotification].
  ///
  /// Wired by `ToolExtensionEntryPoint.run` before the extension peer begins
  /// listening for RPC requests.
  @internal
  ExtensionNotificationSender? notificationSender;

  /// The namespace string of the service (e.g. `'diagnostics'`).
  String get namespace;

  /// Initializes state needed by the service and returns a map of method handlers.
  ///
  /// The returned map maps method names (without namespace prefix) to handler functions.
  Future<Map<String, ExtensionRpcHandler>> initialize();

  /// Sends a fire-and-forget JSON-RPC 2.0 notification with [method] and
  /// [params] to the host tool.
  ///
  /// Throws a [StateError] if called before this service has been attached to
  /// an active extension peer by `ToolExtensionEntryPoint.run`.
  void sendNotification(String method, Map<String, Object?> params) {
    final ExtensionNotificationSender? sender = notificationSender;
    if (sender == null) {
      throw StateError(
        'Cannot send notification "$method": service "$namespace" is not attached to an active peer.',
      );
    }
    sender(method, params);
  }

  /// Sends a structured [logNotificationMethod] notification to the host tool.
  void log(String message, {ExtensionLogLevel level = .info, DateTime? timestamp}) {
    sendNotification(logNotificationMethod, <String, Object?>{
      levelKey: level.name,
      messageKey: message,
      timestampKey: ?timestamp?.toUtc().toIso8601String(),
    });
  }

  /// Sends an [progressNotificationMethod] notification to the host tool for
  /// [requestId] with an optional human-readable [message] and fractional
  /// [progress] (`0.0` to `1.0`).
  ///
  /// Each progress notification also resets the host's sliding inactivity
  /// timer for the in-flight request.
  void reportProgress({required Object requestId, String? message, double? progress}) {
    sendNotification(progressNotificationMethod, <String, Object?>{
      requestIdKey: requestId,
      messageKey: ?message,
      progressKey: ?progress,
    });
  }

  /// Sends a [heartbeatNotificationMethod] notification to the host tool for
  /// [requestId] during a long-running request.
  void sendHeartbeat({required Object requestId}) {
    sendNotification(heartbeatNotificationMethod, <String, Object?>{requestIdKey: requestId});
  }

  /// Invoked when the host tool sends an [cancelRequestNotificationMethod]
  /// notification to cooperatively cancel the in-flight request identified by
  /// [requestId].
  ///
  /// Subclasses that run long-lived operations (such as subprocesses or
  /// downloads) can override this method to abort work associated with
  /// [requestId].
  Future<void> onCancelRequest(Object requestId) async {}

  /// Cleans up resources held by the service when the extension is shut down.
  Future<void> shutdown() async {}
}

/// Represents the capabilities and supported service namespaces reported by an extension.
@immutable
class ToolExtensionCapabilities {
  /// Creates [ToolExtensionCapabilities] listing supported [services],
  /// [supportedPlatforms], and optional [extensionName].
  const ToolExtensionCapabilities({
    required this.services,
    this.extensionName,
    this.protocolVersion = currentProtocolVersion,
    this.supportedPlatforms = ExtensionPackageConfig.defaultSupportedPlatforms,
  });

  /// Deserializes [ToolExtensionCapabilities] from a JSON map payload.
  factory ToolExtensionCapabilities.fromJson(Map<String, Object?> json) {
    return ToolExtensionCapabilities(
      extensionName: json.nullableField<String>(extensionNameKey),
      protocolVersion: json.optionalField<int>(
        protocolVersionKey,
        defaultValue: currentProtocolVersion,
      ),
      services: json.stringIterable(servicesKey).toList(),
      supportedPlatforms: json
          .stringIterable(supportedPlatformsKey)
          .map((String p) => p.toLowerCase())
          .toSet(),
    );
  }

  /// Current protocol version supported by `package:flutter_tools_extension`.
  static const int currentProtocolVersion = ExtensionPackageConfig.currentProtocolVersion;

  /// Map key for [extensionName].
  static const String extensionNameKey = 'extensionName';

  /// Map key for [protocolVersion].
  static const String protocolVersionKey = 'protocolVersion';

  /// Map key for [services].
  static const String servicesKey = 'services';

  /// Map key for [supportedPlatforms].
  static const String supportedPlatformsKey = 'supportedPlatforms';

  /// Optional identifier name of the extension package.
  ///
  /// When provided, this should match the extension's package name. The host
  /// tool uses this identifier in error messages and artifact cache paths.
  final String? extensionName;

  /// The protocol version implemented by the extension isolate.
  final int protocolVersion;

  /// The list of service namespace identifiers supported by the extension.
  final List<String> services;

  /// The set of host operating system platforms supported by the extension in lowercase (e.g., `{'linux'}`).
  final Set<String> supportedPlatforms;

  /// Returns whether the extension supports the given [hostPlatform].
  bool supportsHostPlatform(String hostPlatform) {
    return supportedPlatforms.contains(hostPlatform.toLowerCase());
  }

  /// Serializes capabilities to a map payload.
  Map<String, Object?> toMap() => <String, Object?>{
    extensionNameKey: ?extensionName,
    protocolVersionKey: protocolVersion,
    servicesKey: services,
    supportedPlatformsKey: supportedPlatforms.toList(),
  };
}
