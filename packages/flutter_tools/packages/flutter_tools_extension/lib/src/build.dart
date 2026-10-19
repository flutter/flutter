// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';

import 'protocol_base/service.dart';

/// Context passed to an extension target's [BuildTarget.build] or
/// [AssembleTarget.build] method.
@immutable
class ExtensionBuildContext {
  const ExtensionBuildContext({
    required this.buildDir,
    required this.buildMode,
    required this.flutterRoot,
    required this.mainPath,
    required this.outputDir,
    required this.projectRoot,
    required this.resolvedArtifacts,
  });

  /// The absolute directory URI (ending with `/`) used for temporary build artifacts.
  final Uri buildDir;

  /// The compilation mode for the build.
  final BuildMode buildMode;

  /// The absolute directory URI (ending with `/`) to the Flutter SDK root directory.
  final Uri flutterRoot;

  /// The path to the main entrypoint file (typically `lib/main.dart`).
  final String mainPath;

  /// The absolute directory URI (ending with `/`) where final build outputs should be placed.
  final Uri outputDir;

  /// The absolute directory URI (ending with `/`) to the root directory of the Flutter project being built.
  final Uri projectRoot;

  /// A map of resolved engine artifact names to their absolute paths on the host.
  ///
  /// Keys correspond to [ExtensionArtifact.name] or [ExtensionHostArtifact.name] values.
  final Map<String, String> resolvedArtifacts;
}

/// Abstract target for a custom `flutter build <subcommand>` target.
///
/// Extensions should extend this class to contribute top-level `flutter build`
/// subcommands via [BuildService.buildTargets].
@immutable
abstract class BuildTarget {
  const BuildTarget({
    required this.description,
    required this.targetPlatform,
    this.outputDir = '${BuiltInPlaceholders.projectDir}/build',
  });

  /// The user-readable name of the target (exposed as `flutter build <name>`).
  String get name;

  /// Description of what this target builds.
  final String description;

  /// The target platform identifier (e.g. `'linux-x64'`, `'custom-embedder-arm64'`).
  ///
  /// This is an open [String] rather than an enum so that extensions for custom
  /// embedders can declare platform identifiers that are not built into Flutter.
  /// Used to substitute [BuiltInPlaceholders.targetPlatform] in [outputDir], and as the
  /// default artifact platform when it matches a built-in Flutter target platform.
  // TODO(bkonyi): Support target-platform agnostic BuildTargets, https://github.com/flutter/flutter/issues/194810.
  final String targetPlatform;

  /// The directory pattern used by `flutter build` to determine this target's
  /// output directory (`{OUTPUT_DIR}`), for example
  /// `'${BuiltInPlaceholders.projectDir}/build/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}'`.
  ///
  /// Defaults to `'${BuiltInPlaceholders.projectDir}/build'`. Note that `{BUILD_DIR}`
  /// refers to the intermediate assemble scratch directory (`.dart_tool/flutter_build`),
  /// whereas `{PROJECT_DIR}/build` is the project's top-level `build/` directory.
  ///
  /// Supports [BuiltInPlaceholders.projectDir], [BuiltInPlaceholders.buildDir],
  /// [BuiltInPlaceholders.buildMode], and [BuiltInPlaceholders.targetPlatform].
  final String outputDir;

  /// Engine artifacts required by this build target, resolved for [targetPlatform]
  /// and the active [BuildMode].
  Set<ExtensionArtifact> get artifacts => const <ExtensionArtifact>{};

  /// Host-side build tool or library artifacts required by this build target.
  Set<ExtensionHostArtifact> get hostArtifacts => const <ExtensionHostArtifact>{};

  /// Performs the actual compilation/build steps in the extension process/isolate.
  ///
  /// Access resolved artifact paths from [ExtensionBuildContext.resolvedArtifacts] using
  /// [ExtensionArtifact.name] or [ExtensionHostArtifact.name] as keys.
  /// Returns an [ExtensionBuildResult] indicating whether the build succeeded.
  Future<ExtensionBuildResult> build(ExtensionBuildContext context);
}

