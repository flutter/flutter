// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../features.dart';
import 'extension_discovery.dart';

/// Manages active tool extension isolate connections and exposes capability proxies.
class ExtensionManager {
  /// Creates an [ExtensionManager] targeting the active [hostPlatform].
  ExtensionManager({
    required this.hostPlatform,
    required Logger logger,
    ExtensionDiscovery? discovery,
    FeatureFlags? featureFlags,
  }) : _logger = logger,
       _discovery = discovery ?? ExtensionDiscovery(logger: logger),
       _featureFlags = featureFlags ?? context.get<FeatureFlags>()!;

  /// The active [HostPlatform].
  final HostPlatform hostPlatform;
  final Logger _logger;
  final ExtensionDiscovery _discovery;
  final FeatureFlags _featureFlags;

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
    if (!_featureFlags.isToolExtensionsEnabled) {
      return;
    }
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
  }

  /// Disposes all active extension isolate connections.
  Future<void> dispose() async {
    _logger.printTrace('ExtensionManager disposing all active connections.');
    await _discovery.dispose();
  }
}
