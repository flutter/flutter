// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';

import 'provider.dart';

/// Typedef for an extension RPC handler function.
typedef ExtensionRpcHandler = FutureOr<Object?> Function(Map<String, Object?> params);

/// Callback signature for sending a JSON-RPC 2.0 notification from an extension
/// service to the host tool.
typedef ExtensionNotificationSender = void Function(String method, Map<String, Object?> params);

typedef _ExtensionRequestSender = Future<Object?> Function(String method, [Object? parameters]);

/// Represents a logical service exposed by a Flutter Tool Extension.
///
/// Extension authors extend this class (via specific service base classes) to
/// group related RPC endpoints under a specific [namespace] (e.g.
/// `diagnostics`, `config`, `device`, `build`, `template`).
abstract base class ToolExtensionService {
  /// Internal JSON-RPC notification sender callback used by [sendNotification].
  ///
  /// Wired by `ToolExtensionEntryPoint.run` prior to invoking [initialize],
  /// queuing notifications emitted during [initialize] until the JSON-RPC
  /// channel connects.
  @internal
  ExtensionNotificationSender? notificationSender;

  /// Internal JSON-RPC request sender callback used by [sendHostRequest].
  ///
  /// Wired by `ToolExtensionEntryPoint.run` to `peer.sendRequest` before the
  /// extension peer begins listening for RPC requests.
  @internal
  _ExtensionRequestSender? requestSender;

  /// The namespace string of the service (e.g. `'diagnostics'`).
  String get namespace;

  /// Initializes state needed by the service and returns a map of method handlers.
  ///
  /// The returned map maps method names (without namespace prefix) to handler functions.
  Future<Map<String, ExtensionRpcHandler>> initialize();

  /// Sends a fire-and-forget JSON-RPC 2.0 notification with [method] and
  /// [params] to the host tool.
  ///
  /// Notifications sent during [initialize] are queued until the channel
  /// connects. Throws a [StateError] if called before this service has been
  /// attached by `ToolExtensionEntryPoint.run`.
  void sendNotification(String method, Map<String, Object?> params) {
    final ExtensionNotificationSender? sender = notificationSender;
    if (sender == null) {
      throw StateError(
        'Cannot send notification "$method": service "$namespace" is not attached to an active peer.',
      );
    }
    sender(method, params);
  }

  /// Sends a JSON-RPC 2.0 request to the host tool over the bidirectional
  /// `Peer` and returns the decoded result payload.
  ///
  /// Throws a [StateError] if called before this service has been attached to
  /// an active extension peer by `ToolExtensionEntryPoint.run`.
  @protected
  @nonVirtual
  Future<Object?> sendHostRequest(String method, Map<String, Object?> params) async {
    final _ExtensionRequestSender? sender = requestSender;
    if (sender == null) {
      throw StateError(
        'Cannot send request "$method": service "$namespace" is not attached to an active peer.',
      );
    }
    try {
      return await sender(method, params);
    } on json_rpc.RpcException catch (error) {
      if (tryParseToolExtensionRpcError(code: error.code, message: error.message, data: error.data)
          case final ToolExtensionException translated) {
        throw translated;
      }
      rethrow;
    }
  }

  /// Sends a structured log notification to the host tool over
  /// [ToolExtensionEntryPoint.logNotificationMethod].
  ///
  /// Defaults [timestamp] to the current UTC time when omitted.
  @nonVirtual
  void log(String message, {ExtensionLogLevel level = .info, DateTime? timestamp}) {
    sendNotification(
      ToolExtensionEntryPoint.logNotificationMethod,
      ExtensionLogMessage(
        level: level,
        message: message,
        timestamp: (timestamp ?? DateTime.now()).toUtc(),
      ).toMap(),
    );
  }

  /// Cleans up resources held by the service when the extension is shut down.
  ///
  /// Invoked by `ToolExtensionEntryPoint.run` when the host tool sends an
  /// `extension.shutdown` RPC on CLI exit or connection disposal. Runs
  /// concurrently across all registered services in the isolate via
  /// `Future.wait`, with a short bounded grace period before the
  /// extension isolate is terminated.
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
    this.supportedPlatforms = const <String>{'linux', 'macos', 'windows'},
  });

  /// Deserializes [ToolExtensionCapabilities] from a JSON map payload.
  factory ToolExtensionCapabilities.fromJson(Map<String, Object?> json) {
    return ToolExtensionCapabilities(
      extensionName: json.nullableField<String>(extensionNameKey),
      services: json.stringIterable(servicesKey).toList(),
      supportedPlatforms: json
          .stringIterable(supportedPlatformsKey)
          .map((String p) => p.toLowerCase())
          .toSet(),
    );
  }

  /// Map key for [extensionName].
  static const String extensionNameKey = 'extensionName';

  /// Map key for [services].
  static const String servicesKey = 'services';

  /// Map key for [supportedPlatforms].
  static const String supportedPlatformsKey = 'supportedPlatforms';

  /// Optional identifier name of the extension package.
  ///
  /// When provided, this should match the extension's package name. The host
  /// tool uses this identifier in error messages and artifact cache paths.
  final String? extensionName;

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
    servicesKey: services,
    supportedPlatformsKey: supportedPlatforms.toList(),
  };
}
