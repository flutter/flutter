// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../features.dart';
import 'config.dart';
import 'diagnostics.dart';
import 'extension_device_manager.dart';
import 'extension_discovery.dart';
import 'extension_kernel_compiler.dart';
import 'project_extension_finder.dart';

/// Typedef for spawning an extension connection from a URI and package config.
typedef ExtensionUriSpawner = Future<ExtensionConnection> Function(
  Uri entrypointUri, {
  required Logger logger,
  required Uri packageConfigUri,
  ExtensionPackageConfig? expectedConfig,
  String? extensionName,
});

/// Manages active tool extension isolate connections and exposes capability proxies.
class ExtensionManager {
  /// Creates an [ExtensionManager] targeting the active [hostPlatform].
  ExtensionManager({
    required this._featureFlags,
    required this.hostPlatform,
    required Logger logger,
    ExtensionDiscovery? discovery,
    @visibleForTesting this._entryPoints = const <ExtensionEntryPoint>[],
    this._extensionFinder,
    this._kernelCompiler,
    ExtensionUriSpawner? uriSpawner,
  }) : _logger = logger,
       _discovery = discovery ?? ExtensionDiscovery(logger: logger),
       _uriSpawner = uriSpawner ?? ExtensionConnection.spawnUri;

  /// The active [HostPlatform].
  final HostPlatform hostPlatform;
  final Logger _logger;
  final ExtensionDiscovery _discovery;
  final List<ExtensionEntryPoint> _entryPoints;
  final FeatureFlags _featureFlags;
  final ProjectExtensionFinder? _extensionFinder;
  final ExtensionKernelCompiler? _kernelCompiler;
  final ExtensionUriSpawner _uriSpawner;

  /// Monotonically increasing generation counter incremented whenever the set of
  /// registered extension connections changes.
  int get connectionGeneration => _connectionGeneration;
  int _connectionGeneration = 0;

  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;
  bool _isDisabled = false;
  bool get _isDisposed => _disposeFuture != null;
  bool _entryPointsSpawned = false;
  Future<void>? _initFuture;
  Future<void>? _disposeFuture;

  /// Disables tool extension discovery and initialization for the current CLI
  /// invocation (for example, when `--no-extensions` is passed).
  void disable() {
    assert(_initFuture == null, 'disable() cannot be called after initialization has started.');
    _isDisabled = true;
  }

  final _discoveredByPackageName = <String, DiscoveredProjectExtension>{};
  final _discoveredDirs = <String>{};
  final _spawnedExtensionNames = <String>{};
  final _failedExtensionNames = <String>{};
  final _registeredClientConnections = <ExtensionConnection>{};

  final _diagnosticsExtensions = <DiagnosticsExtension>[];
  final _configurationExtensions = <ConfigurationExtension>[];
  final _deviceExtensions = <DeviceService>[];

  /// Project extensions discovered via `extension/flutter_tools/config.yaml` and
  /// `.dart_tool/package_config.json` that support [hostPlatform].
  List<DiscoveredProjectExtension> get discoveredExtensions =>
      List<DiscoveredProjectExtension>.unmodifiable(_discoveredByPackageName.values);

  /// Discovers project extensions starting from [startDir] using static
  /// `extension/flutter_tools/config.yaml` metadata without spawning isolates.
  Future<List<DiscoveredProjectExtension>> discoverExtensions({Directory? startDir}) async {
    if (_isDisabled || !_featureFlags.isToolExtensionsEnabled) {
      return const <DiscoveredProjectExtension>[];
    }
    final ProjectExtensionFinder? finder = _extensionFinder;
    if (finder == null) {
      return discoveredExtensions;
    }
    final String cacheKey = startDir?.absolute.path ?? '';
    if (_discoveredDirs.contains(cacheKey)) {
      return discoveredExtensions;
    }
    final List<DiscoveredProjectExtension> found = await finder.findProjectExtensions(
      startDirectory: startDir,
    );
    if (found.isNotEmpty) {
      _discoveredDirs.add(cacheKey);
    }
    for (final ext in found) {
      if (ext.config.supportsHostPlatform(hostPlatformName) ||
          ext.config.supportsHostPlatform(hostPlatform.cliName)) {
        _discoveredByPackageName[ext.name] = ext;
      } else {
        _logger.printTrace(
          'Extension "${ext.name}" does not support host platform "$hostPlatformName" '
          '(host platforms: ${ext.config.hostPlatforms}); skipping.',
        );
      }
    }
    return discoveredExtensions;
  }

