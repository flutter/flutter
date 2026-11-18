// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

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

  final _discoveredByPackageName = SplayTreeMap<String, DiscoveredProjectExtension>();
  final _discoveredCache = <(String, bool), List<DiscoveredProjectExtension>>{};
  final _activeExtensionNames = <String>{};
  final _failedExtensionNames = <String>{};
  final _registeredClientConnections = <ExtensionConnection>{};

  final _diagnosticsExtensions = <DiagnosticsExtension>[];
  final _configurationExtensions = <ConfigurationExtension>[];
  final _deviceExtensions = <DeviceService>[];

  /// Project extensions discovered via `extension/flutter_tools/extension.dart`
  /// and `.dart_tool/package_config.json`, sorted deterministically by package name.
  List<DiscoveredProjectExtension> get discoveredExtensions =>
      List<DiscoveredProjectExtension>.unmodifiable(_discoveredByPackageName.values);

  /// Discovers project extensions starting from [startDir] via
  /// `.dart_tool/package_config.json` and `extension/flutter_tools/extension.dart`
  /// without compiling or spawning isolates.
  ///
  /// When [includeWorkspaceMembers] is `true` and the search directory is a Pub
  /// workspace root, direct dependencies across all `workspace:` member
  /// `pubspec.yaml` files are included as well.
  Future<List<DiscoveredProjectExtension>> discoverExtensions({
    bool includeWorkspaceMembers = false,
    Directory? startDir,
  }) async {
    if (_isDisabled || _isDisposed || !_featureFlags.isToolExtensionsEnabled) {
      return const <DiscoveredProjectExtension>[];
    }
    final ProjectExtensionFinder? finder = _extensionFinder;
    if (finder == null) {
      return discoveredExtensions;
    }
    final (String, bool) cacheKey = (startDir?.absolute.path ?? '', includeWorkspaceMembers);
    if (_discoveredCache[cacheKey] case final List<DiscoveredProjectExtension> cached) {
      return cached;
    }
    final List<DiscoveredProjectExtension> found = await finder.findProjectExtensions(
      includeWorkspaceMembers: includeWorkspaceMembers,
      startDirectory: startDir,
    );
    if (_isDisposed) {
      return const <DiscoveredProjectExtension>[];
    }
    for (final ext in found) {
      _discoveredByPackageName[ext.name] = ext;
    }
    final unmodifiableFound = List<DiscoveredProjectExtension>.unmodifiable(found);
    if (found.isNotEmpty) {
      _discoveredCache[cacheKey] = unmodifiableFound;
    }
    return unmodifiableFound;
  }

  /// Ensures entrypoints and discovered project extensions matching
  /// [requiredServices] are compiled and initialized.
  ///
  /// Extensions with up-to-date cached [ToolExtensionCapabilities] are skipped
  /// without spawning an isolate when their `supportedPlatforms` excludes
  /// [hostPlatform] or their `services` do not intersect [requiredServices].
  /// Cold or invalidated `.dill` snapshots are compiled and spawned once to
  /// record cached capabilities, and disposed immediately if they do not match
  /// [hostPlatform] or [requiredServices].
  ///
  /// Returns immediately as a no-op if [dispose] has already been called.
  Future<void> ensureInitialized({
    bool includeWorkspaceMembers = false,
    Set<String>? requiredServices,
    Directory? startDir,
  }) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final Future<void>? previous = _initFuture;
    final Future<void> next = previous == null
        ? _doInitialize(
            includeWorkspaceMembers: includeWorkspaceMembers,
            requiredServices: requiredServices,
            startDir: startDir,
          )
        : previous.then(
            (_) => _doInitialize(
              includeWorkspaceMembers: includeWorkspaceMembers,
              requiredServices: requiredServices,
              startDir: startDir,
            ),
          );
    _initFuture = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _doInitialize({
    required bool includeWorkspaceMembers,
    Set<String>? requiredServices,
    Directory? startDir,
  }) async {
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

    final List<DiscoveredProjectExtension> discovered = await discoverExtensions(
      includeWorkspaceMembers: includeWorkspaceMembers,
      startDir: startDir,
    );
    if (_isDisposed) {
      return;
    }

    final ExtensionKernelCompiler? compiler = _kernelCompiler;
    for (final ext in discovered) {
      if (_isDisposed) {
        return;
      }
      if (_activeExtensionNames.contains(ext.name) || _failedExtensionNames.contains(ext.name)) {
        continue;
      }

      final ToolExtensionCapabilities? cachedCapabilities = compiler?.readCachedCapabilities(ext);
      if (cachedCapabilities != null && !_isCompatible(ext, cachedCapabilities, requiredServices)) {
        continue;
      }

      try {
        final CompiledExtensionKernel? compiled = compiler != null
            ? await compiler.compile(ext)
            : null;
        if (_isDisposed) {
          return;
        }
        final ExtensionConnection connection = await _uriSpawner(
          compiled?.dillUri ?? ext.entrypointUri,
          extensionName: ext.name,
          logger: _logger,
          packageConfigUri: ext.packageConfigUri,
        );
        if (_isDisposed) {
          await connection.dispose();
          return;
        }
        if (cachedCapabilities == null && compiled != null && compiler != null) {
          await compiler.writeCachedCapabilities(
            ext,
            connection.capabilities,
            buildToken: compiled.buildToken,
          );
          if (_isDisposed) {
            await connection.dispose();
            return;
          }
        }
        if (!_isCompatible(ext, connection.capabilities, requiredServices)) {
          await connection.dispose();
          if (_isDisposed) {
            return;
          }
          continue;
        }
        _logger.printTrace(
          'Extension "${ext.name}" supported on host platform "$hostPlatformName"; registering.',
        );
        _activeExtensionNames.add(ext.name);
        _discovery.registerConnection(connection);
        _connectionGeneration++;
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

  bool _isCompatible(
    DiscoveredProjectExtension ext,
    ToolExtensionCapabilities capabilities,
    Set<String>? requiredServices,
  ) {
    if (!_supportsHostPlatform(capabilities)) {
      _logger.printTrace(
        'Extension "${ext.name}" does not support host platform "$hostPlatformName" '
        '(supported platforms: ${capabilities.supportedPlatforms}); skipping.',
      );
      return false;
    }
    if (requiredServices != null && !capabilities.services.any(requiredServices.contains)) {
      _logger.printTrace(
        'Extension "${ext.name}" services ${capabilities.services} do not match '
        'required services $requiredServices; skipping.',
      );
      return false;
    }
    return true;
  }

  bool _supportsHostPlatform(ToolExtensionCapabilities capabilities) =>
      capabilities.supportsHostPlatform(hostPlatformName) ||
      capabilities.supportsHostPlatform(hostPlatform.cliName);

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
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        entryPoint,
        logger: _logger,
      );
      if (_isDisposed) {
        await connection.dispose();
        return;
      }
      if (_supportsHostPlatform(connection.capabilities)) {
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
        if (_isDisposed) {
          return;
        }
      }
    }
    await _populateServiceClients();
    if (!_isDisposed) {
      _isInitialized = true;
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
    _discoveredCache.clear();
    _activeExtensionNames.clear();
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
