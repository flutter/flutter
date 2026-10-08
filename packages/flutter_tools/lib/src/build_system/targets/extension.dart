// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' as core;
import 'package:flutter_tools_core/flutter_tools_core.dart'
    show ExtensionBuildResult, ExtensionBuildTarget;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../experimental/extension_build_manager.dart';
import '../build_system.dart';

/// A build target that delegates to a tool extension.
class ExtensionAssembleTarget extends Target {
  ExtensionAssembleTarget({
    required this._buildManager,
    required this.buildTarget,
    required this._dependencyResolver,
  });

  /// The extension-defined build target.
  final ExtensionBuildTarget buildTarget;

  final ExtensionBuildManager _buildManager;
  final Target Function(String) _dependencyResolver;

  @override
  String get name => buildTarget.name;

  @override
  late final List<Target> dependencies = buildTarget.dependencies.map(_dependencyResolver).toList();

  @override
  late final List<Source> inputs = _convertSources(buildTarget.inputs);

  @override
  late final List<Source> outputs = _convertSources(buildTarget.outputs);

  @override
  String get outputDir => buildTarget.outputDir;

  static List<Source> _convertSources(List<core.Source> sources) {
    final converter = _SourceConverter();
    for (final source in sources) {
      source.accept(converter);
    }
    return converter.sources;
  }

  @override
  Future<void> build(Environment environment) async {
    final Environment(
      :Artifacts artifacts,
      :Directory buildDir,
      :Map<String, String> defines,
      :FileSystem fileSystem,
      :Directory outputDir,
      :Directory projectDir,
    ) = getResolvedEnvironment(
      environment,
    );
    final String mainPath = defines[kTargetFile] ?? fileSystem.path.join('lib', 'main.dart');
    final String? buildMode = defines[kBuildMode];

    if (buildMode == null) {
      throwToolExit('BuildMode define is required for extension build target ${buildTarget.name}');
    }
    final mode = BuildMode.fromCliName(buildMode);

    final Map<String, String> resolvedArtifacts = ArtifactResolver.resolveInputs(
      artifacts: artifacts,
      buildMode: mode,
      target: buildTarget,
    );

    final ExtensionBuildResult result = await _buildManager.build(
      buildDir: buildDir.uri,
      buildMode: mode,
      mainPath: mainPath,
      outputDir: outputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolvedArtifacts,
      targetName: buildTarget.name,
    );

    if (!result.success) {
      throwToolExit(result.errorMessage ?? 'Extension build target ${buildTarget.name} failed.');
    }
  }
}

class _SourceConverter implements core.SourceVisitor {
  final sources = <Source>[];

  @override
  void visitPattern(String pattern, bool optional) {
    sources.add(Source.pattern(pattern, optional: optional));
  }

  @override
  void visitArtifact(core.Artifact artifact, String? platformName, BuildMode? mode) {
    final Artifact hostArtifact = _resolveArtifact(artifact);
    final TargetPlatform? platform = _resolveArtifactPlatform(platformName, artifact);
    sources.add(Source.artifact(hostArtifact, platform: platform, mode: mode));
  }

  @override
  void visitHostArtifact(core.HostArtifact artifact) {
    final HostArtifact hostArtifact = _resolveHostArtifact(artifact);
    sources.add(Source.hostArtifact(hostArtifact));
  }
}

class ArtifactResolver implements core.SourceVisitor {
  ArtifactResolver({
    required this.artifacts,
    required this.buildMode,
    required this.targetPlatform,
  });

  /// Resolves all artifact inputs declared on [target] using [artifacts] and [buildMode].
  ///
  /// Throws a [ToolExit] if [ExtensionBuildTarget.targetPlatform] or any artifact platform
  /// name is invalid.
  static Map<String, String> resolveInputs({
    required Artifacts artifacts,
    required BuildMode buildMode,
    required ExtensionBuildTarget target,
  }) {
    TargetPlatform? targetPlatform;
    if (target.targetPlatform.isNotEmpty) {
      try {
        targetPlatform = TargetPlatform.fromName(target.targetPlatform);
      } on Exception {
        throwToolExit(
          'Invalid target platform "${target.targetPlatform}" for extension build target "${target.name}".',
        );
      }
    }
    final resolver = ArtifactResolver(
      artifacts: artifacts,
      buildMode: buildMode,
      targetPlatform: targetPlatform,
    );
    for (final core.Source input in target.inputs) {
      input.accept(resolver);
    }
    return resolver.resolvedArtifacts;
  }

  final Artifacts artifacts;
  final BuildMode buildMode;
  final TargetPlatform? targetPlatform;

  final resolvedArtifacts = <String, String>{};

  @override
  void visitPattern(String pattern, bool optional) {}

  @override
  void visitArtifact(core.Artifact artifact, String? platformName, BuildMode? mode) {
    final Artifact hostArtifact = _resolveArtifact(artifact);
    final TargetPlatform? platform = _resolveArtifactPlatform(platformName, artifact);
    final String path = artifacts.getArtifactPath(
      hostArtifact,
      platform: platform ?? targetPlatform,
      mode: mode ?? buildMode,
    );
    resolvedArtifacts[artifact.name] = path;
  }

  @override
  void visitHostArtifact(core.HostArtifact artifact) {
    final HostArtifact hostArtifact = _resolveHostArtifact(artifact);
    final String path = artifacts.getHostArtifact(hostArtifact).path;
    resolvedArtifacts[artifact.name] = path;
  }
}

Artifact _resolveArtifact(core.Artifact artifact) {
  return Artifact.values.firstWhere(
    (Artifact e) => e.name == artifact.name,
    orElse: () => throw ArgumentError.value(artifact.name, 'artifact', 'Unknown artifact name.'),
  );
}

TargetPlatform? _resolveArtifactPlatform(String? platformName, core.Artifact artifact) {
  if (platformName == null) {
    return null;
  }
  try {
    return TargetPlatform.fromName(platformName);
  } on Exception {
    throwToolExit('Invalid platform name "$platformName" for artifact "${artifact.name}".');
  }
}

HostArtifact _resolveHostArtifact(core.HostArtifact artifact) {
  return HostArtifact.values.firstWhere(
    (HostArtifact e) => e.name == artifact.name,
    orElse: () =>
        throw ArgumentError.value(artifact.name, 'artifact', 'Unknown host artifact name.'),
  );
}
