// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'build_configuration.dart';
import 'process.dart';

class Compiler {
  Compiler(this._compilerPath);

  String _compilerPath;

  Future<int> compile({
    String mainPath,
    String snapshotPath
  }) {
    return runCommandAndStreamOutput([
      _compilerPath,
      mainPath,
      '--package-root=${ArtifactStore.packageRoot}',
      '--snapshot=$snapshotPath'
    ]);
  }
}

class Toolchain {
  Toolchain({ this.compiler });

  final Compiler compiler;

  static Future<Toolchain> forConfigs(List<BuildConfiguration> configs) async {
    // TODO(abarth): Add a notion of "host platform" to the build configs.
    BuildConfiguration config = configs.first;
    String compilerPath = config.type == BuildType.prebuilt ?
        await ArtifactStore.getPath(Artifact.flutterCompiler) :
        path.join(config.buildDir, 'clang_x64', 'sky_snapshot');

    return new Toolchain(compiler: new Compiler(compilerPath));
  }
}
