// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../generic_extension_protocol.dart';
import '../base/logger.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../globals.dart' as globals;

/// Helper class for discovering tool extensions supporting specific services.
class ExtensionDiscoveryHelper {
  /// Create a new instance of [ExtensionDiscoveryHelper].
  ExtensionDiscoveryHelper({required this.extensionManager, required this.logger});

  /// The extension manager used to manage extension isolates.
  final ToolExtensionManager extensionManager;

  /// The logger used for reporting errors and traces.
  final Logger logger;

  /// Timeout duration for querying capabilities from an extension isolate.
  static const Duration capabilitiesTimeout = Duration(seconds: 5);

  /// Returns a list of [ToolExtension]s that support the requested [serviceNamespace].
  ///
  /// Checks whether [globals.isToolExtensionPrototypeEnabled] is true when starting a new
  /// prototype extension if no extensions are active, queries capabilities with a timeout,
  /// and filters the extensions by [serviceNamespace].
  Future<List<ToolExtension>> getExtensionsSupporting(
    String serviceNamespace, {
    bool throwOnFailure = false,
  }) async {
    if (extensionManager.extensions.isEmpty) {
      if (!globals.isToolExtensionPrototypeEnabled) {
        return const <ToolExtension>[];
      }
      try {
        await extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        if (throwOnFailure) {
          rethrow;
        }
        logger.printError('Failed to spawn prototype extension: $e');
        return const <ToolExtension>[];
      }
    }

    final extensions = <ToolExtension>[];
    for (final ToolExtension extension in extensionManager.extensions) {
      final bool supported = await isServiceSupported(
        extension,
        serviceNamespace,
        throwOnFailure: throwOnFailure,
      );
      if (supported) {
        extensions.add(extension);
      }
    }
    return extensions;
  }

  /// Checks whether a specific [extension] supports the given [serviceNamespace].
  Future<bool> isServiceSupported(
    ToolExtension extension,
    String serviceNamespace, {
    bool throwOnFailure = false,
  }) async {
    final ToolExtensionCapabilities capabilities;
    try {
      capabilities = await extension.getCapabilities().timeout(capabilitiesTimeout);
    } on Object catch (e) {
      if (throwOnFailure) {
        rethrow;
      }
      logger.printTrace('Failed to get capabilities: $e');
      return false;
    }
    return capabilities.services.contains(serviceNamespace);
  }
}
