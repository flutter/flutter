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
    required this._flutterRoot,
    required this._logger,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final String _flutterRoot;
  final Logger _logger;

  List<ProjectTemplate>? _cachedTemplates;
  int _cachedGeneration = -1;

  /// Retrieve the cached templates synchronously.
  ///
  /// Returns the list of project templates cached from the last [getProjectTemplates] call.
  List<ProjectTemplate> get cachedTemplates => _cachedTemplates ?? const <ProjectTemplate>[];

  /// Retrieve templates by routing `template.getProjectTemplates` to active tool extensions.
  ///
  /// Results are cached after the first successful call and refreshed if
  /// additional extension connections are registered.
  Future<List<ProjectTemplate>> getProjectTemplates() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <ProjectTemplate>[];
    }
    await _extensionManager.ensureInitialized(
      requiredServices: const <String>{TemplateService.serviceNamespace},
    );
    if (_cachedTemplates case final cachedTemplates?
        when _extensionManager.connectionGeneration == _cachedGeneration) {
      return cachedTemplates;
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
        } on ToolExtensionException catch (e) {
          _logger.printWarning('Extension "${connection.extensionName}": ${e.message}');
          return const <ExtensionProjectTemplate>[];
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
            _flutterRoot,
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
      } on ToolExtensionException catch (e) {
        throwToolExit(e.message);
      } on Object catch (e) {
        _logger.printTrace('Failed to generate template parameters from extension: $e');
      }
    }

    return toolParameters;
  }

  @override
  Set<ProjectTemplate> get projectTemplates => cachedTemplates.toSet();

  @override
  Set<String> get appPlatformTemplates => const <String>{};

  @override
  Set<String> get pluginPlatformTemplates => const <String>{};
}
