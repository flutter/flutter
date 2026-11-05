// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../base/logger.dart';
import '../features.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages querying build and assemble targets and running custom builds from extension isolates.
base class ExtensionBuildManager {
  ExtensionBuildManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._logger,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final Logger _logger;

  List<ExtensionBuildTarget>? _cachedBuildTargets;
  List<ExtensionAssembleTarget>? _cachedAssembleTargets;
  final _buildTargetToConnection = <String, ExtensionConnection>{};
  final _assembleTargetToConnection = <String, ExtensionConnection>{};

  /// Retrieve the cached `flutter build` targets synchronously.
  List<ExtensionBuildTarget> get cachedTargets =>
      _cachedBuildTargets ?? const <ExtensionBuildTarget>[];

  /// Retrieve the cached `flutter assemble` targets synchronously.
  @visibleForTesting
  List<ExtensionAssembleTarget> get cachedAssembleTargets =>
      _cachedAssembleTargets ?? const <ExtensionAssembleTarget>[];

  /// Returns the name of the extension that registered the custom `flutter build`
  /// target [targetName], or [ExtensionConnection.defaultExtensionName] if no
  /// extension registered it.
  String extensionNameForBuildTarget(String targetName) =>
      _buildTargetToConnection[targetName]?.extensionName ??
      ExtensionConnection.defaultExtensionName;

  /// Returns the name of the extension that registered the custom `flutter assemble`
  /// target [targetName], or [ExtensionConnection.defaultExtensionName] if no
  /// extension registered it.
  String extensionNameForAssembleTarget(String targetName) =>
      _assembleTargetToConnection[targetName]?.extensionName ??
      ExtensionConnection.defaultExtensionName;

  /// Retrieve `flutter build` targets by routing `build.getBuildTargets` to active tool extensions.
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <ExtensionBuildTarget>[];
    }
    if (_cachedBuildTargets case final cachedTargets?) {
      return cachedTargets;
    }

    final List<ExtensionBuildTarget>? targets = await _queryTargets<ExtensionBuildTarget>(
      connectionMap: _buildTargetToConnection,
      listFromJson: ExtensionBuildTarget.listFromJson,
      nameOf: (ExtensionBuildTarget target) => target.name,
      rpcMethod: BuildService.getBuildTargetsMethod,
      targetKind: 'build',
    );
    if (targets == null) {
      return const <ExtensionBuildTarget>[];
    }
    _cachedBuildTargets = targets;
    return targets;
  }

  /// Retrieve `flutter assemble` targets by routing `build.getAssembleTargets` to active tool extensions.
  Future<List<ExtensionAssembleTarget>> getAssembleTargets() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <ExtensionAssembleTarget>[];
    }
    if (_cachedAssembleTargets case final cachedTargets?) {
      return cachedTargets;
    }

    final List<ExtensionAssembleTarget>? targets = await _queryTargets<ExtensionAssembleTarget>(
      connectionMap: _assembleTargetToConnection,
      listFromJson: ExtensionAssembleTarget.listFromJson,
      nameOf: (ExtensionAssembleTarget target) => target.name,
      rpcMethod: BuildService.getAssembleTargetsMethod,
      targetKind: 'assemble',
    );
    if (targets == null) {
      return const <ExtensionAssembleTarget>[];
    }
    _cachedAssembleTargets = targets;
    return targets;
  }

  Future<List<T>?> _queryTargets<T extends Object>({
    required Map<String, ExtensionConnection> connectionMap,
    required List<T> Function(Object? result) listFromJson,
    required String Function(T target) nameOf,
    required String rpcMethod,
    required String targetKind,
  }) async {
    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      return null;
    }

    final targets = <T>[];
    connectionMap.clear();
    final connections = <ExtensionConnection>[
      for (final connection in _extensionManager.connections)
        if (connection.capabilities.services.contains(BuildService.serviceNamespace)) connection,
    ];

    final List<(ExtensionConnection, List<T>)> connectionTargets = await Future.wait(
      connections.map((ExtensionConnection connection) async {
        try {
          final Object? result = await connection.sendRequest(rpcMethod);
          return (connection, listFromJson(result));
        } on Object catch (e) {
          _logger.printWarning(
            'Failed to query $targetKind targets from extension "${connection.extensionName}": $e',
          );
          return (connection, <T>[]);
        }
      }),
    );

    for (final (ExtensionConnection connection, List<T> targetList) in connectionTargets) {
      for (final target in targetList) {
        final String name = nameOf(target);
        if (name.isEmpty) {
          continue;
        }
        if (connectionMap[name] case final ExtensionConnection existingConnection) {
          _logger.printWarning(
            'Skipping duplicate $targetKind target "$name" from extension "${connection.extensionName}" '
            '(already registered by extension "${existingConnection.extensionName}").',
          );
          continue;
        }
        targets.add(target);
        connectionMap[name] = connection;
      }
    }

    return targets;
  }

  /// Triggers a custom `flutter build` target for the given [targetName] by routing to the active extension.
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) {
    return _executeBuildRpc(
      buildMode: buildMode,
      connectionMap: _buildTargetToConnection,
      ensureTargetsLoaded: () async {
        if (_cachedBuildTargets == null) {
          await getBuildTargets();
        }
      },
      flutterRoot: flutterRoot,
      mainPath: mainPath,
      outputDir: outputDir,
      projectRoot: projectRoot,
      resolvedArtifacts: resolvedArtifacts,
      rpcMethod: BuildService.buildMethod,
      targetKind: 'build',
      targetName: targetName,
    );
  }

  /// Triggers a custom `flutter assemble` target for the given [targetName] by routing to the active extension.
  Future<ExtensionBuildResult> assemble({
    required Uri buildDir,
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) {
    return _executeBuildRpc(
      buildDir: buildDir,
      buildMode: buildMode,
      connectionMap: _assembleTargetToConnection,
      ensureTargetsLoaded: () async {
        if (_cachedAssembleTargets == null) {
          await getAssembleTargets();
        }
      },
      flutterRoot: flutterRoot,
      mainPath: mainPath,
      outputDir: outputDir,
      projectRoot: projectRoot,
      resolvedArtifacts: resolvedArtifacts,
      rpcMethod: BuildService.assembleMethod,
      targetKind: 'assemble',
      targetName: targetName,
    );
  }

  Future<ExtensionBuildResult> _executeBuildRpc({
    required BuildMode buildMode,
    required Map<String, ExtensionConnection> connectionMap,
    required Future<void> Function() ensureTargetsLoaded,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String rpcMethod,
    required String targetKind,
    required String targetName,
    Uri? buildDir,
  }) async {
    if (!projectRoot.hasAbsolutePath) {
      throw ArgumentError.value(projectRoot, 'projectRoot', 'Must be an absolute path.');
    }
    if (!outputDir.hasAbsolutePath) {
      throw ArgumentError.value(outputDir, 'outputDir', 'Must be an absolute path.');
    }
    if (buildDir != null && !buildDir.hasAbsolutePath) {
      throw ArgumentError.value(buildDir, 'buildDir', 'Must be an absolute path.');
    }
    if (!flutterRoot.hasAbsolutePath) {
      throw ArgumentError.value(flutterRoot, 'flutterRoot', 'Must be an absolute path.');
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

    await ensureTargetsLoaded();

    final ExtensionConnection? connection = connectionMap[targetName];
    if (connection == null) {
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'No extension found to handle $targetKind target $targetName.',
      );
    }

    try {
      final Object? result = await connection.sendRequest(
        rpcMethod,
        params: <String, Object?>{
          BuildService.buildDirParam: ?buildDir?.toString(),
          BuildService.buildModeParam: buildMode.cliName,
          BuildService.flutterRootParam: flutterRoot.toString(),
          BuildService.mainPathParam: mainPath,
          BuildService.outputDirParam: outputDir.toString(),
          BuildService.projectRootParam: projectRoot.toString(),
          BuildService.resolvedArtifactsParam: resolvedArtifacts,
          BuildService.targetNameParam: targetName,
        },
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
        timeout: null,
      );
      if (result case final Map<String, Object?> resultMap) {
        return ExtensionBuildResult.fromJson(resultMap);
      }
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'Invalid $targetKind result from extension.',
      );
    } on Object catch (e) {
      _logger.printTrace('Failed to run $targetKind from extension: $e');
      return ExtensionBuildResult(success: false, errorMessage: e.toString());
    }
  }
}
