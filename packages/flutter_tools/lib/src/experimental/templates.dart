// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
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
    required this._logger,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final Logger _logger;

  Map<String, String>? _cachedAppPlatformTemplates;
  Map<String, String>? _cachedPluginPlatformTemplates;
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
    return _cachedAppPlatformTemplates ??= await _queryPlatformTemplates(
      method: TemplateService.getAppPlatformTemplatesMethod,
      templateKind: 'app',
    );
  }

  /// Retrieve plugin platform templates by routing `template.getPluginPlatformTemplates` to active tool extensions.
  ///
  /// Results are cached after the first successful call.
  Future<Map<String, String>> getPluginPlatformTemplates() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, String>{};
    }
    return _cachedPluginPlatformTemplates ??= await _queryPlatformTemplates(
      method: TemplateService.getPluginPlatformTemplatesMethod,
      templateKind: 'plugin',
    );
  }

  Future<Map<String, String>> _queryPlatformTemplates({
    required String method,
    required String templateKind,
  }) async {
    await _extensionManager.ensureInitialized();

    final templates = <String, String>{};
    final List<ExtensionConnection> connections = _extensionManager.connections
        .where(
          (ExtensionConnection c) =>
              c.capabilities.services.contains(TemplateService.serviceNamespace),
        )
        .toList();

    for (final connection in connections) {
      try {
        final Object? rpcResult = await connection.sendRequest(method);
        if (rpcResult is Map<String, Object?>) {
          for (final MapEntry(:key, :value) in rpcResult.entries) {
            if (value is String) {
              if (templates.containsKey(key)) {
                _logger.printWarning(
                  'Duplicate $templateKind platform template "$key" provided by extension '
                  '"${connection.extensionName}" (already registered by extension '
                  '"${_platformOwners[key]?.extensionName}"). Ignoring subsequent template mapping.',
                );
              } else {
                templates[key] = value;
                _platformOwners.putIfAbsent(key, () => connection);
              }
            }
          }
        }
      } on Object catch (e) {
        _logger.printTrace('Failed to get results from extension for $method: $e');
      }
    }

    return templates;
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
        Cache.flutterRoot!,
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
        Cache.flutterRoot!,
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

    await _extensionManager.ensureInitialized();

    if (_cachedAppPlatformTemplates == null) {
      await getAppPlatformTemplates();
    }
    if (_cachedPluginPlatformTemplates == null) {
      await getPluginPlatformTemplates();
    }

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
