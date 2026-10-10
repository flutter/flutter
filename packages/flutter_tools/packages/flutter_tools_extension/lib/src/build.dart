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
  /// Keys correspond to [Artifact.name] or [HostArtifact.name] values.
  final Map<String, String> resolvedArtifacts;
}

/// Abstract target that encapsulates both metadata and build logic.
///
/// Extensions should extend this class to define custom build targets.
@immutable
abstract class ExtensionTarget extends Target {
  const ExtensionTarget({
    required this.description,
    required this.targetPlatform,
    this.isTopLevel = true,
    this.outputDir = kBuildDirPlaceholder,
  });

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
  @override
  final String outputDir;

  /// Performs the actual compilation/build steps in the extension process/isolate.
  ///
  /// Access resolved artifact paths from [ExtensionBuildContext.resolvedArtifacts] using
  /// [Artifact.name] or [HostArtifact.name] as keys.
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
            dependencies: target.dependencies.map((Target d) => d.name).toList(),
            inputs: target.inputs,
            isTopLevel: target.isTopLevel,
            outputDir: target.outputDir,
            outputs: target.outputs,
          ).toMap(),
        )
        .toList();
  }

  Future<Map<String, Object?>> _buildRpc(Map<String, Object?> params) async {
    final String targetName = switch (params[targetNameParam]) {
      final String value => value,
      _ => throw RpcException.invalidParams('Missing or invalid "$targetNameParam" parameter.'),
    };
    final String projectRoot = switch (params[projectRootParam]) {
      final String value => value,
      _ => throw RpcException.invalidParams('Missing or invalid "$projectRootParam" parameter.'),
    };
    final String mainPath = switch (params[mainPathParam]) {
      final String value => value,
      _ => throw RpcException.invalidParams('Missing or invalid "$mainPathParam" parameter.'),
    };
    final String buildMode = switch (params[buildModeParam]) {
      final String value => value,
      _ => throw RpcException.invalidParams('Missing or invalid "$buildModeParam" parameter.'),
    };
    final String outputDir = switch (params[outputDirParam]) {
      final String value => value,
      _ => throw RpcException.invalidParams('Missing or invalid "$outputDirParam" parameter.'),
    };
    final String buildDir = switch (params[buildDirParam]) {
      final String value => value,
      _ => throw RpcException.invalidParams('Missing or invalid "$buildDirParam" parameter.'),
    };
    final Map<Object?, Object?> rawResolvedArtifacts = switch (params[resolvedArtifactsParam]) {
      final Map<Object?, Object?> value => value,
      _ => throw RpcException.invalidParams(
        'Missing or invalid "$resolvedArtifactsParam" parameter.',
      ),
    };

    final Uri? projectRootUri = Uri.tryParse(projectRoot);
    if (projectRootUri == null || !projectRootUri.hasAbsolutePath) {
      throw RpcException.invalidParams('Missing or invalid "$projectRootParam" parameter.');
    }

    final Uri? outputDirUri = Uri.tryParse(outputDir);
    if (outputDirUri == null || !outputDirUri.hasAbsolutePath) {
      throw RpcException.invalidParams('Missing or invalid "$outputDirParam" parameter.');
    }

    final Uri? buildDirUri = Uri.tryParse(buildDir);
    if (buildDirUri == null || !buildDirUri.hasAbsolutePath) {
      throw RpcException.invalidParams('Missing or invalid "$buildDirParam" parameter.');
    }

    final BuildMode mode;
    try {
      mode = BuildMode.fromCliName(buildMode);
    } on ArgumentError {
      throw RpcException.invalidParams('Missing or invalid "$buildModeParam" parameter.');
    }

    final resolvedArtifacts = <String, String>{};
    for (final MapEntry<Object?, Object?>(:Object? key, :Object? value)
        in rawResolvedArtifacts.entries) {
      if (key is! String || value is! String) {
        throw RpcException.invalidParams('Missing or invalid "$resolvedArtifactsParam" parameter.');
      }
      resolvedArtifacts[key] = value;
    }

    ExtensionTarget? target;
    for (final ExtensionTarget candidate in targets) {
      if (candidate.name == targetName) {
        target = candidate;
        break;
      }
    }
    if (target == null) {
      return ExtensionBuildResult.failure(message: 'Unknown build target: $targetName').toMap();
    }

    try {
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
    } on Object catch (e, stack) {
      return ExtensionBuildResult.failure(message: '$e\n$stack').toMap();
    }
  }
}
