// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../base/config.dart';
import '../base/logger.dart';
import '../features.dart';
import 'config.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// Parses a list of `KEY=VALUE` [dartDefines] strings into a map, splitting
/// on the first `=` character.
Map<String, String> parseExtensionDartDefines(List<String> dartDefines) {
  if (dartDefines.isEmpty) {
    return const <String, String>{};
  }
  final result = <String, String>{};
  for (final define in dartDefines) {
    final int separatorIndex = define.indexOf('=');
    if (separatorIndex == -1) {
      result[define] = '';
    } else {
      result[define.substring(0, separatorIndex)] = define.substring(separatorIndex + 1);
    }
  }
  return result;
}

/// Manages querying build and assemble targets and running custom builds from extension isolates.
base class ExtensionBuildManager {
  ExtensionBuildManager({
    required this._extensionManager,
    required this._featureFlags,
    required this._logger,
    this._config,
  });

  final Config? _config;
  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final Logger _logger;

  List<ExtensionBuildTarget>? _cachedBuildTargets;
  List<ExtensionAssembleTarget>? _cachedAssembleTargets;
  final _buildTargetToConnection = <String, ExtensionConnection>{};
  final _assembleTargetToConnection = <String, ExtensionConnection>{};
  final _connectionConfigSchema = <ExtensionConnection, (List<FeatureFlag>, List<ConfigOption>)>{};

  /// Retrieve the cached `flutter build` targets synchronously.
  List<ExtensionBuildTarget> get cachedTargets =>
      _cachedBuildTargets ?? const <ExtensionBuildTarget>[];

  /// Retrieve the cached `flutter assemble` targets synchronously.
  @visibleForTesting
  List<ExtensionAssembleTarget> get cachedAssembleTargets =>
      _cachedAssembleTargets ?? const <ExtensionAssembleTarget>[];

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
        if (connectionMap.containsKey(name)) {
          _logger.printWarning(
            'Skipping duplicate $targetKind target "$name" from extension "${connection.extensionName}".',
          );
          continue;
        }
        targets.add(target);
        connectionMap[name] = connection;
      }
    }

    return targets;
  }

  /// Returns the snapshot of extension-owned `flutter config` values for the
  /// extension that owns assemble target [targetName].
  Future<Map<String, String?>> getAssembleTargetConfiguration(String targetName) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, String?>{};
    }
    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      return const <String, String?>{};
    }
    if (_cachedAssembleTargets == null) {
      await getAssembleTargets();
    }
    final ExtensionConnection? connection = _assembleTargetToConnection[targetName];
    if (connection == null) {
      return const <String, String?>{};
    }
    return _resolveExtensionConfiguration(connection);
  }

  Future<Map<String, String?>> _resolveExtensionConfiguration(
    ExtensionConnection connection,
  ) async {
    if (!connection.capabilities.services.contains(ConfigurationExtension.serviceNamespace)) {
      return const <String, String?>{};
    }
    (List<FeatureFlag>, List<ConfigOption>)? schema = _connectionConfigSchema[connection];
    if (schema == null) {
      final client = ConfigurationExtensionClient(connection, logger: _logger);
      final List<FeatureFlag> flags = await client.getFeatureFlags();
      final List<ConfigOption> options = await client.getConfigurations();
      schema = (flags, options);
      _connectionConfigSchema[connection] = schema;
    }
    final (List<FeatureFlag> featureFlags, List<ConfigOption> configOptions) = schema;
    final snapshot = <String, String?>{};
    for (final FeatureFlag(:String name, :bool enabledByDefault) in featureFlags) {
      if (name.isEmpty) {
        continue;
      }
      final Object? rawValue = _config?.getValue(name);
      final bool resolved = switch (rawValue) {
        final bool b => b,
        final String s when s.toLowerCase() == 'true' => true,
        final String s when s.toLowerCase() == 'false' => false,
        _ => enabledByDefault,
      };
      snapshot[name] = resolved.toString();
    }
    for (final ConfigOption(:String name, :String? value) in configOptions) {
      if (name.isEmpty) {
        continue;
      }
      final Object? rawValue = _config?.getValue(name);
      snapshot[name] = rawValue != null ? rawValue.toString() : value;
    }
    return snapshot;
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
    Map<String, bool> buildFlags = const <String, bool>{},
    String? buildName,
    String? buildNumber,
    Map<String, String?> buildOptions = const <String, String?>{},
    Uri? codeSizeDirectory,
    Map<String, String?>? configuration,
    Map<String, String> dartDefines = const <String, String>{},
    bool dartObfuscation = false,
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    String? flavor,
    Uri? splitDebugInfo,
    String? targetDeviceId,
    String? targetPlatform,
    bool? trackWidgetCreation,
    bool? treeShakeIcons,
  }) {
    return _executeBuildRpc(
      buildFlags: buildFlags,
      buildMode: buildMode,
      buildName: buildName,
      buildNumber: buildNumber,
      buildOptions: buildOptions,
      codeSizeDirectory: codeSizeDirectory,
      configuration: configuration,
      connectionMap: _buildTargetToConnection,
      dartDefines: dartDefines,
      dartObfuscation: dartObfuscation,
      ensureTargetsLoaded: () async {
        if (_cachedBuildTargets == null) {
          await getBuildTargets();
        }
      },
      extraFrontEndOptions: extraFrontEndOptions,
      extraGenSnapshotOptions: extraGenSnapshotOptions,
      flavor: flavor,
      flutterRoot: flutterRoot,
      mainPath: mainPath,
      outputDir: outputDir,
      projectRoot: projectRoot,
      resolvedArtifacts: resolvedArtifacts,
      rpcMethod: BuildService.buildMethod,
      splitDebugInfo: splitDebugInfo,
      targetDeviceId: targetDeviceId,
      targetKind: 'build',
      targetName: targetName,
      targetPlatform: targetPlatform,
      trackWidgetCreation: trackWidgetCreation ?? (buildMode == BuildMode.debug),
      treeShakeIcons: treeShakeIcons ?? buildMode.isPrecompiled,
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
    Map<String, bool> buildFlags = const <String, bool>{},
    String? buildName,
    String? buildNumber,
    Map<String, String?> buildOptions = const <String, String?>{},
    Uri? codeSizeDirectory,
    Map<String, String?>? configuration,
    Map<String, String> dartDefines = const <String, String>{},
    bool dartObfuscation = false,
    Map<String, String> extraDefines = const <String, String>{},
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    String? flavor,
    Uri? splitDebugInfo,
    String? targetDeviceId,
    String? targetPlatform,
    bool? trackWidgetCreation,
    bool? treeShakeIcons,
  }) {
    return _executeBuildRpc(
      buildDir: buildDir,
      buildFlags: buildFlags,
      buildMode: buildMode,
      buildName: buildName,
      buildNumber: buildNumber,
      buildOptions: buildOptions,
      codeSizeDirectory: codeSizeDirectory,
      configuration: configuration,
      connectionMap: _assembleTargetToConnection,
      dartDefines: dartDefines,
      dartObfuscation: dartObfuscation,
      ensureTargetsLoaded: () async {
        if (_cachedAssembleTargets == null) {
          await getAssembleTargets();
        }
      },
      extraDefines: extraDefines,
      extraFrontEndOptions: extraFrontEndOptions,
      extraGenSnapshotOptions: extraGenSnapshotOptions,
      flavor: flavor,
      flutterRoot: flutterRoot,
      mainPath: mainPath,
      outputDir: outputDir,
      projectRoot: projectRoot,
      resolvedArtifacts: resolvedArtifacts,
      rpcMethod: BuildService.assembleMethod,
      splitDebugInfo: splitDebugInfo,
      targetDeviceId: targetDeviceId,
      targetKind: 'assemble',
      targetName: targetName,
      targetPlatform: targetPlatform,
      trackWidgetCreation: trackWidgetCreation ?? (buildMode == BuildMode.debug),
      treeShakeIcons: treeShakeIcons ?? buildMode.isPrecompiled,
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
    required bool trackWidgetCreation,
    required bool treeShakeIcons,
    Uri? buildDir,
    Map<String, bool> buildFlags = const <String, bool>{},
    String? buildName,
    String? buildNumber,
    Map<String, String?> buildOptions = const <String, String?>{},
    Uri? codeSizeDirectory,
    Map<String, String?>? configuration,
    Map<String, String> dartDefines = const <String, String>{},
    bool dartObfuscation = false,
    Map<String, String> extraDefines = const <String, String>{},
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    String? flavor,
    Uri? splitDebugInfo,
    String? targetDeviceId,
    String? targetPlatform,
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
    if (codeSizeDirectory != null && !codeSizeDirectory.isValidDirectoryUri) {
      throw ArgumentError.value(
        codeSizeDirectory,
        'codeSizeDirectory',
        'Must be an absolute file:// directory URI ending with "/".',
      );
    }
    if (splitDebugInfo != null && !splitDebugInfo.isValidDirectoryUri) {
      throw ArgumentError.value(
        splitDebugInfo,
        'splitDebugInfo',
        'Must be an absolute file:// directory URI ending with "/".',
      );
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

    final Map<String, String?> resolvedConfiguration =
        connection.capabilities.services.contains(ConfigurationExtension.serviceNamespace)
        ? await _resolveExtensionConfiguration(connection)
        : (configuration ?? const <String, String?>{});

    var resolvedTargetPlatform = targetPlatform;
    if (resolvedTargetPlatform == null) {
      if (buildDir == null) {
        resolvedTargetPlatform = _cachedBuildTargets
            ?.where((ExtensionBuildTarget t) => t.name == targetName)
            .firstOrNull
            ?.targetPlatform;
      } else {
        resolvedTargetPlatform = _cachedAssembleTargets
            ?.where((ExtensionAssembleTarget t) => t.name == targetName)
            .firstOrNull
            ?.targetPlatform;
      }
    }

    try {
      final Object? result = await connection.sendRequest(
        rpcMethod,
        params: <String, Object?>{
          BuildService.buildDirParam: ?buildDir?.toString(),
          if (buildFlags.isNotEmpty) BuildService.buildFlagsParam: buildFlags,
          BuildService.buildModeParam: buildMode.cliName,
          BuildService.buildNameParam: ?buildName,
          BuildService.buildNumberParam: ?buildNumber,
          if (buildOptions.isNotEmpty) BuildService.buildOptionsParam: buildOptions,
          BuildService.codeSizeDirectoryParam: ?codeSizeDirectory?.toString(),
          if (resolvedConfiguration.isNotEmpty)
            BuildService.configurationParam: resolvedConfiguration,
          if (dartDefines.isNotEmpty) BuildService.dartDefinesParam: dartDefines,
          BuildService.dartObfuscationParam: dartObfuscation,
          if (buildDir != null && extraDefines.isNotEmpty)
            BuildService.extraDefinesParam: extraDefines,
          if (extraFrontEndOptions.isNotEmpty)
            BuildService.extraFrontEndOptionsParam: extraFrontEndOptions,
          if (extraGenSnapshotOptions.isNotEmpty)
            BuildService.extraGenSnapshotOptionsParam: extraGenSnapshotOptions,
          BuildService.flavorParam: ?flavor,
          BuildService.flutterRootParam: flutterRoot.toString(),
          BuildService.mainPathParam: mainPath,
          BuildService.outputDirParam: outputDir.toString(),
          BuildService.projectRootParam: projectRoot.toString(),
          BuildService.resolvedArtifactsParam: resolvedArtifacts,
          BuildService.splitDebugInfoParam: ?splitDebugInfo?.toString(),
          BuildService.targetDeviceIdParam: ?targetDeviceId,
          BuildService.targetNameParam: targetName,
          BuildService.targetPlatformParam: ?resolvedTargetPlatform,
          BuildService.trackWidgetCreationParam: trackWidgetCreation,
          BuildService.treeShakeIconsParam: treeShakeIcons,
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
