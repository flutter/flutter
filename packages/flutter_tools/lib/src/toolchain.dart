// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'base/process.dart';
import 'build_configuration.dart';
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
    final List<String> args = [
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

  static Future<Toolchain> forConfigs(List<BuildConfiguration> configs) async {
    for (BuildConfiguration config in configs) {
      String compilerPath = _getCompilerPath(config);
      if (compilerPath != null)
        return new Toolchain(compiler: new SnapshotCompiler(compilerPath));
    }
    return null;
  }
}
