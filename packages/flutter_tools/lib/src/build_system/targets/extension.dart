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
  List<Target> get dependencies => buildTarget.dependencies.map(_dependencyResolver).toList();

  @override
  List<Source> get inputs => buildTarget.inputs;

  @override
  List<Source> get outputs => buildTarget.outputs;

  @override
  String get outputDir => buildTarget.outputDir;

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

    TargetPlatform? targetPlatform;
    if (buildTarget.targetPlatform.isNotEmpty) {
      try {
        targetPlatform = TargetPlatform.fromName(buildTarget.targetPlatform);
      } on Exception {
        throwToolExit(
          'Invalid target platform "${buildTarget.targetPlatform}" for extension build target "${buildTarget.name}".',
        );
      }
    }

    final resolver = ArtifactResolver(
      artifacts: artifacts,
      buildMode: mode,
      targetPlatform: targetPlatform,
    );
    for (final Source input in buildTarget.inputs) {
      input.accept(resolver);
    }

    final ExtensionBuildResult result = await _buildManager.build(
      buildDir: buildDir.uri,
      buildMode: mode,
      mainPath: mainPath,
      outputDir: outputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolver.resolvedArtifacts,
      targetName: buildTarget.name,
    );

    if (!result.success) {
      throwToolExit(result.errorMessage ?? 'Extension build target ${buildTarget.name} failed.');
    }
  }
}

class ArtifactResolver implements core.SourceVisitor {
  ArtifactResolver({
    required this.artifacts,
    required this.buildMode,
    required this.targetPlatform,
  });

  final Artifacts artifacts;
  final BuildMode buildMode;
  final TargetPlatform? targetPlatform;

  final resolvedArtifacts = <String, String>{};

  @override
  void visitPattern(String pattern, bool optional) {}

  @override
  void visitArtifact(core.Artifact artifact, String? platformName, BuildMode? mode) {
    final Artifact hostArtifact = Artifact.values.firstWhere(
      (Artifact e) => e.name == artifact.name,
      orElse: () => throw ArgumentError.value(artifact.name, 'artifact', 'Unknown artifact name.'),
    );
    TargetPlatform? platform;
    if (platformName != null) {
      try {
        platform = TargetPlatform.fromName(platformName);
      } on Exception {
        throwToolExit('Invalid platform name "$platformName" for artifact "${artifact.name}".');
      }
    }

    final String path = artifacts.getArtifactPath(
      hostArtifact,
      platform: platform ?? targetPlatform,
      mode: mode ?? buildMode,
    );
    resolvedArtifacts[artifact.name] = path;
  }

  @override
  void visitHostArtifact(core.HostArtifact artifact) {
    final HostArtifact hostArtifact = HostArtifact.values.firstWhere(
      (HostArtifact e) => e.name == artifact.name,
      orElse: () =>
          throw ArgumentError.value(artifact.name, 'artifact', 'Unknown host artifact name.'),
    );
    final String path = artifacts.getHostArtifact(hostArtifact).path;
    resolvedArtifacts[artifact.name] = path;
  }
}
