// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/process.dart';

class DartDependencySetBuilder {

  factory DartDependencySetBuilder(
      String mainScriptPath, String projectRootPath, String packagesFilePath) {
    if (platform.isWindows)
      return new _GenSnapshotDartDependencySetBuilder(mainScriptPath, projectRootPath, packagesFilePath);
    return new DartDependencySetBuilder._(mainScriptPath, projectRootPath, packagesFilePath);
  }

  DartDependencySetBuilder._(this.mainScriptPath, this.projectRootPath, this.packagesFilePath);

  final String mainScriptPath;
  final String projectRootPath;
  final String packagesFilePath;

  /// Returns a set of canonicalize paths.
  ///
  /// The paths have been canonicalize with `fs.path.canonicalize`.
  Set<String> build() {
    final String skySnapshotPath =
        Artifacts.instance.getArtifactPath(Artifact.skySnapshot);

    final List<String> args = <String>[
      skySnapshotPath,
      '--packages=$packagesFilePath',
      '--print-deps',
      mainScriptPath
    ];

    final String output = runSyncAndThrowStdErrOnError(args);

    return new Set<String>.from(LineSplitter.split(output).map(
        (String path) => fs.path.canonicalize(path))
    );
  }
}

/// A [DartDependencySetBuilder] that is backed by gen_snapshot.
class _GenSnapshotDartDependencySetBuilder implements DartDependencySetBuilder {
  _GenSnapshotDartDependencySetBuilder(this.mainScriptPath,
                                       this.projectRootPath,
                                       this.packagesFilePath);

  @override
  final String mainScriptPath;
  @override
  final String projectRootPath;
  @override
  final String packagesFilePath;

  @override
  Set<String> build() {
    final String snapshotterPath =
        Artifacts.instance.getArtifactPath(Artifact.genSnapshot);
    final String vmSnapshotData =
        Artifacts.instance.getArtifactPath(Artifact.vmSnapshotData);
    final String isolateSnapshotData =
        Artifacts.instance.getArtifactPath(Artifact.isolateSnapshotData);
    assert(fs.path.isAbsolute(this.projectRootPath));

    final List<String> args = <String>[
      snapshotterPath,
      '--snapshot_kind=script',
      '--dependencies-only',
      '--vm_snapshot_data=$vmSnapshotData',
      '--isolate_snapshot_data=$isolateSnapshotData',
      '--packages=$packagesFilePath',
      '--print-dependencies',
      '--script_snapshot=snapshot_blob.bin',
      mainScriptPath
    ];

    final String output = runSyncAndThrowStdErrOnError(args);

    return new Set<String>.from(LineSplitter.split(output).map(
            (String path) => fs.path.canonicalize(path))
    );
  }
}
