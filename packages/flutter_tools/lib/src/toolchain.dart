// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'build_configuration.dart';
import 'base/process.dart';

class Compiler {
  Compiler(this._path);

  String _path;

  Future<int> compile({
    String mainPath,
    String snapshotPath
  }) {
    return runCommandAndStreamOutput([
      _path,
      mainPath,
      '--package-root=${ArtifactStore.packageRoot}',
      '--snapshot=$snapshotPath'
    ]);
  }
}

Future<String> _getCompilerPath(BuildConfiguration config) async {
  if (config.type != BuildType.prebuilt) {
    String compilerPath = path.join(config.buildDir, 'clang_x64', 'sky_snapshot');
    if (FileSystemEntity.isFileSync(compilerPath))
      return compilerPath;
    return null;
  }
  Artifact artifact = ArtifactStore.getArtifact(
    type: ArtifactType.snapshot, hostPlatform: config.hostPlatform);
  return await ArtifactStore.getPath(artifact);
}

class Toolchain {
  Toolchain({ this.compiler });

  final Compiler compiler;

  static Future<Toolchain> forConfigs(List<BuildConfiguration> configs) async {
    for (BuildConfiguration config in configs) {
      String compilerPath = await _getCompilerPath(config);
      if (compilerPath != null)
        return new Toolchain(compiler: new Compiler(compilerPath));
    }
    return null;
  }
}
