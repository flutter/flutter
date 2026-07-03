// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../flutter_tools_core/templates.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../generic_extension_protocol/service.dart';
import '../globals.dart' as globals;

/// Retrieve the [ExtensionTemplateManager] from the context.
ExtensionTemplateManager? get extensionTemplateManager => context.get<ExtensionTemplateManager>();

class ExtensionTemplateManager {
  ExtensionTemplateManager({
    required ToolExtensionManager extensionManager,
    FileSystem? fileSystem,
    Logger? logger,
    Platform? platform,
  }) : _extensionManager = extensionManager,
       _fileSystem = fileSystem ?? globals.fs,
       _logger = logger ?? globals.logger,
       _platform = platform ?? globals.platform;

  final ToolExtensionManager _extensionManager;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;

  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';
  static const String _serviceNamespace = 'template';
  static const String _getProjectTemplatesMethod = 'template.getProjectTemplates';
  static const String _generateTemplateParametersMethod = 'template.generateTemplateParameters';

  List<core.ProjectTemplate>? _cachedTemplates;

  /// Retrieve the cached templates synchronously.
  List<core.ProjectTemplate> get cachedTemplates =>
      _cachedTemplates ?? const <core.ProjectTemplate>[];

  /// Retrieve project templates by routing template.getProjectTemplates to active tool extensions.
  Future<List<core.ProjectTemplate>> getProjectTemplates() async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return const <core.ProjectTemplate>[];
    }
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        _logger.printError('Failed to spawn prototype extension: $e');
        return const <core.ProjectTemplate>[];
      }
    }

    final templates = <core.ProjectTemplate>[];

    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities().timeout(const Duration(seconds: 5));
      } on Exception catch (e) {
        _logger.printTrace('Failed to get capabilities: $e');
        continue;
      }
      if (!capabilities.services.contains(_serviceNamespace)) {
        continue;
      }

      try {
        final Object? result = await extension
            .callMethod(_getProjectTemplatesMethod)
            .timeout(const Duration(seconds: 5));
        if (result is List) {
          for (final Object? item in result) {
            if (item is Map) {
              final Map<String, Object?> resultMap = (item as Map<Object?, Object?>)
                  .cast<String, Object?>();
              templates.add(core.ExtensionProjectTemplate.fromJson(resultMap));
            }
          }
        }
      } on Object catch (e) {
        _logger.printError('Failed to get templates from extension: $e');
      }
    }

    _cachedTemplates = templates;
    return templates;
  }

  /// Resolve a GEP template package URI to a local directory.
  Directory? resolveTemplateDirectory(String templatePath) {
    if (templatePath.startsWith('package:flutter_tools/')) {
      final String relativePart = templatePath.substring('package:flutter_tools/'.length);
      final String? workspaceRootPath = Cache.flutterRoot;
      if (workspaceRootPath == null) {
        throw StateError('Cache.flutterRoot is not initialized.');
      }
      final String localPath = _fileSystem.path.join(
        workspaceRootPath,
        'packages',
        'flutter_tools',
        'lib',
        relativePart,
      );
      return _fileSystem.directory(localPath);
    }
    return null;
  }

  /// Request template parameter generation over GEP RPC.
  Future<Map<String, Object?>> generateTemplateParameters(
    String templateName,
    Map<String, Object?> toolParameters,
  ) async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return toolParameters;
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        _logger.printError('Failed to spawn prototype extension: $e');
        return toolParameters;
      }
    }

    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities().timeout(const Duration(seconds: 5));
      } on Exception catch (e) {
        _logger.printTrace('Failed to get capabilities: $e');
        continue;
      }
      if (!capabilities.services.contains(_serviceNamespace)) {
        continue;
      }

      try {
        final Object? result = await extension
            .callMethod(
              _generateTemplateParametersMethod,
              params: <String, Object?>{
                'templateName': templateName,
                'toolParameters': toolParameters,
              },
            )
            .timeout(const Duration(seconds: 5));
        if (result is Map) {
          final Map<String, Object?> resultMap = (result as Map<Object?, Object?>)
              .cast<String, Object?>();
          return resultMap;
        }
      } on Object catch (e) {
        _logger.printError('Failed to generate template parameters from extension: $e');
      }
    }

    return toolParameters;
  }
}
