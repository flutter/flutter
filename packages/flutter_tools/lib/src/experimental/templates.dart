// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../features.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';
import 'project_extension_finder.dart';

const Duration _kRpcTimeout = Duration(seconds: 5);

/// Manages querying project templates from extension isolates.
///
/// This manager interacts with active [ExtensionConnection]s to discover custom
/// project templates, resolve their directories on the host, and generate
/// template parameters over the extension protocol RPC.
base class ExtensionTemplateManager extends TemplateService {
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

  List<ProjectTemplate>? _cachedTemplates;
  int _cachedGeneration = -1;
  final _cachedCustomPlatforms = <String>{};
  final _cachedAppPlatformTemplates = <String>{};
  final _cachedPluginPlatformTemplates = <String>{};

  /// Retrieve the cached templates synchronously.
  ///
  /// Returns the list of project templates cached from the last [getProjectTemplates] call.
  List<ProjectTemplate> get cachedTemplates => _cachedTemplates ?? const <ProjectTemplate>[];

  /// Retrieve the cached custom platform names declared by discovered extensions.
  Set<String> get cachedCustomPlatforms => Set<String>.unmodifiable(_cachedCustomPlatforms);

  /// Discovers custom platform names declared in `extension/flutter_tools/config.yaml`
  /// for extensions in [projectDir] and the current working directory.
  Future<Set<String>> getCustomPlatforms({Directory? projectDir}) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String>{};
    }
    await _extensionManager.discoverExtensions();
    if (projectDir != null) {
      await _extensionManager.discoverExtensions(startDir: projectDir);
    }
    for (final DiscoveredProjectExtension ext in _extensionManager.discoveredExtensions) {
      _cachedCustomPlatforms.addAll(ext.config.platforms);
    }
    return cachedCustomPlatforms;
  }

  /// Retrieve templates by routing `template.getProjectTemplates` to active tool extensions.
  ///
  /// Results are cached after the first successful call, and refreshed if
  /// [projectDir] introduces additional discovered extensions.
  Future<List<ProjectTemplate>> getProjectTemplates({Directory? projectDir}) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <ProjectTemplate>[];
    }
    await getCustomPlatforms(projectDir: projectDir);
    await _extensionManager.ensureInitialized(
      requiredServices: const <String>{TemplateService.serviceNamespace},
      startDir: projectDir,
    );
    if (_cachedTemplates != null && _extensionManager.connectionGeneration == _cachedGeneration) {
      return _cachedTemplates!;
    }

    final templates = <ProjectTemplate>[];
    final seenNames = <String>{};
    final List<ExtensionConnection> connections = _extensionManager.connections
        .where(
          (ExtensionConnection c) =>
              c.capabilities.services.contains(TemplateService.serviceNamespace),
        )
        .toList();

    final List<List<ExtensionProjectTemplate>> results = await Future.wait(
      connections.map((ExtensionConnection connection) async {
        try {
          final Object? rpcResult = await connection
              .sendRequest(TemplateService.getProjectTemplatesMethod)
              .timeout(_kRpcTimeout);
          return ExtensionProjectTemplate.listFromJson(rpcResult);
        } on Object catch (e) {
          _logger.printTrace(
            'Failed to get results from extension for ${TemplateService.getProjectTemplatesMethod}: $e',
          );
          return const <ExtensionProjectTemplate>[];
        }
      }),
    );

    for (final templateList in results) {
      for (final template in templateList) {
        if (seenNames.add(template.name)) {
          templates.add(template);
        } else {
          _logger.printWarning(
            'Skipping duplicate project template "${template.name}" from extension.',
          );
        }
      }
    }

    _cachedTemplates = templates;
    _cachedGeneration = _extensionManager.connectionGeneration;
    return templates;
  }

  /// Queries `template.getAppTemplates` from active extension isolates.
  Future<Set<String>> fetchAppPlatformTemplates({
    Iterable<String>? platforms,
    Directory? projectDir,
  }) async {
    return _fetchPlatformTemplates(
      method: TemplateService.getAppTemplatesMethod,
      cache: _cachedAppPlatformTemplates,
      platforms: platforms,
      projectDir: projectDir,
    );
  }

  /// Queries `template.getPluginTemplates` from active extension isolates.
  Future<Set<String>> fetchPluginPlatformTemplates({
    Iterable<String>? platforms,
    Directory? projectDir,
  }) async {
    return _fetchPlatformTemplates(
      method: TemplateService.getPluginTemplatesMethod,
      cache: _cachedPluginPlatformTemplates,
      platforms: platforms,
      projectDir: projectDir,
    );
  }

  Future<Set<String>> _fetchPlatformTemplates({
    required Set<String> cache,
    required String method,
    Iterable<String>? platforms,
    Directory? projectDir,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String>{};
    }
    await _extensionManager.ensureInitialized(
      requiredServices: const <String>{TemplateService.serviceNamespace},
      startDir: projectDir,
    );
    final Set<String>? platformSet = platforms?.toSet();
    final discoveredNames = <String>{
      for (final DiscoveredProjectExtension ext in _extensionManager.discoveredExtensions) ext.name,
    };
    final Set<String>? matchingExtensionNames = platformSet == null
        ? null
        : <String>{
            for (final DiscoveredProjectExtension ext in _extensionManager.discoveredExtensions)
              if (ext.config.platforms.any(platformSet.contains)) ext.name,
          };
    final List<ExtensionConnection> connections = _extensionManager.connections
        .where(
          (ExtensionConnection c) =>
              c.capabilities.services.contains(TemplateService.serviceNamespace) &&
              (matchingExtensionNames == null ||
                  !discoveredNames.contains(c.extensionName) ||
                  matchingExtensionNames.contains(c.extensionName)),
        )
        .toList();

    final results = <String>{};
    for (final connection in connections) {
      try {
        final Object? rpcResult = await connection.sendRequest(method).timeout(_kRpcTimeout);
        if (rpcResult case final List<Object?> list) {
          final Iterable<String> paths = list.whereType<String>();
          cache.addAll(paths);
          results.addAll(paths);
        }
      } on Object catch (e) {
        _logger.printTrace('Failed to get results from extension for $method: $e');
      }
    }
    return Set<String>.unmodifiable(platformSet == null ? cache : results);
  }

  /// Resolves a template package URI to a local directory.
  ///
  /// Supports `package:flutter_tools/`, discovered project extension packages,
  /// and `package:flutter_tools_extension_linux_prototype/` URIs.
  Directory resolveTemplateDirectory(String templatePath) {
    if (templatePath.startsWith('package:')) {
      final String withoutScheme = templatePath.substring('package:'.length);
      final int slashIndex = withoutScheme.indexOf('/');
      if (slashIndex > 0) {
        final String packageName = withoutScheme.substring(0, slashIndex);
        final String relativePath = withoutScheme.substring(slashIndex + 1);
        if (packageName == 'flutter_tools') {
          final String absolutePath = _fileSystem.path.join(
            Cache.flutterRoot!,
            'packages',
            'flutter_tools',
            'lib',
            relativePath,
          );
          return _fileSystem.directory(absolutePath);
        }
        for (final DiscoveredProjectExtension ext in _extensionManager.discoveredExtensions) {
          if (ext.name == packageName) {
            final Directory packageLibDir = _fileSystem.directory(ext.packageUri);
            final String normalizedLibPath = _fileSystem.path.normalize(
              packageLibDir.absolute.path,
            );
            final String resolvedPath = _fileSystem.path.normalize(
              _fileSystem.path.joinAll(<String>[normalizedLibPath, ...relativePath.split('/')]),
            );
            if (!_fileSystem.path.isWithin(normalizedLibPath, resolvedPath) &&
                !_fileSystem.path.equals(normalizedLibPath, resolvedPath)) {
              throw ArgumentError.value(
                templatePath,
                'templatePath',
                'Template path escapes package lib/ directory.',
              );
            }
            return _fileSystem.directory(resolvedPath);
          }
        }
        if (packageName == 'flutter_tools_extension_linux_prototype') {
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
      }
    }
    throw ArgumentError('Unsupported template path format: $templatePath');
  }

  /// Request template parameter generation over extension protocol RPC.
  ///
  /// Delegates the parameter generation for [templateName] to the active tool
  /// extension, passing the host's [toolParameters]. Falls back to returning
  /// [toolParameters] unchanged if the extension fails or is not available.
  Future<Map<String, Object?>> generateTemplateParameters(
    String templateName,
    Map<String, Object?> toolParameters,
  ) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return toolParameters;
    }

    final List<ExtensionConnection> connections = _extensionManager.connections
        .where(
          (ExtensionConnection c) =>
              c.capabilities.services.contains(TemplateService.serviceNamespace),
        )
        .toList();

    for (final connection in connections) {
      try {
        final Object? result = await connection
            .sendRequest(
              TemplateService.generateTemplateParametersMethod,
              params: <String, Object?>{
                'templateName': templateName,
                'toolParameters': toolParameters,
              },
            )
            .timeout(_kRpcTimeout);
        if (result is Map) {
          return result.cast<String, Object?>();
        }
      } on Object catch (e) {
        _logger.printTrace('Failed to generate template parameters from extension: $e');
      }
    }

    return toolParameters;
  }

  @override
  Set<ProjectTemplate> get projectTemplates => cachedTemplates.toSet();

  @override
  Set<String> get appPlatformTemplates => Set<String>.unmodifiable(_cachedAppPlatformTemplates);

  @override
  Set<String> get pluginPlatformTemplates =>
      Set<String>.unmodifiable(_cachedPluginPlatformTemplates);
}