/// Abstract target for a custom `flutter assemble <target>` DAG node.
///
/// Extensions should extend this class to contribute `flutter assemble` targets
/// with tracked [dependencies], [inputs], and [outputs] via [BuildService.assembleTargets].
@immutable
abstract class AssembleTarget {
  const AssembleTarget({required this.description, required this.targetPlatform});

  /// The user-readable name of the assemble target.
  String get name;

  /// Description of what this target builds.
  final String description;

  /// The target platform identifier (e.g. `'linux-x64'`, `'custom-embedder-arm64'`).
  ///
  /// This is an open [String] rather than an enum so that extensions for custom
  /// embedders can declare platform identifiers that are not built into Flutter.
  /// Used as the default artifact platform when it matches a built-in Flutter target platform.
  final String targetPlatform;

  /// The names of other assemble targets that this target depends on.
  List<String> get dependencies => const <String>[];

  /// The input [ExtensionSource]s for this target.
  List<ExtensionSource> get inputs => const <ExtensionSource>[];

  /// Output file patterns produced by this target (for example,
  /// `ExtensionSource.pattern('${BuiltInPlaceholders.outputDir}/app.bundle')`).
  List<ExtensionSource> get outputs => const <ExtensionSource>[];

  /// Performs the actual compilation/build steps in the extension process/isolate.
  ///
  /// Access resolved artifact paths from [ExtensionBuildContext.resolvedArtifacts] using
  /// [ExtensionArtifact.name] or [ExtensionHostArtifact.name] as keys.
  /// Returns an [ExtensionBuildResult] indicating whether the build succeeded.
  Future<ExtensionBuildResult> build(ExtensionBuildContext context);
}

