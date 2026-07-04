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

  Future<List<ToolExtension>> _getActiveBuildExtensions({required bool throwOnFailure}) async {
    if (_platform.environment[envPrototypeFlag] != 'true') {
      if (throwOnFailure) {
        throwToolExit('Tool extension prototype is not enabled.');
      }
      return const <ToolExtension>[];
    }

    if (_extensionManager.extensions.isEmpty) {
      // TODO(bkonyi): dynamically load user-installed tool extensions instead of
      // unconditionally loading this prototype extension entrypoint.
      try {
        await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
      } on Object catch (e) {
        if (throwOnFailure) {
          throwToolExit('Failed to spawn prototype extension for build: $e');
        }
        _logger.printError('Failed to spawn prototype extension for build targets: $e');
        return const <ToolExtension>[];
      }
    }

    final activeExtensions = <ToolExtension>[];
    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities().timeout(const Duration(seconds: 5));
      } on Exception catch (e) {
        _logger.printTrace('Failed to get capabilities: $e');
        continue;
      }
      if (capabilities.services.contains(_serviceNamespace)) {
        activeExtensions.add(extension);
      }
    }
    return activeExtensions;
  }

  /// Retrieve build targets by routing build.getTargets to active tool extensions.
  Future<List<core.Target>> getTargets() async {
    if (_cachedTargets != null) {
      return _cachedTargets!;
    }

    final targets = <core.Target>[];

    for (final ToolExtension extension in await _getActiveBuildExtensions(throwOnFailure: false)) {
      try {
        final Object? result = await extension
            .callMethod(_getTargetsMethod)
            .timeout(const Duration(seconds: 5));
        if (result case final List<Object?> resultList) {
          for (final item in resultList) {
            if (item case final Map<Object?, Object?> itemMap) {
              targets.add(core.ExtensionBuildTarget.fromJson(itemMap.cast<String, Object?>()));
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

  /// Request build execution over extension protocol RPC.
  Future<Map<String, Object?>> buildTarget(
    String targetName,
    core.BuildEnvironment environment,
  ) async {
    for (final ToolExtension extension in await _getActiveBuildExtensions(throwOnFailure: true)) {
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
        if (result case final Map<Object?, Object?> rawResultMap) {
          final Map<String, Object?> resultMap = rawResultMap.cast<String, Object?>();
          if (resultMap case {'success': true}) {
            return resultMap;
          }
          final String message = switch (resultMap) {
            {'errorMessage': final String msg} => msg,
            {'message': final String msg} => msg,
            _ => 'Unknown error',
          };
          throwToolExit('Build compilation failed: $message');
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
