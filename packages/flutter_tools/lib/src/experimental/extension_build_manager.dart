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

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      return const <ExtensionBuildTarget>[];
    }

    final targets = <ExtensionBuildTarget>[];
    _targetToConnection.clear();
    final connections = <ExtensionConnection>[
      for (final connection in _extensionManager.connections)
        if (connection.capabilities.services.contains(BuildService.serviceNamespace)) connection,
    ];

    final List<(ExtensionConnection, List<ExtensionBuildTarget>)> connectionTargets =
        await Future.wait(
          connections.map((ExtensionConnection connection) async {
            try {
              final Object? result = await connection.sendRequest(
                BuildService.getBuildTargetsMethod,
              );
              return (connection, ExtensionBuildTarget.listFromJson(result));
            } on Object catch (e) {
              _logger.printTrace('Failed to query build targets from extension: $e');
              return (connection, const <ExtensionBuildTarget>[]);
            }
          }),
        );

    for (final (ExtensionConnection connection, List<ExtensionBuildTarget> targetList)
        in connectionTargets) {
      for (final target in targetList) {
        if (target.name.isEmpty) {
          continue;
        }
        if (_targetToConnection.containsKey(target.name)) {
          // TODO(bkonyi): Include conflicting extension names once extension manifest metadata is wired into ExtensionConnection.
          _logger.printWarning('Skipping duplicate build target "${target.name}" from extension.');
          continue;
        }
        targets.add(target);
        _targetToConnection[target.name] = connection;
      }
    }

    _cachedTargets = targets;
    return targets;
  }

  /// Triggers a custom build for the given [targetName] by routing to the active extension.
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    if (!projectRoot.hasAbsolutePath) {
      throw ArgumentError.value(projectRoot, 'projectRoot', 'Must be an absolute path.');
    }
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const ExtensionBuildResult(
        success: false,
        errorMessage: 'Tool extensions are disabled.',
      );
    }

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'Failed to initialize extension manager: $e',
      );
    }

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
      final Object? result = await connection.sendRequest(
        BuildService.buildMethod,
        params: <String, Object?>{
          BuildService.buildModeParam: buildMode.cliName,
          BuildService.mainPathParam: mainPath,
          BuildService.projectRootParam: projectRoot.toString(),
          BuildService.targetNameParam: targetName,
        },
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
        timeout: null,
      );
      if (result case final Map<String, Object?> resultMap) {
        return ExtensionBuildResult.fromJson(resultMap);
      }
      return const ExtensionBuildResult(
        success: false,
        errorMessage: 'Invalid build result from extension.',
      );
    } on Object catch (e) {
      _logger.printTrace('Failed to run build from extension: $e');
      return ExtensionBuildResult(success: false, errorMessage: e.toString());
    }
  }
}
