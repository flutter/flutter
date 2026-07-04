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
  }) : _discoveryHelper = ExtensionDiscoveryHelper(
         extensionManager: extensionManager,
         logger: logger ?? globals.logger,
         platform: platform ?? globals.platform,
       ),
       _fileSystem = fileSystem ?? globals.fs,
       _logger = logger ?? globals.logger;

  final ExtensionDiscoveryHelper _discoveryHelper;
  final FileSystem _fileSystem;
  final Logger _logger;

  List<core.ProjectTemplate>? _cachedTemplates;

  /// Retrieve the cached templates synchronously.
  List<core.ProjectTemplate> get cachedTemplates =>
      _cachedTemplates ?? const <core.ProjectTemplate>[];

  /// Retrieve templates by routing template.getProjectTemplates to active tool extensions.
  Future<List<core.ProjectTemplate>> getProjectTemplates() async {
    if (!_discoveryHelper.isPrototypeEnabled) {
      return const <core.ProjectTemplate>[];
    }
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    final List<core.ProjectTemplate> templates = await _discoveryHelper
        .getListFromExtensions<core.ProjectTemplate>(
          core.TemplateService.serviceNamespace,
          core.TemplateService.getProjectTemplatesMethod,
          core.ExtensionProjectTemplate.listFromJson,
        );

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
    if (!_discoveryHelper.isPrototypeEnabled) {
      return toolParameters;
    }

    final List<ToolExtension> extensions = await _discoveryHelper.getExtensionsSupporting(
      core.TemplateService.serviceNamespace,
    );

    for (final extension in extensions) {
      try {
        final Object? result = await extension
            .callMethod(
              core.TemplateService.generateTemplateParametersMethod,
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
