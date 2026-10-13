// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';

import 'protocol_base/service.dart';

/// Context passed to the extension target's [ExtensionTarget.build] method.
@immutable
class ExtensionBuildContext {
  const ExtensionBuildContext({
    required this.buildDir,
    required this.buildMode,
    required this.mainPath,
    required this.outputDir,
    required this.projectRoot,
    required this.resolvedArtifacts,
  });

  /// The directory used for temporary build artifacts.
  final Uri buildDir;

  /// The compilation mode for the build.
  final BuildMode buildMode;

  /// The path to the main entrypoint file (typically `lib/main.dart`).
  final String mainPath;

  /// The directory where final build outputs should be placed.
  final Uri outputDir;

  /// The absolute URI to the root directory of the Flutter project being built.
  final Uri projectRoot;

  /// A map of resolved engine artifact names to their absolute paths on the host.
  ///
  /// Keys correspond to [ExtensionArtifact.name] or [ExtensionHostArtifact.name] values.
  final Map<String, String> resolvedArtifacts;
}

/// Abstract target that encapsulates both metadata and build logic.
///
/// Extensions should extend this class to define custom build targets.
@immutable
abstract class ExtensionTarget {
  const ExtensionTarget({
    required this.description,
    required this.targetPlatform,
    this.isTopLevel = true,
    this.outputDir = kBuildDirPlaceholder,
  });

  /// The user-readable name of the target.
  String get name;

  /// Description of what this target builds.
  final String description;

  /// The target platform string (e.g. `'linux-x64'`, `'android-arm64'`).
  final String targetPlatform;

  /// Whether this target is a top-level target invokable through `flutter build`.
  ///
  /// Non-top-level targets are typically used as dependencies for other targets
  /// and are not directly exposed to the user.
  final bool isTopLevel;

  /// The output directory pattern for this target.
  ///
  /// Can include placeholders like `{PROJECT_DIR}` or `{BUILD_MODE}` which
  /// will be resolved by the host.
  final String outputDir;

  /// The names of other targets that this target depends on.
  List<String> get dependencies => const <String>[];

  /// The input [ExtensionSource]s for this target.
  List<ExtensionSource> get inputs => const <ExtensionSource>[];

  /// The output [ExtensionSource]s produced by this target.
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
/// Automatically routes build RPC calls to the registered [targets].
abstract base class BuildService extends ToolExtensionService {
  /// Service namespace identifier for custom builds.
  static const String serviceNamespace = 'build';

  /// RPC method identifier to query contributed build targets.
  static const String getBuildTargetsMethod = 'build.getBuildTargets';

  /// RPC method identifier to trigger a custom build.
  static const String buildMethod = 'build.build';

  /// RPC parameter key for the temporary build directory.
  static const String buildDirParam = 'buildDir';

  /// RPC parameter key for the build mode.
  static const String buildModeParam = 'buildMode';

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
  static const String _buildRpcMethod = 'build';

  @override
  String get namespace => serviceNamespace;

  /// Returns the custom build targets contributed by this extension.
  List<ExtensionTarget> get targets;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getBuildTargetsRpcMethod: _getBuildTargetsRpc,
      _buildRpcMethod: _buildRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getBuildTargetsRpc(Map<String, Object?> _) async {
    return targets
        .map(
          (ExtensionTarget target) => ExtensionBuildTarget(
            description: target.description,
            name: target.name,
            targetPlatform: target.targetPlatform,
            dependencies: target.dependencies,
            inputs: target.inputs,
            isTopLevel: target.isTopLevel,
            outputDir: target.outputDir,
            outputs: target.outputs,
          ).toMap(),
        )
        .toList();
  }

  static String _requireString(Map<String, Object?> params, String key) => switch (params[key]) {
    final String value => value,
    _ => throw RpcException.invalidParams('Missing or invalid "$key" parameter.'),
  };

  static Uri _requireAbsoluteUri(Map<String, Object?> params, String key) {
    final String raw = _requireString(params, key);
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAbsolutePath) {
      throw RpcException.invalidParams('Missing or invalid "$key" parameter.');
    }
    return uri;
  }

  Future<Map<String, Object?>> _buildRpc(Map<String, Object?> params) async {
    final String targetName = _requireString(params, targetNameParam);
    final Uri projectRootUri = _requireAbsoluteUri(params, projectRootParam);
    final String mainPath = _requireString(params, mainPathParam);
    final String buildMode = _requireString(params, buildModeParam);
    final Uri outputDirUri = _requireAbsoluteUri(params, outputDirParam);
    final Uri buildDirUri = _requireAbsoluteUri(params, buildDirParam);
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

    final ExtensionTarget? target = targets
        .where((ExtensionTarget t) => t.name == targetName)
        .firstOrNull;
    if (target == null) {
      return ExtensionBuildResult(
        success: false,
        errorMessage: 'Unknown build target: $targetName',
      ).toMap();
    }

    final context = ExtensionBuildContext(
      buildDir: buildDirUri,
      buildMode: mode,
      mainPath: mainPath,
      outputDir: outputDirUri,
      projectRoot: projectRootUri,
      resolvedArtifacts: resolvedArtifacts,
    );
    final ExtensionBuildResult result = await target.build(context);
    return result.toMap();
  }
}
