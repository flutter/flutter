// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Extension discovery helper for tool extensions.
///
/// This library provides utilities for discovering active tool extensions,
/// spawning prototype extensions, and querying their capabilities over RPC.
library experimental.extension_discovery;

import 'dart:async';

import '../../generic_extension_protocol.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../globals.dart' as globals;

/// A helper class for abstracting extension isolate spawning and capability querying.
///
/// This helper provides utilities to check if the tool extension prototype is enabled,
/// query capabilities of extensions, filter extensions by supported services,
/// and invoke RPC methods on multiple extensions.
class ExtensionDiscoveryHelper {
  /// Create a new instance of [ExtensionDiscoveryHelper].
  ExtensionDiscoveryHelper({
    required Logger logger,
    Duration capabilitiesTimeout = const Duration(seconds: 5),
    ToolExtensionManager? extensionManager,
    Platform? platform,
  }) : _logger = logger,
       _capabilitiesTimeout = capabilitiesTimeout,
       _extensionManager = extensionManager,
       _platform = platform;

  final Duration _capabilitiesTimeout;
  final ToolExtensionManager? _extensionManager;
  final Logger _logger;
  final Platform? _platform;

  /// Environment variable key to enable tool extension prototype features.
  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';

  /// Whether the host platform enables tool extension prototype features.
  ///
  /// Checks the injected platform's environment variables first, and falls back
  /// to the global flag if no platform was injected.
  bool get isPrototypeEnabled => _platform != null
      ? _platform.environment[envPrototypeFlag] == 'true'
      : globals.isToolExtensionPrototypeEnabled;

  bool get _isPrototypeEnabled => isPrototypeEnabled;

  /// The [Logger] used by this helper.
  Logger get logger => _logger;

  /// The [ToolExtensionManager] used by this helper.
  ToolExtensionManager? get extensionManager => _extensionManager;

  /// Query the capabilities of a [ToolExtension] with a timeout.
  ///
  /// Returns null if the query fails, unless [throwOnFailure] is true.
  Future<ToolExtensionCapabilities?> getExtensionCapabilities(
    ToolExtension extension, {
    bool throwOnFailure = false,
  }) async {
    try {
      return await extension.getCapabilities().timeout(_capabilitiesTimeout);
    } on Object catch (e) {
      if (throwOnFailure) {
        rethrow;
      }
      _logger.printTrace('Failed to get capabilities: $e');
      return null;
    }
  }

  /// Checks whether a specific [extension] supports the given [serviceNamespace].
  ///
  /// Queries the extension's capabilities and checks if the service namespace
  /// is listed in the supported services.
  Future<bool> isServiceSupported(
    ToolExtension extension,
    String serviceNamespace, {
    bool throwOnFailure = false,
  }) async {
    final ToolExtensionCapabilities? capabilities = await getExtensionCapabilities(
      extension,
      throwOnFailure: throwOnFailure,
    );
    return capabilities != null && capabilities.services.contains(serviceNamespace);
  }

  /// Discover active or newly spawned tool extensions that support [serviceNamespace].
  ///
  /// If the extension manager has no extensions registered and the prototype
  /// is enabled, it attempts to start the default Linux extension prototype.
  Future<List<ToolExtension>> getExtensionsSupporting(
    String serviceNamespace, {
    bool throwOnFailure = false,
  }) async {
    final ToolExtensionManager? extensionManager = _extensionManager;
    if (extensionManager == null) {
      return const <ToolExtension>[];
    }

    if (extensionManager.extensions.isEmpty) {
      if (!_isPrototypeEnabled) {
        return const <ToolExtension>[];
      }
      try {
        await extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        if (throwOnFailure) {
          rethrow;
        }
        _logger.printError('Failed to spawn prototype extension: $e');
        return const <ToolExtension>[];
      }
    }

    final matchingExtensions = <ToolExtension>[];
    for (final ToolExtension extension in extensionManager.extensions) {
      final bool supported = await isServiceSupported(
        extension,
        serviceNamespace,
        throwOnFailure: throwOnFailure,
      );
      if (supported) {
        matchingExtensions.add(extension);
      }
    }
    return matchingExtensions;
  }

  /// Discover active or newly spawned tool extensions that support [serviceNamespace],
  /// invoke [method] on each, and decode results using [decoder].
  ///
  /// Combines results from all responding extensions into a single list.
  Future<List<T>> getListFromExtensions<T>(
    String serviceNamespace,
    String method,
    List<T> Function(Object? rpcResult) decoder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final results = <T>[];
    for (final ToolExtension extension in await getExtensionsSupporting(serviceNamespace)) {
      try {
        final Object? rpcResult = await extension.callMethod(method).timeout(timeout);
        results.addAll(decoder(rpcResult));
      } on Object catch (e) {
        _logger.printError('Failed to get results from extension for $method: $e');
      }
    }
    return results;
  }
}