  /// Ensures entrypoints and discovered project extensions matching
  /// [requiredServices] are compiled and initialized.
  ///
  /// When [requiredServices] is non-null, only discovered project extensions
  /// whose static `extension/flutter_tools/config.yaml` declares at least one
  /// service in [requiredServices] are compiled and spawned.
  ///
  /// Returns immediately as a no-op if [dispose] has already been called.
  Future<void> ensureInitialized({Set<String>? requiredServices, Directory? startDir}) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final Future<void>? previous = _initFuture;
    final Future<void> next = previous == null
        ? _doInitialize(requiredServices: requiredServices, startDir: startDir)
        : previous.then(
            (_) => _doInitialize(requiredServices: requiredServices, startDir: startDir),
          );
    _initFuture = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _doInitialize({Set<String>? requiredServices, Directory? startDir}) async {
    if (_isDisposed) {
      return;
    }
    if (_isDisabled || !_featureFlags.isToolExtensionsEnabled) {
      _isInitialized = true;
      return;
    }

    if (_entryPoints.isNotEmpty && !_entryPointsSpawned) {
      _entryPointsSpawned = true;
      await _initialize(entryPoints: _entryPoints);
      if (_isDisposed) {
        return;
      }
    }

    await discoverExtensions(startDir: startDir);
    if (_isDisposed) {
      return;
    }

    final toSpawn = <DiscoveredProjectExtension>[
      for (final DiscoveredProjectExtension ext in _discoveredByPackageName.values)
        if (!_spawnedExtensionNames.contains(ext.name) &&
            !_failedExtensionNames.contains(ext.name) &&
            (requiredServices == null || ext.config.services.any(requiredServices.contains)))
          ext,
    ];

    for (final ext in toSpawn) {
      if (_isDisposed) {
        return;
      }
      try {
        final CompiledExtensionKernel? compiled = _kernelCompiler != null
            ? await _kernelCompiler.compile(ext)
            : null;
        if (_isDisposed) {
          return;
        }
        final ExtensionConnection connection = await _uriSpawner(
          compiled?.dillUri ?? ext.entrypointUri,
          expectedConfig: ext.config,
          logger: _logger,
          packageConfigUri: ext.packageConfigUri,
          extensionName: ext.name,
        );
        if (_isDisposed) {
          await connection.dispose();
          return;
        }
        _spawnedExtensionNames.add(ext.name);
        await _registerOrDisposeConnection(connection);
      } on Object catch (error) {
        _failedExtensionNames.add(ext.name);
        _logger.printWarning('Failed to initialize tool extension "${ext.name}": $error');
      }
    }

    await _populateServiceClients();
    if (!_isDisposed) {
      _isInitialized = true;
    }
  }

  /// Active extension connections compatible with [hostPlatform].
  List<ExtensionConnection> get connections =>
      _isDisposed ? const <ExtensionConnection>[] : _discovery.connections;

  /// The operating system name of the host platform (e.g. `'linux'`, `'macos'`, `'windows'`).
  String get hostPlatformName => hostPlatform.osName == 'darwin' ? 'macos' : hostPlatform.osName;

  /// Spawns [entryPoints] without host OS checks; disposes any extension that reports
  /// it does not support [hostPlatform].
  ///
  /// Returns immediately as a no-op if [dispose] has already been called.
  @visibleForTesting
  Future<void> initialize({
    List<ExtensionEntryPoint> entryPoints = const <ExtensionEntryPoint>[],
  }) async {
    if (_isDisposed) {
      return;
    }
    assert(_initFuture == null, 'initialize() cannot be called after initialization has started.');
    await (_initFuture = _initialize(entryPoints: entryPoints));
  }

  Future<void> _initialize({required List<ExtensionEntryPoint> entryPoints}) async {
    _logger.printTrace(
      'ExtensionManager initializing for platform "$hostPlatformName" with ${entryPoints.length} entrypoint(s).',
    );
    for (final entryPoint in entryPoints) {
      // ignore: invalid_use_of_visible_for_testing_member, transitional until #194774.
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        entryPoint,
        logger: _logger,
      );
      if (_isDisposed) {
        await connection.dispose();
        return;
      }
      await _registerOrDisposeConnection(connection);
      if (_isDisposed) {
        return;
      }
    }
    await _populateServiceClients();
    if (!_isDisposed) {
      _isInitialized = true;
    }
  }

  Future<void> _registerOrDisposeConnection(ExtensionConnection connection) async {
    if (connection.capabilities.supportsHostPlatform(hostPlatformName) ||
        connection.capabilities.supportsHostPlatform(hostPlatform.cliName)) {
      _logger.printTrace(
        'Extension connection supported on host platform "$hostPlatformName"; registering.',
      );
      _discovery.registerConnection(connection);
      _connectionGeneration++;
    } else {
      _logger.printTrace(
        'Extension connection does not support host platform "$hostPlatformName" '
        '(supported platforms: ${connection.capabilities.supportedPlatforms}); disposing connection.',
      );
      await connection.dispose();
    }
  }

  Future<void> _populateServiceClients() async {
    for (final ExtensionConnection connection in _discovery.connections) {
      if (_registeredClientConnections.contains(connection)) {
        continue;
      }
      _registeredClientConnections.add(connection);
      if (connection.capabilities.services.contains(DiagnosticsExtension.serviceNamespace)) {
        final client = DiagnosticsExtensionClient(connection, logger: _logger);
        await client.fetchTitle();
        if (_isDisposed) {
          return;
        }
        _diagnosticsExtensions.add(client);
      }
      if (connection.capabilities.services.contains(ConfigurationExtension.serviceNamespace)) {
        final client = ConfigurationExtensionClient(connection, logger: _logger);
        await client.fetchTitle();
        if (_isDisposed) {
          return;
        }
        _configurationExtensions.add(client);
      }
      if (connection.capabilities.services.contains(DeviceService.serviceNamespace)) {
        _deviceExtensions.add(ExtensionDeviceClient(connection, logger: _logger));
      }
    }
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
  Future<void> dispose() => _disposeFuture ??= _doDispose();

  Future<void> _doDispose() async {
    _logger.printTrace('ExtensionManager disposing all active connections.');
    _diagnosticsExtensions.clear();
    _configurationExtensions.clear();
    _deviceExtensions.clear();
    _discoveredByPackageName.clear();
    _discoveredDirs.clear();
    _spawnedExtensionNames.clear();
    _failedExtensionNames.clear();
    _registeredClientConnections.clear();
    _entryPointsSpawned = false;
    _isInitialized = false;
    _connectionGeneration++;
    try {
      await _initFuture;
    } on Object {
      // Ignore initialization errors during disposal so cleanup still runs.
    }
    await _discovery.dispose();
  }
}
