// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../features.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages querying platform templates from extension isolates.
///
/// This manager interacts with active [ExtensionConnection]s to discover custom
/// platform templates, resolve their directories on the host, and generate
/// platform template parameters over the extension protocol RPC.
base class ExtensionTemplateManager {
  /// Creates an [ExtensionTemplateManager].
  ExtensionTemplateManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._fileSystem,
    required this._flutterRoot,
    required this._logger,
  });

  static const _appTemplateKind = 'app';
  static const _pluginTemplateKind = 'plugin';

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final String _flutterRoot;
  final Logger _logger;

  Map<String, String>? _cachedAppPlatformTemplates;
  Map<String, String>? _cachedPluginPlatformTemplates;
  Future<void>? _loadFuture;
  final _platformOwners = <String, ExtensionConnection>{};

  /// Retrieve the cached app platform templates synchronously.
  Map<String, String> get cachedAppPlatformTemplates =>
      _cachedAppPlatformTemplates ?? const <String, String>{};

  /// Retrieve the cached plugin platform templates synchronously.
  Map<String, String> get cachedPluginPlatformTemplates =>
      _cachedPluginPlatformTemplates ?? const <String, String>{};

  /// Retrieve app platform templates by routing `template.getAppPlatformTemplates` to active tool extensions.
  ///
  /// Results are cached after the first successful call.
  Future<Map<String, String>> getAppPlatformTemplates() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, String>{};
    }
    await (_loadFuture ??= _loadPlatformTemplates());
    return _cachedAppPlatformTemplates!;
  }

  /// Retrieve plugin platform templates by routing `template.getPluginPlatformTemplates` to active tool extensions.
  ///
  /// Results are cached after the first successful call.
  Future<Map<String, String>> getPluginPlatformTemplates() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, String>{};
    }
    await (_loadFuture ??= _loadPlatformTemplates());
    return _cachedPluginPlatformTemplates!;
  }

  Future<void> _loadPlatformTemplates() async {
    await _extensionManager.ensureInitialized();

    final appTemplates = <String, String>{};
    final pluginTemplates = <String, String>{};
    final List<ExtensionConnection> connections = _extensionManager.connections
        .where(
          (ExtensionConnection c) =>
              c.capabilities.services.contains(TemplateService.serviceNamespace),
        )
        .toList();

    final List<(ExtensionConnection, Object?, Object?)> results = await Future.wait(
      connections.map((ExtensionConnection connection) async {
        final (Object? appResult, Object? pluginResult) = await (
          _requestPlatformTemplates(
            connection: connection,
            method: TemplateService.getAppPlatformTemplatesMethod,
          ),
          _requestPlatformTemplates(
            connection: connection,
            method: TemplateService.getPluginPlatformTemplatesMethod,
          ),
        ).wait;
        return (connection, appResult, pluginResult);
      }),
    );

    for (final (connection, appResult, pluginResult) in results) {
      _collectPlatformTemplates(
        connection: connection,
        rpcResult: appResult,
        targetMap: appTemplates,
        templateKind: _appTemplateKind,
      );
      _collectPlatformTemplates(
        connection: connection,
        rpcResult: pluginResult,
        targetMap: pluginTemplates,
        templateKind: _pluginTemplateKind,
      );
    }

    _cachedAppPlatformTemplates = appTemplates;
    _cachedPluginPlatformTemplates = pluginTemplates;
  }

  Future<Object?> _requestPlatformTemplates({
    required ExtensionConnection connection,
    required String method,
  }) async {
    try {
      return await connection.sendRequest(method);
    } on Object catch (e) {
      _logger.printTrace('Failed to get results from extension for $method: $e');
      return null;
    }
  }

  void _collectPlatformTemplates({
    required ExtensionConnection connection,
    required Object? rpcResult,
    required Map<String, String> targetMap,
    required String templateKind,
  }) {
    if (rpcResult is! Map<String, Object?>) {
      return;
    }
    for (final MapEntry(:key, :value) in rpcResult.entries) {
      if (value is! String) {
        continue;
      }
      final ExtensionConnection? existingOwner = _platformOwners[key];
      if (existingOwner != null && existingOwner != connection) {
        if (targetMap.containsKey(key)) {
          _logger.printWarning(
            'Duplicate $templateKind platform template "$key" provided by extension '
            '"${connection.extensionName}" (already registered by extension '
            '"${existingOwner.extensionName}"). Ignoring subsequent template mapping.',
          );
        } else {
          _logger.printWarning(
            'Conflicting $templateKind platform template "$key" provided by extension '
            '"${connection.extensionName}" (platform already registered by extension '
            '"${existingOwner.extensionName}"). Ignoring subsequent template mapping.',
          );
        }
      } else {
        targetMap[key] = value;
        _platformOwners[key] = connection;
      }
    }
  }

  /// Resolves a template package URI to a local directory.
  ///
  /// Currently only supports 'package:flutter_tools/' and
  /// 'package:flutter_tools_extension_linux_prototype/' URIs, resolving them
  /// relative to the Flutter SDK root.
  Directory resolveTemplateDirectory(String templatePath) {
    if (templatePath.startsWith('package:flutter_tools/')) {
      final String relativePath = templatePath.substring('package:flutter_tools/'.length);
      final String absolutePath = _fileSystem.path.join(
        _flutterRoot,
        'packages',
        'flutter_tools',
        'lib',
        relativePath,
      );
      return _fileSystem.directory(absolutePath);
    }
    // TODO(bkonyi): Resolve package URIs generically using package config or discovered paths.
    if (templatePath.startsWith('package:flutter_tools_extension_linux_prototype/')) {
      final String relativePath = templatePath.substring(
        'package:flutter_tools_extension_linux_prototype/'.length,
      );
      final String absolutePath = _fileSystem.path.join(
        _flutterRoot,
        'packages',
        'flutter_tools',
        'packages',
        'flutter_tools_extension_linux_prototype',
        'lib',
        relativePath,
      );
      return _fileSystem.directory(absolutePath);
    }
    throw ArgumentError('Unsupported template path format: $templatePath');
  }

  /// Request platform template parameter generation over extension protocol RPC.
  ///
  /// Delegates parameter generation for [platformName] to the active tool
  /// extension that provides platform support for [platformName], passing the
  /// host's [toolParameters]. Falls back to returning [toolParameters] unchanged
  /// if the extension fails, does not modify parameters, or is not available.
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platformName,
    required Map<String, Object?> toolParameters,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return toolParameters;
    }

    await (_loadFuture ??= _loadPlatformTemplates());

    final ExtensionConnection? owner = _platformOwners[platformName];
    if (owner == null) {
      return toolParameters;
    }

    try {
      final Object? result = await owner.sendRequest(
        TemplateService.generatePlatformTemplateParametersMethod,
        params: <String, Object?>{
          TemplateService.platformNameParam: platformName,
          TemplateService.toolParametersParam: toolParameters,
        },
      );
      if (result is Map<String, Object?>) {
        return result;
      }
    } on Object catch (e) {
      _logger.printTrace(
        'Failed to generate platform template parameters from extension '
        '"${owner.extensionName}": $e',
      );
    }

    return toolParameters;
  }
}
