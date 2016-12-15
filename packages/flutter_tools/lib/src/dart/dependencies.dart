// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:path/path.dart' as path;

import '../base/process.dart';
import '../toolchain.dart';

class DartDependencySetBuilder {
  DartDependencySetBuilder(this.mainScriptPath,
                           this.projectRootPath,
                           this.packagesFilePath);

  final String mainScriptPath;
  final String projectRootPath;
  final String packagesFilePath;

  Set<String> build() {
    final String skySnapshotPath =
        ToolConfiguration.instance.getHostToolPath(HostTool.SkySnapshot);

    final List<String> args = <String>[
      skySnapshotPath,
      '--packages=$packagesFilePath',
      '--print-deps',
      mainScriptPath
    ];

    String output = runSyncAndThrowStdErrOnError(args);

    final List<String> lines = LineSplitter.split(output).toList();
    final Set<String> minimalDependencies = new Set<String>();
    for (String line in lines) {
      if (!line.startsWith('package:')) {
        // We convert the uris so that they are relative to the project
        // root.
        line = path.relative(line, from: projectRootPath);
      }
      minimalDependencies.add(line);
    }
    return minimalDependencies;
  }
}
