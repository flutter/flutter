// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/json.dart';
import 'package:meta/meta.dart';

/// Typedef for an extension RPC handler function.
typedef ExtensionRpcHandler = FutureOr<Object?> Function(Map<String, Object?> params);

/// Callback signature for sending a JSON-RPC 2.0 notification from an extension
/// service to the host tool.
typedef ExtensionNotificationSender = void Function(String method, Map<String, Object?> params);

/// Represents a logical service exposed by a Flutter Tool Extension.
///
/// Extension authors implement this class to group related RPC endpoints under
/// a specific [namespace] (e.g. `diagnostics`, `configuration`, `device`, `build`, `templates`).
abstract class ToolExtensionService {
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
