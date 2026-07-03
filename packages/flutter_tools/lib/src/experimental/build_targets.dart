// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/context.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../flutter_tools_core/build.dart' as core;
import '../generic_extension_protocol/manager.dart';
import '../generic_extension_protocol/service.dart';
import '../globals.dart' as globals;

/// Retrieve the [ExtensionBuildTargetManager] from the context.
ExtensionBuildTargetManager? get extensionBuildTargetManager =>
    context.get<ExtensionBuildTargetManager>();

/// Manages querying build targets and delegating builds to extension isolates.
class ExtensionBuildTargetManager {
  /// Create a new instance of [ExtensionBuildTargetManager].
  ExtensionBuildTargetManager({
    required ToolExtensionManager extensionManager,
    Logger? logger,
    Platform? platform,
  }) : _extensionManager = extensionManager,
       _logger = logger ?? globals.logger,
       _platform = platform ?? globals.platform;

  final ToolExtensionManager _extensionManager;
  final Logger _logger;
  final Platform _platform;

  /// Environment variable key to enable tool extension prototype features.
  static const String envPrototypeFlag = 'FLUTTER_TOOL_EXTENSION_PROTOTYPE';
  static const String _serviceNamespace = 'build';
  static const String _getTargetsMethod = 'build.getTargets';
  static const String _buildMethod = 'build.build';

  List<core.Target>? _cachedTargets;

  /// Retrieve the cached targets synchronously.
  List<core.Target> get cachedTargets => _cachedTargets ?? const <core.Target>[];

  /// Retrieve build targets by routing build.getTargets to active tool extensions.
  Future<List<core.Target>> getTargets() async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      return const <core.Target>[];
    }
    if (_cachedTargets != null) {
      return _cachedTargets!;
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        _logger.printError('Failed to spawn prototype extension for build targets: $e');
        return const <core.Target>[];
      }
    }

    final targets = <core.Target>[];

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
            .callMethod(_getTargetsMethod)
            .timeout(const Duration(seconds: 5));
        if (result is List) {
          for (final Object? item in result) {
            if (item is Map) {
              final Map<String, Object?> resultMap = (item as Map<Object?, Object?>)
                  .cast<String, Object?>();
              targets.add(core.ExtensionBuildTarget.fromJson(resultMap));
            }
          }
        }
      } on Object catch (e) {
        _logger.printError('Failed to get targets from extension: $e');
      }
    }

    _cachedTargets = targets;
    return targets;
  }

  /// Alias for [getTargets] supporting alternative naming conventions.
  Future<List<core.Target>> getBuildTargets() => getTargets();

  /// Request build execution over GEP RPC.
  Future<Map<String, Object?>> buildTarget(
    String targetName,
    core.BuildEnvironment environment,
  ) async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      throwToolExit('Tool extension prototype is not enabled.');
    }

    if (_extensionManager.extensions.isEmpty) {
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        throwToolExit('Failed to spawn prototype extension for build: $e');
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
              _buildMethod,
              params: <String, Object?>{
                'targetName': targetName,
                'environment': environment.toMap(),
              },
            )
            .timeout(const Duration(seconds: 60));
        if (result is Map) {
          final Map<String, Object?> resultMap = (result as Map<Object?, Object?>)
              .cast<String, Object?>();
          final bool success = resultMap['success'] as bool? ?? false;
          if (!success) {
            final String message =
                resultMap['errorMessage'] as String? ??
                resultMap['message'] as String? ??
                'Unknown error';
            throwToolExit('Build compilation failed: $message');
          }
          return resultMap;
        }
      } on Object catch (e) {
        if (e is ToolExit) {
          rethrow;
        }
        throwToolExit('Build compilation failed: $e');
      }
    }

    throwToolExit('No extension service handled build for target: $targetName');
  }
}
