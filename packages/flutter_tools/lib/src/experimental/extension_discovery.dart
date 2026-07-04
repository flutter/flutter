// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../generic_extension_protocol.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../globals.dart' as globals;

/// A helper class for abstracting extension isolate spawning and capability querying.
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

  /// The logger used by this helper.
  Logger get logger => _logger;

  /// The extension manager used by this helper.
  ToolExtensionManager? get extensionManager => _extensionManager;

  /// Environment variable key to enable tool extension prototype features.
  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';

  /// Whether the host platform enables tool extension prototype features.
  bool get isPrototypeEnabled => _platform != null
      ? _platform.environment[envPrototypeFlag] == 'true'
      : globals.isToolExtensionPrototypeEnabled;

  /// Query the capabilities of a [ToolExtension] with a timeout.
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
  Future<List<ToolExtension>> getExtensionsSupporting(
    String serviceNamespace, {
    bool throwOnFailure = false,
  }) async {
    final ToolExtensionManager? extensionManager = _extensionManager;
    if (extensionManager == null) {
      return const <ToolExtension>[];
    }

    if (extensionManager.extensions.isEmpty) {
      if (!isPrototypeEnabled) {
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

  /// Query extensions supporting [serviceNamespace] and invoke [method], decoding results with [decoder].
  Future<List<T>> getListFromExtensions<T>(
    String serviceNamespace,
    String method,
    List<T> Function(Object? rpcResult) decoder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isPrototypeEnabled) {
      return <T>[];
    }
    final List<ToolExtension> matchingExtensions = await getExtensionsSupporting(serviceNamespace);
    final results = <T>[];
    for (final extension in matchingExtensions) {
      try {
        final Object? rpcResult = await extension.callMethod(method).timeout(timeout);
        results.addAll(decoder(rpcResult));
      } on Object catch (e) {
        _logger.printError('Failed to get $method from extension: $e');
      }
    }
    return results;
  }
}
