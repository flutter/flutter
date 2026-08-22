// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/context.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../features.dart';
import 'diagnostics.dart';
import 'extension_discovery.dart';

/// Manages active tool extension isolate connections and exposes capability proxies.
class ExtensionManager {
  /// Creates an [ExtensionManager] targeting the active [hostPlatform].
  ExtensionManager({
    required this.hostPlatform,
    required Logger logger,
    List<ExtensionEntryPoint> entryPoints = const <ExtensionEntryPoint>[],
    ExtensionDiscovery? discovery,
    FeatureFlags? featureFlags,
  }) : _logger = logger,
       _entryPoints = entryPoints,
       _discovery = discovery ?? ExtensionDiscovery(logger: logger),
       _featureFlags = featureFlags ?? context.get<FeatureFlags>()!;

  /// The active [HostPlatform].
  final HostPlatform hostPlatform;
  final Logger _logger;
  final ExtensionDiscovery _discovery;
  final List<ExtensionEntryPoint> _entryPoints;
  final FeatureFlags _featureFlags;
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;
  Future<void>? _initFuture;
  final List<DiagnosticsExtension> _diagnosticsExtensions = <DiagnosticsExtension>[];

  /// Ensures entrypoints are initialized; idempotent.
  Future<void> ensureInitialized() {
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      _isInitialized = true;
      return;
    }
    if (_entryPoints.isNotEmpty) {
      await initialize(entryPoints: _entryPoints);
    } else {
      _isInitialized = true;
    }
  }

  /// Active extension connections compatible with [hostPlatform].
  List<ExtensionConnection> get connections => _discovery.connections;

  /// The operating system name of the host platform (e.g. `'linux'`, `'macos'`, `'windows'`).
  String get hostPlatformName => switch (hostPlatform) {
    HostPlatform.darwin_x64 || HostPlatform.darwin_arm64 => 'macos',
    HostPlatform.linux_x64 || HostPlatform.linux_arm64 || HostPlatform.linux_riscv64 => 'linux',
    HostPlatform.windows_x64 || HostPlatform.windows_arm64 => 'windows',
  };

  /// Spawns entrypoints without host OS checks; disposes any extension that reports
  /// it does not support [hostPlatform].
  Future<void> initialize({
    List<ExtensionEntryPoint> entryPoints = const <ExtensionEntryPoint>[],
  }) async {
    _logger.printTrace(
      'ExtensionManager initializing for platform "$hostPlatformName" with ${entryPoints.length} entrypoint(s).',
    );
    for (final entryPoint in entryPoints) {
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        entryPoint,
        logger: _logger,
      );
      if (connection.capabilities.supportsHostPlatform(hostPlatformName) ||
          connection.capabilities.supportsHostPlatform(hostPlatform.cliName)) {
        _logger.printTrace(
          'Extension connection supported on host platform "$hostPlatformName"; registering.',
        );
        _discovery.registerConnection(connection);
      } else {
        _logger.printTrace(
          'Extension connection does not support host platform "$hostPlatformName" '
          '(supported platforms: ${connection.capabilities.supportedPlatforms}); disposing connection.',
        );
        await connection.dispose();
      }
    }
    _diagnosticsExtensions.clear();
    for (final ExtensionConnection connection in _discovery.connections) {
      if (connection.capabilities.services.contains(DiagnosticsExtension.serviceNamespace)) {
        final client = DiagnosticsExtensionClient(connection, logger: _logger);
        await client.fetchTitle();
        _diagnosticsExtensions.add(client);
      }
    }
    _isInitialized = true;
  }

  /// Active [DiagnosticsExtension] proxies for extensions supporting `'diagnostics'`.
  List<DiagnosticsExtension> get diagnosticsExtensions {
    assert(
      _isInitialized,
      'ExtensionManager.ensureInitialized() must be called before accessing diagnosticsExtensions.',
    );
    return List<DiagnosticsExtension>.unmodifiable(_diagnosticsExtensions);
  }

  /// Disposes all active extension isolate connections.
  Future<void> dispose() async {
    _logger.printTrace('ExtensionManager disposing all active connections.');
    _diagnosticsExtensions.clear();
    _isInitialized = false;
    _initFuture = null;
    await _discovery.dispose();
  }
}
