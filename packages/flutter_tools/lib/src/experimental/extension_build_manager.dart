// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart' show kExtensionBuildTarget, kExtensionPluginPlatformKey;
import '../features.dart';
import '../flutter_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Manages querying build and assemble targets and running custom builds from extension isolates.
base class ExtensionBuildManager {
  ExtensionBuildManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._fileSystem,
    required this._logger,
    required this._projectFactory,
  });

  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final Logger _logger;
  final FlutterProjectFactory _projectFactory;

  List<ExtensionBuildTarget>? _cachedBuildTargets;
  List<ExtensionAssembleTarget>? _cachedAssembleTargets;
  final _buildTargetToConnection = <String, ExtensionConnection>{};
  final _assembleTargetToConnection = <String, ExtensionConnection>{};
  final _buildTargetsByName = <String, ExtensionBuildTarget>{};

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

  /// Returns the `flutter assemble` environment defines for [targetName],
  /// including `kExtensionBuildTarget`, `kExtensionTargetOs`,
  /// `kExtensionTargetArch`, `kExtensionCCompiler*` from [nativeAssetsConfig],
  /// and `kExtensionPluginPlatformKey` when configured on the
  /// [ExtensionBuildTarget].
  Map<String, String> environmentDefinesForTarget(
    String targetName, {
    ExtensionNativeAssetsConfig? nativeAssetsConfig,
  }) {
    final ExtensionBuildTarget? target = _buildTargetsByName[targetName];
    if (target == null) {
      return const <String, String>{};
    }
    return <String, String>{
      kExtensionBuildTarget: target.name,
      ...?nativeAssetsConfig?.toEnvironmentDefines(),
      if (target.pluginPlatformKey case final String key when key.isNotEmpty)
        kExtensionPluginPlatformKey: key,
    };
  }

  /// Queries the active extension for the Dart hooks (`native_assets`) configuration
  /// for [targetName] given the current build context.
  ///
  /// Returns `null` if tool extensions are disabled, no extension handles
  /// [targetName], or the target does not configure native asset hooks.
  /// Throws a [ToolExit] if the extension fails to resolve the configuration or
  /// returns a malformed payload.
  Future<ExtensionNativeAssetsConfig?> resolveNativeAssetsConfig({
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) async {
    _validateRequestUris(flutterRoot: flutterRoot, outputDir: outputDir, projectRoot: projectRoot);
    if (!_featureFlags.isToolExtensionsEnabled) {
      return null;
    }

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      throwToolExit('Failed to initialize extension manager: $e');
    }

    if (_cachedBuildTargets == null) {
      await getBuildTargets();
    }

    final ExtensionConnection? connection = _buildTargetToConnection[targetName];
    if (connection == null) {
      return null;
    }

    final Map<String, Object?> params = await _createBuildRequestParams(
      buildMode: buildMode,
      flutterRoot: flutterRoot,
      mainPath: mainPath,
      outputDir: outputDir,
      pluginPlatformKey: _buildTargetsByName[targetName]?.pluginPlatformKey,
      projectRoot: projectRoot,
      resolvedArtifacts: resolvedArtifacts,
      targetName: targetName,
    );

    try {
      final Object? result = await connection.sendRequest(
        BuildService.resolveNativeAssetsConfigMethod,
        params: params,
        timeout: null,
      );
      if (result == null) {
        return null;
      }
      if (result case final Map<String, Object?> resultMap) {
        return ExtensionNativeAssetsConfig.fromJson(resultMap);
      }
      throwToolExit(
        'Invalid native assets config response from extension "${connection.extensionName}" for target "$targetName".',
      );
    } on ToolExit {
      rethrow;
    } on ToolExtensionException catch (e) {
      throwToolExit(
        'Failed to resolve native assets config from extension "${connection.extensionName}" for target "$targetName": ${e.message}',
      );
    } on Object catch (e) {
      throwToolExit(
        'Failed to resolve native assets config from extension "${connection.extensionName}" for target "$targetName": $e',
      );
    }
  }

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
    _buildTargetsByName.clear();
    for (final ExtensionBuildTarget target in targets) {
      _buildTargetsByName[target.name] = target;
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
        } on ToolExtensionException catch (e) {
          _logger.printWarning('Extension "${connection.extensionName}": ${e.message}');
          return (connection, <T>[]);
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
      resolvePluginPlatformKey: () => _buildTargetsByName[targetName]?.pluginPlatformKey,
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
    String? pluginPlatformKey,
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
      resolvePluginPlatformKey: () => pluginPlatformKey,
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
    required String? Function() resolvePluginPlatformKey,
    required Map<String, String> resolvedArtifacts,
    required String rpcMethod,
    required String targetKind,
    required String targetName,
    Uri? buildDir,
  }) async {
    _validateRequestUris(
      buildDir: buildDir,
      flutterRoot: flutterRoot,
      outputDir: outputDir,
      projectRoot: projectRoot,
    );
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

    final Map<String, Object?> params = await _createBuildRequestParams(
      buildDir: buildDir,
      buildMode: buildMode,
      flutterRoot: flutterRoot,
      mainPath: mainPath,
      outputDir: outputDir,
      pluginPlatformKey: resolvePluginPlatformKey(),
      projectRoot: projectRoot,
      resolvedArtifacts: resolvedArtifacts,
      targetName: targetName,
    );

    try {
      final Object? result = await connection.sendRequest(rpcMethod, params: params, timeout: null);
      if (result case final Map<String, Object?> resultMap) {
        return ExtensionBuildResult.fromJson(resultMap);
      }
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'Invalid $targetKind result from extension.',
      );
    } on ToolExtensionException catch (e) {
      return ExtensionBuildResult(success: false, errorMessage: e.message);
    } on Object catch (e) {
      _logger.printTrace('Failed to run $targetKind from extension: $e');
      return ExtensionBuildResult(success: false, errorMessage: e.toString());
    }
  }

  void _validateRequestUris({
    required Uri flutterRoot,
    required Uri outputDir,
    required Uri projectRoot,
    Uri? buildDir,
  }) {
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
  }

  Future<Map<String, Object?>> _createBuildRequestParams({
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
    Uri? buildDir,
    String? pluginPlatformKey,
  }) async {
    final List<ExtensionPlugin> resolvedPlugins = await _resolvePluginsForTarget(
      projectRoot,
      pluginPlatformKey,
      buildMode: buildMode,
    );
    return <String, Object?>{
      BuildService.buildDirParam: ?buildDir?.toString(),
      BuildService.buildModeParam: buildMode.cliName,
      BuildService.flutterRootParam: flutterRoot.toString(),
      BuildService.mainPathParam: mainPath,
      BuildService.outputDirParam: outputDir.toString(),
      if (resolvedPlugins.isNotEmpty)
        BuildService.pluginsParam: <Map<String, Object?>>[
          for (final ExtensionPlugin plugin in resolvedPlugins) plugin.toMap(),
        ],
      BuildService.projectRootParam: projectRoot.toString(),
      BuildService.resolvedArtifactsParam: resolvedArtifacts,
      BuildService.targetNameParam: targetName,
    };
  }

  Future<List<ExtensionPlugin>> _resolvePluginsForTarget(
    Uri projectRoot,
    String? pluginPlatformKey, {
    required BuildMode buildMode,
  }) async {
    if (pluginPlatformKey == null || pluginPlatformKey.isEmpty) {
      return const <ExtensionPlugin>[];
    }
    final Directory projectDir = _fileSystem.directory(projectRoot);
    final FlutterProject project = _projectFactory.fromDirectory(projectDir);
    if (!project.pubspecFile.existsSync()) {
      return const <ExtensionPlugin>[];
    }
    final List<Plugin> foundPlugins = await findPlugins(
      project,
      extraPlatformKeys: <String>{pluginPlatformKey},
      logger: _logger,
      throwOnError: false,
    );
    if (foundPlugins.isEmpty) {
      return const <ExtensionPlugin>[];
    }
    return resolveExtensionPluginsForPlatform(
      foundPlugins,
      pluginPlatformKey,
      fileSystem: _fileSystem,
      includeDevDependencies: !buildMode.isRelease,
      logger: _logger,
    );
  }
}
