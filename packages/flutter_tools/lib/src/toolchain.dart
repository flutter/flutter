// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'base/context.dart';
import 'base/process.dart';
import 'build_configuration.dart';
import 'cache.dart';
import 'globals.dart';
import 'package_map.dart';

class SnapshotCompiler {
  SnapshotCompiler(this._path);

  final String _path;

  Future<int> createSnapshot({
    String mainPath,
    String snapshotPath,
    String depfilePath,
    String buildOutputPath
  }) {
    assert(mainPath != null);
    assert(snapshotPath != null);

    final List<String> args = <String>[
      _path,
      mainPath,
      '--packages=${PackageMap.instance.packagesPath}',
      '--snapshot=$snapshotPath'
    ];
    if (depfilePath != null)
      args.add('--depfile=$depfilePath');
    if (buildOutputPath != null)
      args.add('--build-output=$buildOutputPath');
    return runCommandAndStreamOutput(args);
  }
}

// TODO(devoncarew): This should instead take a host platform and target platform.

String _getCompilerPath(BuildConfiguration config) {
  if (config.type != BuildType.prebuilt) {
    String compilerPath = path.join(config.buildDir, 'clang_x64', 'sky_snapshot');
    if (FileSystemEntity.isFileSync(compilerPath))
      return compilerPath;
    compilerPath = path.join(config.buildDir, 'sky_snapshot');
    if (FileSystemEntity.isFileSync(compilerPath))
      return compilerPath;
    return null;
  }
  Artifact artifact = ArtifactStore.getArtifact(
    type: ArtifactType.snapshot, hostPlatform: config.hostPlatform);
  return ArtifactStore.getPath(artifact);
}

class Toolchain {
  Toolchain({ this.compiler });

  final SnapshotCompiler compiler;

  static Toolchain forConfigs(List<BuildConfiguration> configs) {
    for (BuildConfiguration config in configs) {
      String compilerPath = _getCompilerPath(config);
      if (compilerPath != null)
        return new Toolchain(compiler: new SnapshotCompiler(compilerPath));
    }
    return null;
  }
}

/// A ToolConfiguration can return the tools directory for the current host platform
/// and the engine artifact directory for a given target platform. It is configurable
/// via command-line arguments in order to support local engine builds.
class ToolConfiguration {
  /// [overrideCache] is configurable for testing.
  ToolConfiguration({ Cache overrideCache }) {
    _cache = overrideCache ?? cache;
  }

  Cache _cache;

  static ToolConfiguration get instance {
    if (context[ToolConfiguration] == null)
      context[ToolConfiguration] = new ToolConfiguration();
    return context[ToolConfiguration];
  }

  /// Override using the artifacts from the cache directory (--engine-src-path).
  String engineSrcPath;

  /// The engine mode to use (only relevent when [engineSrcPath] is set).
  bool engineRelease;

  bool get isLocalEngine => engineSrcPath != null;

  /// Return the directory that contains engine artifacts for the given targets.
  /// This directory might contain artifacts like `libsky_shell.so`.
  Directory getEngineArtifactsDirectory(TargetPlatform platform, BuildMode mode) {
    Directory dir = _getEngineArtifactsDirectory(platform, mode);
    if (dir != null)
      printTrace('Using engine artifacts dir: ${dir.path}');
    return dir;
  }

  Directory _getEngineArtifactsDirectory(TargetPlatform platform, BuildMode mode) {
    if (engineSrcPath != null) {
      List<String> buildDir = <String>[];

      switch (platform) {
        case TargetPlatform.android_arm:
        case TargetPlatform.android_x64:
        case TargetPlatform.android_x86:
          buildDir.add('android');
          break;

        // TODO(devoncarew): We will need an ios vs ios_x86 target (for ios vs. ios_sim).
        case TargetPlatform.ios:
          buildDir.add('ios');
          break;

        // These targets don't have engine artifacts.
        case TargetPlatform.darwin_x64:
        case TargetPlatform.linux_x64:
          buildDir.add('host');
          break;
      }

      buildDir.add(getModeName(mode));

      if (!engineRelease)
        buildDir.add('unopt');

      // Add a suffix for the target architecture.
      switch (platform) {
        case TargetPlatform.android_x64:
          buildDir.add('x64');
          break;
        case TargetPlatform.android_x86:
          buildDir.add('x86');
          break;
        default:
          break;
      }

      return new Directory(path.join(engineSrcPath, 'out', buildDir.join('_')));
    } else {
      String suffix = mode != BuildMode.debug ? '-${getModeName(mode)}' : '';

      // Create something like `android-arm` or `android-arm-release`.
      String dirName = getNameForTargetPlatform(platform) + suffix;
      Directory engineDir = _cache.getArtifactDirectory('engine');
      return new Directory(path.join(engineDir.path, dirName));
    }
  }
}
