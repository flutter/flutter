// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';

import 'protocol_base/service.dart';

/// Abstract target for a custom `flutter build <subcommand>` target.
///
/// Extensions should extend this class to contribute top-level `flutter build`
/// subcommands via [BuildService.buildTargets].
@immutable
abstract base class BuildTarget {
  const BuildTarget({
    required this.description,
    required this.outputDir,
    this.targetPlatforms = const <String>{},
  });

  /// The user-readable name of the target (exposed as `flutter build <name>`).
  ///
  /// Must match [ExtensionBuildTarget.isValidName].
  String get name;

  /// Description of what this target builds.
  final String description;

  /// The directory pattern used by `flutter build` to determine this target's
  /// output directory, for example
  /// `'${BuiltInPlaceholders.outputDir}/custom/${BuiltInPlaceholders.targetPlatform}/${BuiltInPlaceholders.buildMode}'`.
  ///
  /// Supports [BuiltInPlaceholders.outputDir] (the project's configured build
  /// output root from `flutter config --build-dir`, defaulting to
  /// `<project>/build`), [BuiltInPlaceholders.projectDir],
  /// [BuiltInPlaceholders.buildMode], and [BuiltInPlaceholders.targetPlatform]
  /// (when [targetPlatforms] is non-empty).
  final String outputDir;

  /// Supported target platform identifiers for this build target, preserving
  /// insertion order.
  ///
  /// * When empty (`const <String>{}`), no `--target-platform` CLI option is
  ///   registered and [ExtensionBuildContext.targetPlatform] is `null`.
  /// * When containing a single platform, `targetPlatforms.single` is passed
  ///   automatically as [ExtensionBuildContext.targetPlatform] without adding a
  ///   redundant `--target-platform` CLI option.
  /// * When containing multiple platforms, `flutter build <name>` registers a
  ///   `--target-platform` CLI option defaulting to `targetPlatforms.first`.
  final Set<String> targetPlatforms;

  /// Custom boolean CLI flags registered on `flutter build <name>` and
  /// passed via [ExtensionBuildContext.buildFlags].
  List<ExtensionFlag> get flags => const <ExtensionFlag>[];

  /// Custom single-value CLI options registered on `flutter build <name>` and
  /// passed via [ExtensionBuildContext.buildOptions].
  List<ExtensionOption> get options => const <ExtensionOption>[];

  /// Compilation modes supported by this target on `flutter build <name>`
  /// (registering `--debug`, `--profile`, and `--release` flags accordingly).
  Set<BuildMode> get supportedBuildModes => const <BuildMode>{.debug, .profile, .release};

  /// Whether this target supports `--flavor` on `flutter build <name>` and
  /// `flutter run` (passing the parsed value via
  /// [ExtensionBuildContext.flavor]).
  bool get supportsFlavors => false;

  /// Whether this target supports `--analyze-size` and
  /// `--code-size-directory` on `flutter build <name>`.
  bool get supportsSizeAnalysis => false;

  /// Engine artifacts required by this build target, resolved for the active
  /// target platform and [BuildMode].
  Set<ExtensionArtifact> get artifacts => const <ExtensionArtifact>{};

  /// Host-side build tool or library artifacts required by this build target.
  Set<ExtensionHostArtifact> get hostArtifacts => const <ExtensionHostArtifact>{};

  /// Executes the build target, returning an [ExtensionBuildResult] on success
  /// or throwing a [ToolExtensionException] on failure.
  Future<ExtensionBuildResult> build(ExtensionBuildContext context);
}

