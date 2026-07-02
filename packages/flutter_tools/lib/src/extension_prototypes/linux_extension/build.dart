// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';

import '../../../flutter_tools_extension.dart';

/// The build service implementation for Linux platform devices.
base class LinuxBuildService extends BuildService {
  LinuxBuildService({FileSystem? fileSystem, ProcessManager? processManager})
    : _fileSystem = fileSystem ?? const LocalFileSystem(),
      _processManager = processManager ?? const LocalProcessManager();

  final FileSystem _fileSystem;
  final ProcessManager _processManager;

  @override
  late final List<Target> targets = <Target>[
    LinuxAssembleTarget(fileSystem: _fileSystem, processManager: _processManager),
  ];

  @override
  Map<String, Object?> get nativeAssetsConfig => const <String, Object?>{};

  @override
  List<ArtifactDependency> get artifactDependencies => const <ArtifactDependency>[];
}

/// The compilation target for the Linux application.
base class LinuxAssembleTarget extends Target {
  LinuxAssembleTarget({required FileSystem fileSystem, required ProcessManager processManager})
    : _fileSystem = fileSystem,
      _processManager = processManager;

  final FileSystem _fileSystem;
  final ProcessManager _processManager;

  @override
  String get name => 'assemble_linux_app';

  @override
  List<String> get dependencies => const <String>[];

  @override
  List<String> get inputs => const <String>[];

  @override
  List<String> get outputs => const <String>[];

  @override
  Future<void> build(BuildEnvironment env) async {
    final String projectPath = _fileSystem.path.fromUri(env.projectRoot);
    final String outputPath = _fileSystem.path.fromUri(env.outputDirectory);

    // Make sure the output directory exists.
    final Directory outputDir = _fileSystem.directory(outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // 1. cmake -S <project>/linux -B <output>
    final String linuxProjectPath = _fileSystem.path.join(projectPath, 'linux');
    final cmakeConfigureCmd = <String>['cmake', '-S', linuxProjectPath, '-B', outputPath];
    final ProcessResult configureResult = await _processManager.run(cmakeConfigureCmd);
    if (configureResult.exitCode != 0) {
      throw Exception(
        'CMake configuration failed with exit code ${configureResult.exitCode}.\n'
        'Stdout: ${configureResult.stdout}\n'
        'Stderr: ${configureResult.stderr}',
      );
    }

    // 2. cmake --build <output>
    final cmakeBuildCmd = <String>['cmake', '--build', outputPath];
    final ProcessResult buildResult = await _processManager.run(cmakeBuildCmd);
    if (buildResult.exitCode != 0) {
      throw Exception(
        'CMake build failed with exit code ${buildResult.exitCode}.\n'
        'Stdout: ${buildResult.stdout}\n'
        'Stderr: ${buildResult.stderr}',
      );
    }
  }
}

/// The artifact service implementation for Linux platform devices.
base class LinuxArtifactService extends ArtifactService {
  @override
  Set<ArtifactDependency> get artifacts => const <ArtifactDependency>{};

  @override
  Future<void> downloadArtifacts(
    Set<ArtifactDependency> artifacts, {
    required String buildMode,
    required String hostPlatform,
    required String targetPlatform,
  }) async {
    // No-op for this prototype since we have no custom external dependencies.
  }
}
