// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../flutter_tools_core/templates.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../globals.dart' as globals;
import 'extension_discovery.dart';

/// Retrieve the [ExtensionTemplateManager] from the context.
ExtensionTemplateManager? get extensionTemplateManager => context.get<ExtensionTemplateManager>();

/// Manages querying project templates from extension isolates.
class ExtensionTemplateManager {
  /// Create a new instance of [ExtensionTemplateManager].
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

  /// Environment variable key to enable tool extension prototype features.
  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';
  static const String _serviceNamespace = 'template';
  static const String _getProjectTemplatesMethod = 'template.getProjectTemplates';
  static const String _generateTemplateParametersMethod = 'template.generateTemplateParameters';

  List<core.ProjectTemplate>? _cachedTemplates;

  /// Retrieve the cached templates synchronously.
  List<core.ProjectTemplate> get cachedTemplates =>
      _cachedTemplates ?? const <core.ProjectTemplate>[];

  /// Retrieve templates by routing template.getProjectTemplates to active tool extensions.
  Future<List<core.ProjectTemplate>> getProjectTemplates() async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return const <core.ProjectTemplate>[];
    }
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    final helper = ExtensionDiscoveryHelper(extensionManager: _extensionManager, logger: _logger);
    final List<ToolExtension> extensions = await helper.getExtensionsSupporting(_serviceNamespace);

    final templates = <core.ProjectTemplate>[];

    for (final extension in extensions) {
      try {
        final Object? result = await extension
            .callMethod(_getProjectTemplatesMethod)
            .timeout(const Duration(seconds: 5));
        if (result case final List<Object?> resultList) {
          for (final item in resultList) {
            if (item case final Map<Object?, Object?> itemMap) {
              templates.add(
                core.ExtensionProjectTemplate.fromJson(itemMap.cast<String, Object?>()),
              );
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

  /// Resolves a Tool Extension Protocol template package URI to a local directory.
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
    throw ArgumentError('Unsupported template path format: $templatePath');
  }

  /// Request template parameter generation over extension protocol RPC.
  Future<Map<String, Object?>> generateTemplateParameters(
    String templateName,
    Map<String, Object?> toolParameters,
  ) async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return toolParameters;
    }

    final helper = ExtensionDiscoveryHelper(extensionManager: _extensionManager, logger: _logger);
    final List<ToolExtension> extensions = await helper.getExtensionsSupporting(_serviceNamespace);

    for (final extension in extensions) {
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
        if (result case final Map<Object?, Object?> resultMap) {
          return resultMap.cast<String, Object?>();
        }
      } on Object catch (e) {
        _logger.printError('Failed to generate template parameters from extension: $e');
      }
    }

    return toolParameters;
  }
}
