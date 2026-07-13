// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// Typedef for an extension RPC handler function.
typedef ExtensionRpcHandler = FutureOr<Object?> Function(Map<String, Object?> params);

/// Represents a logical service exposed by a Flutter Tool Extension.
///
/// Extension authors implement this class to group related RPC endpoints under
/// a specific [namespace] (e.g. `diagnostics`, `configuration`, `device`, `build`, `templates`).
abstract class ToolExtensionService {
  /// The namespace string of the service (e.g. `'diagnostics'`).
  String get namespace;

  /// Initializes state needed by the service and returns a map of method handlers.
  ///
  /// The returned map maps method names (without namespace prefix) to handler functions.
  Future<Map<String, ExtensionRpcHandler>> initialize();

  /// Cleans up resources held by the service when the extension is shut down.
  Future<void> shutdown() async {}
}

/// Represents the capabilities and supported service namespaces reported by an extension.
@immutable
class ToolExtensionCapabilities {
  /// Creates [ToolExtensionCapabilities] listing supported [services] and [supportedPlatforms].
  const ToolExtensionCapabilities({
    required this.services,
    this.supportedPlatforms = const <String>['linux', 'macos', 'windows'],
  });

  /// Deserializes [ToolExtensionCapabilities] from a JSON map payload.
  factory ToolExtensionCapabilities.fromJson(Map<String, Object?> json) {
    final Object? servicesList = json['services'];
    final List<String> services = servicesList is List ? servicesList.cast<String>() : <String>[];
    final Object? platformsList = json['supportedPlatforms'];
    final List<String> supportedPlatforms = platformsList is List
        ? platformsList.cast<String>()
        : const <String>['linux', 'macos', 'windows'];
    return ToolExtensionCapabilities(services: services, supportedPlatforms: supportedPlatforms);
  }

  /// The list of service namespace identifiers supported by the extension.
  final List<String> services;

  /// The list of host operating system platforms supported by the extension (e.g., `'linux'`).
  final List<String> supportedPlatforms;

  /// Returns whether the extension supports the given [hostPlatform].
  bool supportsHostPlatform(String hostPlatform) {
    return supportedPlatforms.contains(hostPlatform.toLowerCase());
  }

  /// Serializes capabilities to a map payload.
  Map<String, Object?> toMap() => <String, Object?>{
    'services': services,
    'supportedPlatforms': supportedPlatforms,
  };
}
