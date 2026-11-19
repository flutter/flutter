// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../base/config.dart';
import '../base/logger.dart';
import '../base/platform.dart';
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
    this._platform,
  });

  final Config? _config;
  final ExtensionManager _extensionManager;
  final FeatureFlags _featureFlags;
  final Logger _logger;
  final Platform? _platform;

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

  /// Returns the snapshot of extension-owned `flutter config` values for the
  /// extension that owns assemble target [targetName].
  Future<Map<String, Object?>> getAssembleTargetConfiguration(String targetName) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, Object?>{};
    }
    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      return const <String, Object?>{};
    }
    if (_cachedAssembleTargets == null) {
      await getAssembleTargets();
    }
    final ExtensionConnection? connection = _assembleTargetToConnection[targetName];
    if (connection == null) {
      return const <String, Object?>{};
    }
    return _resolveExtensionConfiguration(connection);
  }

  Future<Map<String, Object?>> _resolveExtensionConfiguration(
    ExtensionConnection connection,
  ) async {
    if (!connection.capabilities.services.contains(ConfigurationExtension.serviceNamespace)) {
      return const <String, Object?>{};
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
    Map<String, Object?>? extensionSettings;
    if (_config?.getValue('extensions') case final Map<String, Object?> extensionsMap) {
      if (extensionsMap[connection.extensionName] case final Map<String, Object?> extMap) {
        extensionSettings = extMap;
      }
    }

    Object? lookupPersistedSetting(String key) {
      if (extensionSettings != null && extensionSettings.containsKey(key)) {
        return extensionSettings[key];
      }
      return _config?.getValue(key);
    }

    final snapshot = <String, Object?>{};
    for (final FeatureFlag(:String name, :String? environmentVariable, :bool enabledByDefault)
        in featureFlags) {
      if (name.isEmpty) {
        continue;
      }
      bool? envOverride;
      if (environmentVariable != null && environmentVariable.isNotEmpty) {
        envOverride = _parseOptionalBool(_platform?.environment[environmentVariable]);
      }
      final bool resolved =
          envOverride ?? _parseOptionalBool(lookupPersistedSetting(name)) ?? enabledByDefault;
      snapshot[name] = resolved;
    }
    for (final ConfigOption(:String name, :String? value) in configOptions) {
      if (name.isEmpty) {
        continue;
      }
      final Object? rawValue = lookupPersistedSetting(name);
      final String? resolved = rawValue != null ? '$rawValue' : value;
      if (resolved != null) {
        snapshot[name] = resolved;
      }
    }
    return snapshot;
  }

  static bool? _parseOptionalBool(Object? rawValue) => switch (rawValue) {
    final bool b => b,
    final String s when s.toLowerCase() == 'true' || s == '1' => true,
    final String s when s.toLowerCase() == 'false' || s == '0' => false,
    _ => null,
  };

  /// Triggers a custom `flutter build` target for [targetName] by routing to the
  /// owning extension, throwing a [ToolExtensionException] if the build fails.
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
    Map<String, String> buildOptions = const <String, String>{},
    Uri? codeSizeDirectory,
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
  }) async {
    final (ExtensionConnection connection, Object? result) = await _sendBuildOrAssembleRpc(
      buildFlags: buildFlags,
      buildMode: buildMode,
      buildName: buildName,
      buildNumber: buildNumber,
      buildOptions: buildOptions,
      codeSizeDirectory: codeSizeDirectory,
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
    if (result case final Map<String, Object?> resultMap) {
      try {
        return ExtensionBuildResult.fromJson(resultMap);
      } on FormatException catch (e) {
        throw ToolExtensionException(
          'Invalid build result from extension "${connection.extensionName}": ${e.message}',
        );
      }
    }
    throw ToolExtensionException(
      'Invalid build result from extension "${connection.extensionName}".',
    );
  }

  /// Triggers a custom `flutter assemble` target for [targetName] by routing to
  /// the owning extension, throwing a [ToolExtensionException] if the step fails.
  Future<void> assemble({
    required Uri buildDir,
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
    String? buildName,
    String? buildNumber,
    Uri? codeSizeDirectory,
    Map<String, Object?>? configuration,
    Map<String, String> dartDefines = const <String, String>{},
    bool dartObfuscation = false,
    Map<String, String> extraDefines = const <String, String>{},
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    String? flavor,
    Uri? splitDebugInfo,
    String? targetPlatform,
    bool? trackWidgetCreation,
    bool? treeShakeIcons,
  }) async {
    await _sendBuildOrAssembleRpc(
      buildDir: buildDir,
      buildMode: buildMode,
      buildName: buildName,
      buildNumber: buildNumber,
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
      targetKind: 'assemble',
      targetName: targetName,
      targetPlatform: targetPlatform,
      trackWidgetCreation: trackWidgetCreation ?? (buildMode == BuildMode.debug),
      treeShakeIcons: treeShakeIcons ?? buildMode.isPrecompiled,
    );
  }

  Future<(ExtensionConnection, Object?)> _sendBuildOrAssembleRpc({
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
    Map<String, String> buildOptions = const <String, String>{},
    Uri? codeSizeDirectory,
    Map<String, Object?>? configuration,
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
      throw const ToolExtensionException('Tool extensions are disabled.');
    }

    try {
      await _extensionManager.ensureInitialized();
    } on ToolExtensionException {
      rethrow;
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      throw ToolExtensionException('Failed to initialize extension manager: $e');
    }

    await ensureTargetsLoaded();

    final ExtensionConnection? connection = connectionMap[targetName];
    if (connection == null) {
      throw ToolExtensionException('No extension found to handle $targetKind target $targetName.');
    }

    final Map<String, Object?> resolvedConfiguration =
        buildDir == null &&
            connection.capabilities.services.contains(ConfigurationExtension.serviceNamespace)
        ? await _resolveExtensionConfiguration(connection)
        : (configuration ?? const <String, Object?>{});

    var resolvedTargetPlatform = targetPlatform;
    if (resolvedTargetPlatform == null) {
      if (buildDir == null) {
        resolvedTargetPlatform = _cachedBuildTargets
            ?.where((ExtensionBuildTarget t) => t.name == targetName)
            .firstOrNull
            ?.targetPlatforms
            .firstOrNull;
      } else {
        resolvedTargetPlatform = _cachedAssembleTargets
            ?.where((ExtensionAssembleTarget t) => t.name == targetName)
            .firstOrNull
            ?.targetPlatform;
      }
    }

    final Map<String, Object?> contextParams = buildDir != null
        ? ExtensionAssembleContext(
            buildDir: buildDir,
            buildMode: buildMode,
            buildName: buildName,
            buildNumber: buildNumber,
            codeSizeDirectory: codeSizeDirectory,
            configuration: resolvedConfiguration,
            dartDefines: dartDefines,
            dartObfuscation: dartObfuscation,
            extraDefines: extraDefines,
            extraFrontEndOptions: extraFrontEndOptions,
            extraGenSnapshotOptions: extraGenSnapshotOptions,
            flavor: flavor,
            flutterRoot: flutterRoot,
            mainPath: mainPath,
            outputDir: outputDir,
            projectRoot: projectRoot,
            resolvedArtifacts: resolvedArtifacts,
            splitDebugInfo: splitDebugInfo,
            targetPlatform: resolvedTargetPlatform,
            trackWidgetCreation: trackWidgetCreation,
            treeShakeIcons: treeShakeIcons,
          ).toMap()
        : ExtensionBuildContext(
            buildFlags: buildFlags,
            buildMode: buildMode,
            buildName: buildName,
            buildNumber: buildNumber,
            buildOptions: buildOptions,
            codeSizeDirectory: codeSizeDirectory,
            configuration: resolvedConfiguration,
            dartDefines: dartDefines,
            dartObfuscation: dartObfuscation,
            extraFrontEndOptions: extraFrontEndOptions,
            extraGenSnapshotOptions: extraGenSnapshotOptions,
            flavor: flavor,
            flutterRoot: flutterRoot,
            mainPath: mainPath,
            outputDir: outputDir,
            projectRoot: projectRoot,
            resolvedArtifacts: resolvedArtifacts,
            splitDebugInfo: splitDebugInfo,
            targetDeviceId: targetDeviceId,
            targetPlatform: resolvedTargetPlatform,
            trackWidgetCreation: trackWidgetCreation,
            treeShakeIcons: treeShakeIcons,
          ).toMap();

    try {
      final Object? result = await connection.sendRequest(
        rpcMethod,
        params: <String, Object?>{BuildService.targetNameParam: targetName, ...contextParams},
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
        timeout: null,
      );
      return (connection, result);
    } on ToolExtensionException {
      rethrow;
    } on Object catch (e) {
      _logger.printTrace('Failed to run $targetKind from extension: $e');
      throw ToolExtensionException(e.toString());
    }
  }
}