/// Abstract target for a custom `flutter assemble <target>` DAG node.
///
/// Extensions should extend this class to contribute `flutter assemble` targets
/// with tracked [dependencies], [inputs], and [outputs] via [BuildService.assembleTargets].
@immutable
abstract base class AssembleTarget {
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

  /// Names of `.d` dependency files written by this target into the build directory.
  ///
  /// Extensions that declare [depfiles] can use [Depfile.format] to write `.d`
  /// files into [ExtensionAssembleContext.buildDir]. The host deletes any
  /// existing declared depfiles from [ExtensionAssembleContext.buildDir]
  /// before invoking [build].
  ///
  /// Each entry must match [ExtensionAssembleTarget.isValidDepfileName].
  /// Because all targets write depfiles directly into the shared
  /// [ExtensionAssembleContext.buildDir], depfile names must be unique across
  /// built-in Flutter tool targets and all active extensions. Prefix depfile
  /// names with the target platform or extension name (for example,
  /// `'linux_build.d'`) to avoid conflicts.
  ///
  /// Relative paths inside each depfile are resolved against the project root
  /// directory and rewritten in place with normalized paths by the host after
  /// a successful build. If a declared depfile is missing or invalid after a
  /// successful build, the host logs an error and disables incremental build
  /// caching for this target without failing the build.
  ///
  /// See also:
  ///
  /// * [Depfile], which formats and parses `.d` dependency files.
  List<String> get depfiles => const <String>[];

  /// The input [ExtensionSource]s for this target.
  List<ExtensionSource> get inputs => const <ExtensionSource>[];

  /// Output file patterns produced by this target (for example,
  /// `ExtensionSource.pattern('${BuiltInPlaceholders.outputDir}/app.bundle')`).
  List<ExtensionSource> get outputs => const <ExtensionSource>[];

  /// Executes the assemble step in the extension isolate, writing declared
  /// [outputs] and [depfiles] or throwing a [ToolExtensionException] on failure.
  Future<void> build(ExtensionAssembleContext context);
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
            flags: target.flags,
            hostArtifacts: target.hostArtifacts,
            name: target.name,
            options: target.options,
            outputDir: target.outputDir,
            supportedBuildModes: target.supportedBuildModes,
            supportsFlavors: target.supportsFlavors,
            supportsSizeAnalysis: target.supportsSizeAnalysis,
            targetPlatforms: target.targetPlatforms,
          ).toMap(),
        )
        .toList();
  }

  Future<List<Map<String, Object?>>> _getAssembleTargetsRpc(Map<String, Object?> _) async {
    return assembleTargets
        .map(
          (AssembleTarget target) => ExtensionAssembleTarget(
            dependencies: target.dependencies,
            depfiles: target.depfiles,
            description: target.description,
            inputs: target.inputs,
            name: target.name,
            outputs: target.outputs,
            targetPlatform: target.targetPlatform,
          ).toMap(),
        )
        .toList();
  }

  static (String targetName, ExtensionBuildContext context) _parseBuildRequest(
    Map<String, Object?> params,
  ) {
    final String targetName;
    final ExtensionBuildContext context;
    try {
      targetName = params.requiredField<String>(targetNameParam);
      context = ExtensionBuildContext.fromJson(params);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return (targetName, context);
  }

  static (String targetName, ExtensionAssembleContext context) _parseAssembleRequest(
    Map<String, Object?> params,
  ) {
    final String targetName;
    final ExtensionAssembleContext context;
    try {
      targetName = params.requiredField<String>(targetNameParam);
      context = ExtensionAssembleContext.fromJson(params);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return (targetName, context);
  }

  Future<Map<String, Object?>> _buildRpc(Map<String, Object?> params) async {
    final (String targetName, ExtensionBuildContext context) = _parseBuildRequest(params);
    final BuildTarget? target = buildTargets
        .where((BuildTarget t) => t.name == targetName)
        .firstOrNull;
    if (target == null) {
      throw ToolExtensionException('Unknown build target: $targetName');
    }
    final ExtensionBuildResult result = await target.build(context);
    return result.toMap();
  }

  Future<Map<String, Object?>> _assembleRpc(Map<String, Object?> params) async {
    final (String targetName, ExtensionAssembleContext context) = _parseAssembleRequest(params);
    final AssembleTarget? target = assembleTargets
        .where((AssembleTarget t) => t.name == targetName)
        .firstOrNull;
    if (target == null) {
      throw ToolExtensionException('Unknown assemble target: $targetName');
    }
    await target.build(context);
    return <String, Object?>{};
  }
}
