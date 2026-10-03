// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../base/logger.dart';
import '../features.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

const Duration _kGetBuildTargetsTimeout = Duration(seconds: 5);
const Duration _kBuildTimeout = Duration(minutes: 5);

/// Manages querying build targets and running custom builds from extension isolates.
base class ExtensionBuildManager {
  ExtensionBuildManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._logger,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final Logger _logger;

  List<ExtensionBuildTarget>? _cachedTargets;
  final _targetToConnection = <String, ExtensionConnection>{};

  /// Retrieve the cached build targets synchronously.
  List<ExtensionBuildTarget> get cachedTargets => _cachedTargets ?? const <ExtensionBuildTarget>[];

  /// Retrieve build targets by routing `build.getBuildTargets` to active tool extensions.
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <ExtensionBuildTarget>[];
    }
    if (_cachedTargets case final cachedTargets?) {
      return cachedTargets;
    }

    await _extensionManager.ensureInitialized();

    final targets = <ExtensionBuildTarget>[];
    _targetToConnection.clear();
    final connections = <ExtensionConnection>[
      for (final connection in _extensionManager.connections)
        if (connection.capabilities.services.contains(BuildService.serviceNamespace)) connection,
    ];

    for (final connection in connections) {
      try {
        final Object? rpcResult = await connection
            .sendRequest(BuildService.getBuildTargetsMethod)
            .timeout(_kGetBuildTargetsTimeout);
        for (final ExtensionBuildTarget target in ExtensionBuildTarget.listFromJson(rpcResult)) {
          targets.add(target);
          _targetToConnection[target.name] = connection;
        }
      } on Object catch (e) {
        _logger.printError(
          'Failed to get results from extension for ${BuildService.getBuildTargetsMethod}: $e',
        );
      }
    }

    _cachedTargets = targets;
    return targets;
  }

  /// Triggers a custom build for the given [targetName] by routing to the active extension.
  Future<ExtensionBuildResult> build({
    required String buildMode,
    required String mainPath,
    required String projectRoot,
    required String targetName,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const ExtensionBuildResult(
        success: false,
        errorMessage: 'Tool extensions are disabled.',
      );
    }

    await _extensionManager.ensureInitialized();

    if (_cachedTargets == null) {
      await getBuildTargets();
    }

    final ExtensionConnection? connection = _targetToConnection[targetName];
    if (connection == null) {
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'No extension found to handle build target $targetName.',
      );
    }

    try {
      final Object? result = await connection
          .sendRequest(BuildService.buildMethod, <String, Object?>{
            BuildService.buildModeParam: buildMode,
            BuildService.mainPathParam: mainPath,
            BuildService.projectRootParam: projectRoot,
            BuildService.targetNameParam: targetName,
          })
          .timeout(_kBuildTimeout);
      if (result case final Map<String, Object?> resultMap) {
        return ExtensionBuildResult.fromJson(resultMap);
      } else if (result case final Map<Object?, Object?> resultMap) {
        return ExtensionBuildResult.fromJson(resultMap.cast<String, Object?>());
      }
      return const ExtensionBuildResult(
        success: false,
        errorMessage: 'Invalid build result from extension.',
      );
    } on Object catch (e) {
      _logger.printError('Failed to run build from extension: $e');
      return ExtensionBuildResult(success: false, errorMessage: e.toString());
    }
  }
}