/// Extension service interface for custom builds.
///
/// Automatically routes build and assemble RPC calls to the registered
/// [buildTargets] and [assembleTargets].
abstract base class BuildService extends ToolExtensionService {
  /// Service namespace identifier for custom builds.
  static const String serviceNamespace = 'build';

  /// RPC method identifier to query contributed `flutter build` targets.
  static const String getBuildTargetsMethod = 'build.getBuildTargets';

  /// RPC method identifier to query contributed `flutter assemble` targets.
  static const String getAssembleTargetsMethod = 'build.getAssembleTargets';

  /// RPC method identifier to trigger a custom `flutter build` target.
  static const String buildMethod = 'build.build';

  /// RPC method identifier to trigger a custom `flutter assemble` target.
  static const String assembleMethod = 'build.assemble';

  /// RPC parameter key for the temporary build directory.
  static const String buildDirParam = 'buildDir';

  /// RPC parameter key for the build mode.
  static const String buildModeParam = 'buildMode';

  /// RPC parameter key for the Flutter SDK root directory.
  static const String flutterRootParam = 'flutterRoot';

  /// RPC parameter key for the main entrypoint path.
  static const String mainPathParam = 'mainPath';

  /// RPC parameter key for the output directory.
  static const String outputDirParam = 'outputDir';

  /// RPC parameter key for the project root path.
  static const String projectRootParam = 'projectRoot';

  /// RPC parameter key for the map of resolved engine artifacts.
  static const String resolvedArtifactsParam = 'resolvedArtifacts';

  /// RPC parameter key for the target name.
  static const String targetNameParam = 'targetName';

  static const String _getBuildTargetsRpcMethod = 'getBuildTargets';
  static const String _getAssembleTargetsRpcMethod = 'getAssembleTargets';
  static const String _buildRpcMethod = 'build';
  static const String _assembleRpcMethod = 'assemble';

  @override
  String get namespace => serviceNamespace;

  /// Returns the custom `flutter build` targets contributed by this extension.
  List<BuildTarget> get buildTargets => const <BuildTarget>[];

  /// Returns the custom `flutter assemble` targets contributed by this extension.
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[];

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getBuildTargetsRpcMethod: _getBuildTargetsRpc,
      _getAssembleTargetsRpcMethod: _getAssembleTargetsRpc,
      _buildRpcMethod: _buildRpc,
      _assembleRpcMethod: _assembleRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getBuildTargetsRpc(Map<String, Object?> _) async {
    return buildTargets
        .map(
          (BuildTarget target) => ExtensionBuildTarget(
            artifacts: target.artifacts,
            description: target.description,
            hostArtifacts: target.hostArtifacts,
            name: target.name,
            outputDir: target.outputDir,
            targetPlatform: target.targetPlatform,
          ).toMap(),
        )
        .toList();
  }

  Future<List<Map<String, Object?>>> _getAssembleTargetsRpc(Map<String, Object?> _) async {
    return assembleTargets
        .map(
          (AssembleTarget target) => ExtensionAssembleTarget(
            dependencies: target.dependencies,
            description: target.description,
            inputs: target.inputs,
            name: target.name,
            outputs: target.outputs,
            targetPlatform: target.targetPlatform,
          ).toMap(),
        )
        .toList();
  }

  static String _requireString(Map<String, Object?> params, String key) => switch (params[key]) {
    final String value => value,
    _ => throw RpcException.invalidParams('Missing or invalid "$key" parameter.'),
  };

  static Uri _requireAbsoluteDirectoryUri(Map<String, Object?> params, String key) {
    final String raw = _requireString(params, key);
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAbsolutePath) {
      throw RpcException.invalidParams('Missing or invalid "$key" parameter.');
    }
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }

  static (String targetName, ExtensionBuildContext context) _parseBuildRequest(
    Map<String, Object?> params,
  ) {
    final String targetName = _requireString(params, targetNameParam);
    final Uri projectRootUri = _requireAbsoluteDirectoryUri(params, projectRootParam);
    final String mainPath = _requireString(params, mainPathParam);
    final String buildMode = _requireString(params, buildModeParam);
    final Uri outputDirUri = _requireAbsoluteDirectoryUri(params, outputDirParam);
    final Uri buildDirUri = _requireAbsoluteDirectoryUri(params, buildDirParam);
    final Uri flutterRootUri = _requireAbsoluteDirectoryUri(params, flutterRootParam);
    final Map<String, Object?> rawResolvedArtifacts = switch (params[resolvedArtifactsParam]) {
      final Map<String, Object?> value => value,
      _ => throw RpcException.invalidParams(
        'Missing or invalid "$resolvedArtifactsParam" parameter.',
      ),
    };

    final BuildMode mode;
    try {
      mode = BuildMode.fromCliName(buildMode);
    } on ArgumentError {
      throw RpcException.invalidParams('Missing or invalid "$buildModeParam" parameter.');
    }

    final resolvedArtifacts = <String, String>{};
    for (final MapEntry(:String key, :Object? value) in rawResolvedArtifacts.entries) {
      if (value is! String) {
        throw RpcException.invalidParams('Missing or invalid "$resolvedArtifactsParam" parameter.');
      }
      resolvedArtifacts[key] = value;
    }

    final context = ExtensionBuildContext(
      buildDir: buildDirUri,
      buildMode: mode,
      flutterRoot: flutterRootUri,
      mainPath: mainPath,
      outputDir: outputDirUri,
      projectRoot: projectRootUri,
      resolvedArtifacts: resolvedArtifacts,
    );
    return (targetName, context);
  }

  Future<Map<String, Object?>> _buildRpc(Map<String, Object?> params) async {
    final (String targetName, ExtensionBuildContext context) = _parseBuildRequest(params);
    final BuildTarget? target = buildTargets
        .where((BuildTarget t) => t.name == targetName)
        .firstOrNull;
    if (target == null) {
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'Unknown build target: $targetName',
      ).toMap();
    }
    final ExtensionBuildResult result = await target.build(context);
    return result.toMap();
  }

  Future<Map<String, Object?>> _assembleRpc(Map<String, Object?> params) async {
    final (String targetName, ExtensionBuildContext context) = _parseBuildRequest(params);
    final AssembleTarget? target = assembleTargets
        .where((AssembleTarget t) => t.name == targetName)
        .firstOrNull;
    if (target == null) {
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'Unknown assemble target: $targetName',
      ).toMap();
    }
    final ExtensionBuildResult result = await target.build(context);
    return result.toMap();
  }
}
