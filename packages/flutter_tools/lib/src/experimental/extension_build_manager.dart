// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as json_rpc_error;
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart'
    show TargetPlatform, getBuildDirectory, kBuildMode, kTargetFile, kTargetPlatform;
import '../build_system/targets/extension.dart'
    show
        kExtensionBuildTarget,
        kExtensionCCompilerAr,
        kExtensionCCompilerCc,
        kExtensionCCompilerEnvScript,
        kExtensionCCompilerEnvScriptArgs,
        kExtensionCCompilerLd,
        kExtensionCustomTargetPlatform,
        kExtensionPluginPlatformKey,
        nativeAssetsEnvironmentDefines,
        resolveExtensionBuildTargetArtifacts,
        resolveExtensionOutputDir;
import '../convert.dart';
import '../dart/package_map.dart';
import '../features.dart';
import '../flutter_plugins.dart';
import '../package_graph.dart';
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
  Map<String, String>? _cachedPluginPlatformDirectories;
  final _buildTargetToConnection = <String, ExtensionConnection>{};
  final _assembleTargetToConnection = <String, ExtensionConnection>{};
  final _pluginPlatformToConnection = <String, ExtensionConnection>{};
  final _buildTargetsByName = <String, ExtensionBuildTarget>{};

  static const _kDillStampFileSuffix = '.dill.stamp';
  static const _kExtensionPluginsStampFileName = 'extension_plugins.stamp';
  static const _kExtensionsDirName = 'extensions';
  static const _kFlutterBuildDirName = 'flutter_build';
  static const _kFlutterToolsDirName = 'flutter_tools';
  static const _kGetPluginPlatformDirectoriesMethod = 'build.getPluginPlatformDirectories';
  static const _kInjectPluginsMethod = 'build.injectPlugins';
  static const _kStampExtensionDillStampsKey = 'extensionDillStamps';
  static const _kStampFlutterPluginsDependenciesHashKey = 'flutterPluginsDependenciesHash';
  static const _kStampPackageConfigHashKey = 'packageConfigHash';
  static const _kStampPlatformDirectoriesKey = 'platformDirectories';
  static const _kStampReleaseModeKey = 'releaseMode';

  /// Deletes `.dart_tool/flutter_build/extension_plugins.stamp` under
  /// [projectDirectory] if present (for example, when `flutter create`
  /// scaffolds or re-scaffolds platform runner directories).
  static void deletePluginsStamp(Directory projectDirectory) {
    ErrorHandlingFileSystem.deleteIfExists(_pluginsStampFile(projectDirectory));
  }

  static File _pluginsStampFile(Directory projectDirectory) => projectDirectory
      .childDirectory('.dart_tool')
      .childDirectory(_kFlutterBuildDirName)
      .childFile(_kExtensionPluginsStampFileName);

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

  static const _cCompilerDefineKeys = <String>{
    kExtensionCCompilerCc,
    kExtensionCCompilerAr,
    kExtensionCCompilerLd,
    kExtensionCCompilerEnvScript,
    kExtensionCCompilerEnvScriptArgs,
  };

  static bool _isBuiltInTargetPlatform(String platform) {
    try {
      TargetPlatform.fromName(platform);
      return true;
    } on Exception {
      return false;
    }
  }

  /// Returns whether [platform] matches a build or assemble target registered
  /// by an active tool extension.
  Future<bool> isRegisteredTargetPlatform(String platform) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return false;
    }
    final List<ExtensionBuildTarget> buildTargets = await getBuildTargets();
    if (buildTargets.any(
      (ExtensionBuildTarget t) => t.name == platform || t.targetPlatform == platform,
    )) {
      return true;
    }
    final List<ExtensionAssembleTarget> assembleTargets = await getAssembleTargets();
    return assembleTargets.any((ExtensionAssembleTarget t) => t.targetPlatform == platform);
  }

  /// Returns the `flutter assemble` environment defines for [targetName],
  /// including `kExtensionBuildTarget`, `kExtensionHookTargetOs`,
  /// `kExtensionHookTargetArch`, `kExtensionCCompiler*` from
  /// [nativeAssetsConfig], and `kExtensionPluginPlatformKey` when configured on
  /// the [ExtensionBuildTarget].
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
      if (nativeAssetsConfig != null) ...nativeAssetsEnvironmentDefines(nativeAssetsConfig),
      if (target.pluginPlatformKey case final String key when key.isNotEmpty)
        kExtensionPluginPlatformKey: key,
    };
  }

  /// Resolves extension `flutter assemble` environment defines for the current
  /// invocation without overwriting explicit CLI [defines].
  Future<Map<String, String>> resolveAssembleEnvironmentDefines({
    required Artifacts artifacts,
    required Config config,
    required Map<String, String> defines,
    required Uri flutterRoot,
    required Directory projectDir,
    List<String> requestedAssembleTargetNames = const <String>[],
  }) async {
    final String? explicitTargetName = defines[kExtensionBuildTarget]?.trim();
    final bool hasExplicitBuildTarget = explicitTargetName != null && explicitTargetName.isNotEmpty;
    if (!_featureFlags.isToolExtensionsEnabled) {
      if (hasExplicitBuildTarget) {
        throwToolExit(
          '"$kExtensionBuildTarget" requires the tool extensions feature to be enabled.',
        );
      }
      return const <String, String>{};
    }

    final String? platform = defines[kTargetPlatform];
    final bool hasPlatform = platform != null && platform.isNotEmpty;
    final bool isBuiltInPlatform = hasPlatform && _isBuiltInTargetPlatform(platform);
    if (!hasExplicitBuildTarget &&
        requestedAssembleTargetNames.isEmpty &&
        (!hasPlatform || isBuiltInPlatform)) {
      return const <String, String>{};
    }

    final List<ExtensionBuildTarget> buildTargets = await getBuildTargets();
    final ExtensionBuildTarget? matchedTarget = await _matchAssembleBuildTarget(
      buildTargets: buildTargets,
      explicitTargetName: hasExplicitBuildTarget ? explicitTargetName : null,
      isBuiltInPlatform: isBuiltInPlatform,
      platform: hasPlatform ? platform : null,
      requestedAssembleTargetNames: requestedAssembleTargetNames,
    );
    if (matchedTarget == null) {
      if (hasPlatform &&
          !isBuiltInPlatform &&
          !defines.containsKey(kExtensionCustomTargetPlatform)) {
        final List<ExtensionAssembleTarget> assembleTargets = await getAssembleTargets();
        if (assembleTargets.any((ExtensionAssembleTarget t) => t.targetPlatform == platform)) {
          return <String, String>{kExtensionCustomTargetPlatform: 'true'};
        }
      }
      return const <String, String>{};
    }

    final String? buildModeName = defines[kBuildMode];
    final BuildMode buildMode;
    if (buildModeName == null || buildModeName.isEmpty) {
      buildMode = BuildMode.debug;
    } else {
      try {
        buildMode = BuildMode.fromCliName(buildModeName);
      } on ArgumentError {
        throwToolExit('Invalid "$kBuildMode" define: "$buildModeName".');
      }
    }
    final Map<String, String> resolvedArtifacts = resolveExtensionBuildTargetArtifacts(
      artifacts: artifacts,
      buildMode: buildMode,
      target: matchedTarget,
    );
    final Directory targetOutputDir = resolveExtensionOutputDir(
      buildMode: buildMode,
      buildOutputDir: projectDir.childDirectory(getBuildDirectory(config, _fileSystem)),
      fileSystem: _fileSystem,
      projectDir: projectDir,
      target: matchedTarget,
    );
    final ExtensionNativeAssetsConfig? nativeAssetsConfig = await resolveNativeAssetsConfig(
      buildMode: buildMode,
      flutterRoot: flutterRoot,
      mainPath: defines[kTargetFile] ?? 'lib/main.dart',
      outputDir: targetOutputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolvedArtifacts,
      targetName: matchedTarget.name,
    );
    final candidateDefines = <String, String>{
      if (hasPlatform && !isBuiltInPlatform) kExtensionCustomTargetPlatform: 'true',
      ...environmentDefinesForTarget(matchedTarget.name, nativeAssetsConfig: nativeAssetsConfig),
    };
    final bool hasCliCompilerOverride = _cCompilerDefineKeys.any(defines.containsKey);
    return <String, String>{
      for (final MapEntry(:String key, :String value) in candidateDefines.entries)
        if (!defines.containsKey(key) &&
            (!hasCliCompilerOverride || !_cCompilerDefineKeys.contains(key)))
          key: value,
    };
  }

  Future<ExtensionBuildTarget?> _matchAssembleBuildTarget({
    required List<ExtensionBuildTarget> buildTargets,
    required String? explicitTargetName,
    required bool isBuiltInPlatform,
    required String? platform,
    required List<String> requestedAssembleTargetNames,
  }) async {
    if (explicitTargetName != null) {
      final ExtensionBuildTarget? target = buildTargets
          .where((ExtensionBuildTarget t) => t.name == explicitTargetName)
          .firstOrNull;
      if (target == null) {
        throwToolExit(
          'Unknown extension build target "$explicitTargetName" specified in "$kExtensionBuildTarget".',
        );
      }
      return target;
    }

    if (requestedAssembleTargetNames.isNotEmpty) {
      if (_cachedAssembleTargets == null) {
        await getAssembleTargets();
      }
      final owningConnections = <ExtensionConnection>{
        for (final String name in requestedAssembleTargetNames) ?_assembleTargetToConnection[name],
      };
      final List<ExtensionBuildTarget> candidates = owningConnections.isEmpty
          ? buildTargets
          : buildTargets
                .where(
                  (ExtensionBuildTarget t) =>
                      owningConnections.contains(_buildTargetToConnection[t.name]),
                )
                .toList();
      final String? resolvedPlatform =
          platform ??
          _cachedAssembleTargets
              ?.where((ExtensionAssembleTarget t) => requestedAssembleTargetNames.contains(t.name))
              .firstOrNull
              ?.targetPlatform;
      if (resolvedPlatform == null || resolvedPlatform.isEmpty) {
        return null;
      }
      final ExtensionBuildTarget? nameMatch = candidates
          .where((ExtensionBuildTarget t) => t.name == resolvedPlatform)
          .firstOrNull;
      if (nameMatch != null) {
        return nameMatch;
      }
      final List<ExtensionBuildTarget> platformMatches = candidates
          .where((ExtensionBuildTarget t) => t.targetPlatform == resolvedPlatform)
          .toList();
      if (platformMatches.length == 1) {
        return platformMatches.single;
      }
      if (platformMatches.length > 1) {
        if (platform != null && !isBuiltInPlatform) {
          _throwAmbiguousTargetPlatform(platform, platformMatches);
        }
        final String matchingNames = platformMatches
            .map((ExtensionBuildTarget t) => '"${t.name}"')
            .join(', ');
        _logger.printTrace(
          'Skipping automatic extension build target inference for "$resolvedPlatform" because '
          'multiple targets match ($matchingNames); pass -d$kExtensionBuildTarget=<name> to '
          'select a specific build target.',
        );
      }
      return null;
    }

    if (platform == null || platform.isEmpty) {
      return null;
    }
    final ExtensionBuildTarget? nameMatch = buildTargets
        .where((ExtensionBuildTarget t) => t.name == platform)
        .firstOrNull;
    if (nameMatch != null) {
      return nameMatch;
    }
    final List<ExtensionBuildTarget> platformMatches = buildTargets
        .where((ExtensionBuildTarget t) => t.targetPlatform == platform)
        .toList();
    if (platformMatches.length > 1) {
      _throwAmbiguousTargetPlatform(platform, platformMatches);
    }
    return platformMatches.firstOrNull;
  }

  Never _throwAmbiguousTargetPlatform(String platform, List<ExtensionBuildTarget> matches) {
    final String matchingNames = matches.map((ExtensionBuildTarget t) => '"${t.name}"').join(', ');
    throwToolExit(
      'Ambiguous custom target platform "$platform" matches multiple extension '
      'build targets ($matchingNames); pass -d$kExtensionBuildTarget=<name> to '
      'select a specific build target.',
    );
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
      pluginPlatformKey: pluginPlatformKey,
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
    String? pluginPlatformKey,
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
      pluginPlatformKey:
          pluginPlatformKey ??
          (targetKind == 'build' ? _buildTargetsByName[targetName]?.pluginPlatformKey : null),
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
    final List<ExtensionPlugin> resolvedPlugins;
    if (pluginPlatformKey == null || pluginPlatformKey.isEmpty) {
      resolvedPlugins = const <ExtensionPlugin>[];
    } else {
      final FlutterProject project = _projectFactory.fromDirectory(
        _fileSystem.directory(projectRoot),
      );
      final Map<String, List<ExtensionPlugin>> resolved = await _resolvePluginsForPlatforms(
        project,
        <String>{pluginPlatformKey},
        releaseMode: buildMode.isRelease,
      );
      resolvedPlugins = resolved[pluginPlatformKey] ?? const <ExtensionPlugin>[];
    }
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

  /// Queries active tool extensions for `flutter.plugin.platforms.<key>` to
  /// project-relative runner directory mappings (`build.getPluginPlatformDirectories`).
  Future<Map<String, String>> getPluginPlatformDirectories() async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return const <String, String>{};
    }
    if (_cachedPluginPlatformDirectories case final Map<String, String> cached) {
      return cached;
    }

    try {
      await _extensionManager.ensureInitialized();
    } on Object catch (e) {
      _logger.printTrace('Failed to initialize extension manager: $e');
      return const <String, String>{};
    }

    _pluginPlatformToConnection.clear();
    final List<ExtensionConnection> connections = _extensionManager.connections
        .where(
          (ExtensionConnection connection) =>
              connection.capabilities.services.contains(BuildService.serviceNamespace),
        )
        .sortedBy((ExtensionConnection c) => c.extensionName);

    final List<(ExtensionConnection, Map<String, String>)> responses = await Future.wait(
      connections.map((ExtensionConnection connection) async {
        try {
          final Object? result = await connection.sendRequest(_kGetPluginPlatformDirectoriesMethod);
          if (result case final Map<String, Object?> rawMap) {
            final parsed = <String, String>{};
            for (final MapEntry(:String key, :Object? value) in rawMap.entries) {
              if (value is! String) {
                _logger.printWarning(
                  'Invalid plugin platform directories response from extension '
                  '"${connection.extensionName}": expected string runner directory for "$key", '
                  'got ${value.runtimeType}.',
                );
                return (connection, const <String, String>{});
              }
              parsed[key] = value;
            }
            return (connection, parsed);
          }
          _logger.printWarning(
            'Invalid plugin platform directories response from extension '
            '"${connection.extensionName}": expected Map<String, String>.',
          );
          return (connection, const <String, String>{});
        } on Object catch (e) {
          switch (e) {
            case final ToolExtensionException e:
              _logger.printWarning('Extension "${connection.extensionName}": ${e.message}');
            case final RpcException e when e.code == json_rpc_error.METHOD_NOT_FOUND:
              _logger.printTrace(
                'Extension "${connection.extensionName}" does not implement '
                '"$_kGetPluginPlatformDirectoriesMethod".',
              );
            case _:
              _logger.printWarning(
                'Failed to query plugin platform directories from extension '
                '"${connection.extensionName}": $e',
              );
          }
          return (connection, const <String, String>{});
        }
      }),
    );

    final directories = <String, String>{};
    for (final (ExtensionConnection connection, Map<String, String> entries) in responses) {
      for (final MapEntry(key: String platformKey, value: String rawRunnerDir) in entries.entries) {
        if (Plugin.builtInPlatformKeys.contains(platformKey)) {
          _logger.printWarning(
            'Skipping plugin platform "$platformKey" from extension "${connection.extensionName}" '
            'because "$platformKey" is a built-in platform.',
          );
          continue;
        }
        if (!ExtensionBuildTarget.isValidPluginPlatformKey(platformKey)) {
          _logger.printWarning(
            'Skipping invalid plugin platform key "$platformKey" from extension '
            '"${connection.extensionName}".',
          );
          continue;
        }
        final String? normalizedRunnerDir = _normalizeRelativeRunnerDir(rawRunnerDir);
        if (normalizedRunnerDir == null) {
          _logger.printWarning(
            'Skipping plugin platform "$platformKey" from extension "${connection.extensionName}": '
            'runner directory "$rawRunnerDir" must be a relative path within the project root.',
          );
          continue;
        }
        if (_pluginPlatformToConnection[platformKey] case final ExtensionConnection existing) {
          _logger.printWarning(
            'Skipping duplicate plugin platform "$platformKey" from extension '
            '"${connection.extensionName}" (already registered by extension '
            '"${existing.extensionName}").',
          );
          continue;
        }
        directories[platformKey] = normalizedRunnerDir;
        _pluginPlatformToConnection[platformKey] = connection;
      }
    }

    final result = Map<String, String>.unmodifiable(directories);
    _cachedPluginPlatformDirectories = result;
    return result;
  }

  /// Invokes `BuildService.injectPlugins` for each extension-declared platform
  /// whose runner directory exists under [project] when stamp inputs have
  /// changed relative to `.dart_tool/flutter_build/extension_plugins.stamp`.
  Future<void> injectPlugins(
    FlutterProject project, {
    required bool releaseMode,
    PackageConfig? packageConfig,
    PackageGraph? packageGraph,
    PubspecCache? pubspecCache,
  }) async {
    if (!_featureFlags.isToolExtensionsEnabled) {
      return;
    }

    final File stampFile = _pluginsStampFile(project.directory);
    final Map<String, String> platformDirectories = await getPluginPlatformDirectories();
    final existingPlatformDirectories = <String, String>{
      for (final MapEntry(key: String platformKey, value: String runnerDir)
          in platformDirectories.entries)
        if (project.directory.childDirectory(runnerDir).existsSync()) platformKey: runnerDir,
    };
    if (existingPlatformDirectories.isEmpty) {
      ErrorHandlingFileSystem.deleteIfExists(stampFile);
      return;
    }

    // Hash `.dart_tool/flutter_tools/extensions/**/*.dill.stamp` when that
    // directory exists on disk (RFC 510.0000 §4.6), falling back to
    // `.dart_tool/package_config.json` before the `.dill` cache has been populated.
    final String stamp = _encodeExtensionPluginsStamp(
      project,
      existingPlatformDirectories: existingPlatformDirectories,
      releaseMode: releaseMode,
    );
    if (stampFile.existsSync() && stampFile.readAsStringSync() == stamp) {
      return;
    }

    final Map<String, List<ExtensionPlugin>> pluginsByPlatform = await _resolvePluginsForPlatforms(
      project,
      existingPlatformDirectories.keys,
      packageConfig: packageConfig,
      packageGraph: packageGraph,
      pubspecCache: pubspecCache,
      releaseMode: releaseMode,
    );
    final ExtensionFlutterProject extensionProject = project.toExtensionProject();
    for (final MapEntry(key: String platformKey, value: String runnerDir)
        in existingPlatformDirectories.entries) {
      final ExtensionConnection connection = _pluginPlatformToConnection[platformKey]!;
      final context = ExtensionPluginInjectionContext(
        pluginPlatformKey: platformKey,
        plugins: pluginsByPlatform[platformKey] ?? const <ExtensionPlugin>[],
        project: extensionProject,
        releaseMode: releaseMode,
        runnerDirectory: project.directory.childDirectory(runnerDir).absolute.uri,
      );
      try {
        await connection.sendRequest(_kInjectPluginsMethod, params: context.toMap(), timeout: null);
      } on Exception catch (e) {
        final String detail = e is ToolExtensionException ? e.message : '$e';
        throwToolExit(
          'Failed to inject "$platformKey" plugins via extension '
          '"${connection.extensionName}": $detail',
        );
      }
    }

    stampFile.parent.createSync(recursive: true);
    stampFile.writeAsStringSync(stamp, flush: true);
  }

  Future<Map<String, List<ExtensionPlugin>>> _resolvePluginsForPlatforms(
    FlutterProject project,
    Iterable<String> platformKeys, {
    required bool releaseMode,
    PackageConfig? packageConfig,
    PackageGraph? packageGraph,
    PubspecCache? pubspecCache,
  }) async {
    final Set<String> keys = platformKeys.toSet();
    if (keys.isEmpty || !project.pubspecFile.existsSync()) {
      return <String, List<ExtensionPlugin>>{
        for (final String key in keys) key: const <ExtensionPlugin>[],
      };
    }
    final List<Plugin> foundPlugins = await findPlugins(
      project,
      extraPlatformKeys: keys,
      logger: _logger,
      packageConfig: packageConfig,
      packageGraph: packageGraph,
      pubspecCache: pubspecCache,
      throwOnError: false,
    );
    return <String, List<ExtensionPlugin>>{
      for (final String key in keys)
        key: foundPlugins.isEmpty
            ? const <ExtensionPlugin>[]
            : resolveExtensionPluginsForPlatform(
                foundPlugins,
                key,
                fileSystem: _fileSystem,
                includeDevDependencies: !releaseMode,
                logger: _logger,
              ),
    };
  }

  static String _encodeExtensionPluginsStamp(
    FlutterProject project, {
    required Map<String, String> existingPlatformDirectories,
    required bool releaseMode,
  }) {
    final File packageConfigFile = findPackageConfigFileOrDefault(project.directory);
    final Directory extensionsDir = packageConfigFile.parent
        .childDirectory(_kFlutterToolsDirName)
        .childDirectory(_kExtensionsDirName);
    final Map<String, String>? extensionDillStamps = _hashExtensionDillStamps(extensionsDir);
    return json.encode(<String, Object?>{
      _kStampExtensionDillStampsKey: extensionDillStamps,
      _kStampFlutterPluginsDependenciesHashKey: _hashFileIfExists(
        project.flutterPluginsDependenciesFile,
      ),
      _kStampPackageConfigHashKey: extensionDillStamps == null
          ? _hashFileIfExists(packageConfigFile)
          : null,
      _kStampPlatformDirectoriesKey: <String, String>{
        for (final String key in existingPlatformDirectories.keys.sorted())
          key: existingPlatformDirectories[key]!,
      },
      _kStampReleaseModeKey: releaseMode,
    });
  }

  static Map<String, String>? _hashExtensionDillStamps(Directory extensionsDir) {
    if (!extensionsDir.existsSync()) {
      return null;
    }
    final FileSystem fileSystem = extensionsDir.fileSystem;
    final List<File> stampFiles;
    try {
      stampFiles = <File>[
        for (final FileSystemEntity entity in extensionsDir.listSync(
          recursive: true,
          followLinks: false,
        ))
          if (entity is File && entity.path.endsWith(_kDillStampFileSuffix)) entity,
      ];
    } on FileSystemException {
      return null;
    }
    final unsorted = <String, String>{
      for (final File stampFile in stampFiles)
        if (_hashFileIfExists(stampFile) case final String hash)
          fileSystem.path
                  .split(fileSystem.path.relative(stampFile.path, from: extensionsDir.path))
                  .join('/'):
              hash,
    };
    return <String, String>{
      for (final String path in unsorted.keys.sorted()) path: unsorted[path]!,
    };
  }

  String? _normalizeRelativeRunnerDir(String raw) {
    if (!_fileSystem.path.isRelative(raw)) {
      return null;
    }
    final String normalized = _fileSystem.path.normalize(raw);
    final String firstSegment = _fileSystem.path.split(normalized).first;
    if (firstSegment == '.' || firstSegment == '..') {
      return null;
    }
    return normalized;
  }

  static String? _hashFileIfExists(File file) {
    if (!file.existsSync()) {
      return null;
    }
    try {
      return sha256.convert(file.readAsBytesSync()).toString();
    } on FileSystemException {
      return null;
    }
  }
}
