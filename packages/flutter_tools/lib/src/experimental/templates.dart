// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Project template manager for tool extensions.
///
/// This library manages discovery of custom project templates from active
/// tool extensions and handles template parameter generation over RPC.
library experimental.templates;

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
///
/// This manager interacts with active [ToolExtension]s to discover custom
/// project templates, resolve their directories on the host, and generate
/// template parameters over the extension protocol RPC.
class ExtensionTemplateManager {
  /// Create a new instance of [ExtensionTemplateManager].
  ExtensionTemplateManager({
    required ToolExtensionManager extensionManager,
    FileSystem? fileSystem,
    Logger? logger,
    Platform? platform,
  }) : _fileSystem = fileSystem ?? globals.fs,
       _logger = logger ?? globals.logger,
       _discoveryHelper = ExtensionDiscoveryHelper(
         logger: logger ?? globals.logger,
         extensionManager: extensionManager,
         platform: platform ?? globals.platform,
       );

  final FileSystem _fileSystem;
  final Logger _logger;
  final ExtensionDiscoveryHelper _discoveryHelper;

  List<core.ProjectTemplate>? _cachedTemplates;

  /// Retrieve the cached templates synchronously.
  ///
  /// Returns the list of project templates cached from the last [getProjectTemplates] call.
  List<core.ProjectTemplate> get cachedTemplates =>
      _cachedTemplates ?? const <core.ProjectTemplate>[];

  /// Retrieve templates by routing `template.getProjectTemplates` to active tool extensions.
  ///
  /// Results are cached after the first successful call.
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

  /// Resolves a template package URI to a local directory.
  ///
  /// Currently only supports 'package:flutter_tools/' URIs, resolving them
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
