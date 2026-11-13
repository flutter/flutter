// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/logger.dart';
import '../base/os.dart';
import '../features.dart';
import 'config.dart';
import 'diagnostics.dart';
import 'extension_device_manager.dart';
import 'extension_discovery.dart';

/// Manages active tool extension isolate connections and exposes capability proxies.
class ExtensionManager {
  /// Creates an [ExtensionManager] targeting the active [hostPlatform].
  ExtensionManager({
    required this._featureFlags,
    required this.hostPlatform,
    required Logger logger,
    this._entryPoints = const <ExtensionEntryPoint>[],
    ExtensionDiscovery? discovery,
  }) : _logger = logger,
       _discovery = discovery ?? ExtensionDiscovery(logger: logger);

  /// The active [HostPlatform].
  final HostPlatform hostPlatform;
  final Logger _logger;
  final ExtensionDiscovery _discovery;
  final List<ExtensionEntryPoint> _entryPoints;
  final FeatureFlags _featureFlags;
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;
  bool _isDisabled = false;
  bool _isDisposed = false;
  Future<void>? _initFuture;
  Future<void>? _disposeFuture;
  final _diagnosticsExtensions = <DiagnosticsExtension>[];
  final _configurationExtensions = <ConfigurationExtension>[];
  final _deviceExtensions = <DeviceService>[];

  /// Disables tool extension initialization for the current CLI invocation
  /// (for example, when `--no-extensions` is passed).
  void disable() {
    assert(_initFuture == null, 'disable() cannot be called after initialization has started.');
    _isDisabled = true;
  }

  /// Ensures entrypoints are initialized; idempotent.
  ///
  /// Returns immediately as a no-op if [dispose] has already been called.
  Future<void> ensureInitialized() {
    if (_isDisposed) {
      return Future<void>.value();
    }
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    if (_isDisabled || !_featureFlags.isToolExtensionsEnabled) {
      _isInitialized = true;
      return;
    }
    if (_entryPoints.isNotEmpty) {
      await _initialize(entryPoints: _entryPoints);
    } else {
      _isInitialized = true;
    }
  }

  /// Active extension connections compatible with [hostPlatform].
  List<ExtensionConnection> get connections => _discovery.connections;

  /// The operating system name of the host platform (e.g. `'linux'`, `'macos'`, `'windows'`).
  String get hostPlatformName => hostPlatform.osName == 'darwin' ? 'macos' : hostPlatform.osName;

  /// Spawns entrypoints without host OS checks; disposes any extension that reports
  /// it does not support [hostPlatform].
  ///
  /// Returns immediately as a no-op if [dispose] has already been called.
  Future<void> initialize({List<ExtensionEntryPoint> entryPoints = const <ExtensionEntryPoint>[]}) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    return _initFuture = _initialize(entryPoints: entryPoints);
  }

  Future<void> _initialize({required List<ExtensionEntryPoint> entryPoints}) async {
    _logger.printTrace(
      'ExtensionManager initializing for platform "$hostPlatformName" with ${entryPoints.length} entrypoint(s).',
    );
    for (final entryPoint in entryPoints) {
      if (_isDisposed) {
        return;
      }
      // ignore: invalid_use_of_visible_for_testing_member, transitional until #194774.
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        entryPoint,
        logger: _logger,
      );
      if (_isDisposed) {
        await connection.dispose();
        return;
      }
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
    _configurationExtensions.clear();
    _deviceExtensions.clear();
    for (final ExtensionConnection connection in _discovery.connections) {
      if (_isDisposed) {
        return;
      }
      if (connection.capabilities.services.contains(DiagnosticsExtension.serviceNamespace)) {
        final client = DiagnosticsExtensionClient(connection, logger: _logger);
        await client.fetchTitle();
        _diagnosticsExtensions.add(client);
      }
      if (connection.capabilities.services.contains(ConfigurationExtension.serviceNamespace)) {
        final client = ConfigurationExtensionClient(connection, logger: _logger);
        await client.fetchTitle();
        _configurationExtensions.add(client);
      }
      if (connection.capabilities.services.contains(DeviceService.serviceNamespace)) {
        final client = ExtensionDeviceClient(connection, logger: _logger);
        _deviceExtensions.add(client);
      }
    }
    if (_isDisposed) {
      return;
    }
    _isInitialized = true;
  }

  /// Active [DiagnosticsExtension] proxies for extensions supporting `'diagnostics'`.
  List<DiagnosticsExtension> get diagnosticsExtensions {
    assert(
      _isInitialized || _isDisposed,
      'ExtensionManager.ensureInitialized() must be called before accessing diagnosticsExtensions.',
    );
    return List<DiagnosticsExtension>.unmodifiable(_diagnosticsExtensions);
  }

  /// Active [ConfigurationExtension] proxies for extensions supporting `'config'`.
  List<ConfigurationExtension> get configurationExtensions {
    assert(
      _isInitialized || _isDisposed,
      'ExtensionManager.ensureInitialized() must be called before accessing configurationExtensions.',
    );
    return List<ConfigurationExtension>.unmodifiable(_configurationExtensions);
  }

  /// Active [DeviceService] proxies for extensions supporting `'device'`.
  List<DeviceService> get deviceExtensions {
    assert(
      _isInitialized || _isDisposed,
      'ExtensionManager.ensureInitialized() must be called before accessing deviceExtensions.',
    );
    return List<DeviceService>.unmodifiable(_deviceExtensions);
  }

  /// Disposes all active extension isolate connections.
  ///
  /// If initialization is currently in flight, waits for it to finish before
  /// disposing registered connections. Subsequent calls to [ensureInitialized]
  /// or [initialize] after [dispose] is invoked are no-ops.
  Future<void> dispose() {
    _isDisposed = true;
    return _disposeFuture ??= _doDispose();
  }

  Future<void> _doDispose() async {
    _logger.printTrace('ExtensionManager disposing all active connections.');
    try {
      await _initFuture;
    } on Object {
      // Ignore initialization errors during disposal so cleanup still runs.
    }
    _diagnosticsExtensions.clear();
    _configurationExtensions.clear();
    _deviceExtensions.clear();
    _isInitialized = false;
    await _discovery.dispose();
  }
}
