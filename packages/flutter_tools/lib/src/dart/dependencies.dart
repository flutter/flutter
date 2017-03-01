// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../artifacts.dart';
import '../base/process.dart';

class DartDependencySetBuilder {
  DartDependencySetBuilder(this.mainScriptPath,
                           this.projectRootPath,
                           this.packagesFilePath);

  final String mainScriptPath;
  final String projectRootPath;
  final String packagesFilePath;

  Set<String> build() {
    final String skySnapshotPath =
        Artifacts.instance.getArtifactPath(Artifact.skySnapshot);

    final List<String> args = <String>[
      skySnapshotPath,
      '--packages=$packagesFilePath',
      '--print-deps',
      mainScriptPath
    ];

    String output = runSyncAndThrowStdErrOnError(args);

    return new Set<String>.from(LineSplitter.split(output));
  }
}
