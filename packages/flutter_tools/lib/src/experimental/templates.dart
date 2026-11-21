// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../features.dart';
import '../template.dart' show kAllCreatePlatforms;
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages querying platform templates from extension isolates.
///
/// Interacts with active [ExtensionConnection]s to discover custom platform
/// identifiers, resolve [ExtensionPlatformTemplate] descriptors and local
/// template directories on the host, and generate platform template parameters
/// over the extension protocol RPC.
base class ExtensionTemplateManager {
  /// Creates an [ExtensionTemplateManager].
  ExtensionTemplateManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._fileSystem,
    required this._flutterRoot,
    required this._logger,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final String _flutterRoot;
  final Logger _logger;

  Map<ExtensionTemplateType, Set<String>>? _cachedPlatforms;
  Future<void>? _loadFuture;
  final _platformOwners = <String, ExtensionConnection>{};

  /// Cached custom platform identifiers for [templateType].
  Set<String> cachedPlatforms(ExtensionTemplateType templateType) =>
      _cachedPlatforms?[templateType] ?? const <String>{};

  /// Retrieves custom platform identifiers for [templateType] by routing
  /// `template.getSupportedPlatforms` to active tool extensions.
  ///
  /// Results are cached after the first call.
  Future<Set<String>> getSupportedPlatforms(ExtensionTemplateType templateType) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String>{};
    }
    await (_loadFuture ??= _loadSupportedPlatforms());
    return cachedPlatforms(templateType);
  }

  Future<void> _loadSupportedPlatforms() async {
    await _extensionManager.ensureInitialized();

    final connections = <ExtensionConnection>[
      for (final ExtensionConnection connection in _extensionManager.connections)
        if (connection.capabilities.services.contains(TemplateService.serviceNamespace)) connection,
    ];

    final platformsByType = <ExtensionTemplateType, Set<String>>{
      for (final ExtensionTemplateType type in ExtensionTemplateType.values) type: <String>{},
    };

    final List<(ExtensionConnection, Object?)> results = await Future.wait(
      connections.map((ExtensionConnection connection) async {
        try {
          return (
            connection,
            await connection.sendRequest(TemplateService.getSupportedPlatformsMethod),
          );
        } on ToolExtensionException catch (e) {
          _logger.printWarning('Extension "${connection.extensionName}": ${e.message}');
          return (connection, null);
        } on Object catch (e) {
          _logger.printTrace(
            'Failed to get supported platforms from extension "${connection.extensionName}": $e',
          );
          return (connection, null);
        }
      }),
    );

    for (final (connection, rpcResult) in results) {
      _collectSupportedPlatforms(
        connection: connection,
        rpcResult: rpcResult,
        platformsByType: platformsByType,
      );
    }

    _cachedPlatforms = <ExtensionTemplateType, Set<String>>{
      for (final MapEntry(:key, :value) in platformsByType.entries)
        key: Set<String>.unmodifiable(value),
    };
  }

  void _collectSupportedPlatforms({
    required ExtensionConnection connection,
    required Object? rpcResult,
    required Map<ExtensionTemplateType, Set<String>> platformsByType,
  }) {
    if (rpcResult is! Map<String, Object?>) {
      return;
    }
    for (final ExtensionTemplateType type in ExtensionTemplateType.values) {
      final Object? rawList = rpcResult[type.name];
      if (rawList is! List<Object?>) {
        continue;
      }
      final Set<String> targetSet = platformsByType[type]!;
      for (final Object? entry in rawList) {
        if (entry is! String || entry.isEmpty) {
          continue;
        }
        if (kAllCreatePlatforms.contains(entry)) {
          _logger.printWarning(
            'Extension "${connection.extensionName}" attempted to register ${type.name} '
            'platform template "$entry", which conflicts with a built-in Flutter platform. '
            'Ignoring extension template mapping.',
          );
          continue;
        }
        final ExtensionConnection? existingOwner = _platformOwners[entry];
        if (existingOwner != null && existingOwner != connection) {
          if (targetSet.contains(entry)) {
            _logger.printWarning(
              'Duplicate ${type.name} platform template "$entry" provided by extension '
              '"${connection.extensionName}" (already registered by extension '
              '"${existingOwner.extensionName}"). Ignoring subsequent template mapping.',
            );
          } else {
            _logger.printWarning(
              'Conflicting ${type.name} platform template "$entry" provided by extension '
              '"${connection.extensionName}" (platform already registered by extension '
              '"${existingOwner.extensionName}"). Ignoring subsequent template mapping.',
            );
          }
        } else {
          targetSet.add(entry);
          _platformOwners[entry] = connection;
        }
      }
    }
  }

  /// Resolves the [ExtensionPlatformTemplate] descriptor for [platform] and
  /// [templateType] over RPC.
  Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
    required String platform,
    required ExtensionTemplateType templateType,
    required Map<String, Object?> toolParameters,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return null;
    }

    await (_loadFuture ??= _loadSupportedPlatforms());

    final ExtensionConnection? owner = _platformOwners[platform];
    if (owner == null || !cachedPlatforms(templateType).contains(platform)) {
      return null;
    }

    final Object? result;
    try {
      result = await owner.sendRequest(
        TemplateService.resolvePlatformTemplateMethod,
        params: <String, Object?>{
          TemplateService.platformParam: platform,
          TemplateService.templateTypeParam: templateType.name,
          TemplateService.toolParametersParam: toolParameters,
        },
      );
    } on ToolExtensionException catch (e) {
      throwToolExit(e.message);
    } on Object catch (e) {
      throwToolExit(
        'Failed to resolve platform template from extension "${owner.extensionName}" '
        'for platform "$platform": $e',
      );
    }

    if (result == null) {
      return null;
    }
    if (result is! Map<String, Object?>) {
      throwToolExit(
        'Invalid platform template descriptor from extension "${owner.extensionName}" '
        'for platform "$platform": expected Map<String, Object?>?, got ${result.runtimeType}.',
      );
    }
    try {
      return ExtensionPlatformTemplate.fromJson(result);
    } on FormatException catch (e) {
      throwToolExit(
        'Invalid platform template descriptor from extension "${owner.extensionName}" '
        'for platform "$platform": ${e.message}',
      );
    }
  }

  /// Resolves a [template]'s `package:` URI to a local directory.
  ///
  /// Currently only supports `package:flutter_tools/` and
  /// `package:flutter_tools_extension_linux_prototype/` URIs, resolving them
  /// relative to the Flutter SDK root.
  Directory resolveTemplateDirectory(ExtensionPlatformTemplate template) {
    final List<String> segments = template.templateUri.pathSegments;
    final String packageName = segments.first;
    // TODO(bkonyi): Resolve package URIs generically using package config or discovered paths.
    final String packageLibPath = switch (packageName) {
      'flutter_tools' => _fileSystem.path.join(_flutterRoot, 'packages', 'flutter_tools', 'lib'),
      'flutter_tools_extension_linux_prototype' => _fileSystem.path.join(
        _flutterRoot,
        'packages',
        'flutter_tools',
        'packages',
        'flutter_tools_extension_linux_prototype',
        'lib',
      ),
      _ => throw ArgumentError.value(
        template.templateUri,
        'template',
        'Unsupported template package: "$packageName".',
      ),
    };
    return _fileSystem.directory(
      _fileSystem.path.joinAll(<String>[packageLibPath, ...segments.skip(1)]),
    );
  }

  /// Requests platform template parameter generation over extension protocol RPC.
  ///
  /// Delegates parameter generation for [platform] to the active tool
  /// extension that provides platform support for [platform], passing the
  /// host's [toolParameters]. Falls back to returning [toolParameters] unchanged
  /// if the extension fails, does not modify parameters, or is not available.
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platform,
    required Map<String, Object?> toolParameters,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return toolParameters;
    }

    await (_loadFuture ??= _loadSupportedPlatforms());

    final ExtensionConnection? owner = _platformOwners[platform];
    if (owner == null) {
      return toolParameters;
    }

    try {
      final Object? result = await owner.sendRequest(
        TemplateService.generatePlatformTemplateParametersMethod,
        params: <String, Object?>{
          TemplateService.platformParam: platform,
          TemplateService.toolParametersParam: toolParameters,
        },
      );
      if (result is Map<String, Object?>) {
        return result;
      }
    } on ToolExtensionException catch (e) {
      throwToolExit(e.message);
    } on Object catch (e) {
      _logger.printTrace(
        'Failed to generate platform template parameters from extension '
        '"${owner.extensionName}": $e',
      );
    }

    return toolParameters;
  }
}
