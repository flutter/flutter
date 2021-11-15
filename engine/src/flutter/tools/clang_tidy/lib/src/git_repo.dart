// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Directory, File;

import 'package:path/path.dart' as path;
import 'package:process_runner/process_runner.dart';

/// Utility methods for working with a git repo.
class GitRepo {
  /// The git repository rooted at `root`.
  GitRepo(this.root);

  /// The root of the git repo.
  final io.Directory root;

  List<io.File>? _changedFiles;

  /// Returns a list of all non-deleted files which differ from the nearest
  /// merge-base with `main`. If it can't find a fork point, uses the default
  /// merge-base.
  ///
  /// This is only computed once and cached. Subsequent invocations of the
  /// getter will return the same result.
  Future<List<io.File>> get changedFiles async =>
    _changedFiles ??= await _getChangedFiles();

  Future<List<io.File>> _getChangedFiles() async {
    final ProcessRunner processRunner = ProcessRunner(
      defaultWorkingDirectory: root,
    );
    final ProcessRunnerResult fetchResult = await processRunner.runProcess(
      <String>['git', 'fetch', 'upstream', 'main'],
      failOk: true,
    );
    if (fetchResult.exitCode != 0) {
      await processRunner.runProcess(<String>[
        'git',
        'fetch',
        'origin',
        'main',
      ]);
    }
    final Set<String> result = <String>{};
    ProcessRunnerResult mergeBaseResult = await processRunner.runProcess(
      <String>['git', 'merge-base', '--fork-point', 'FETCH_HEAD', 'HEAD'],
      failOk: true,
    );
    if (mergeBaseResult.exitCode != 0) {
      mergeBaseResult = await processRunner.runProcess(<String>[
        'git',
        'merge-base',
        'FETCH_HEAD',
        'HEAD',
      ], failOk: false);
    }
    final String mergeBase = mergeBaseResult.stdout.trim();
    final ProcessRunnerResult masterResult = await processRunner
        .runProcess(<String>[
      'git',
      'diff',
      '--name-only',
      '--diff-filter=ACMRT',
      mergeBase,
    ]);
    result.addAll(masterResult.stdout.split('\n').where(
      (String str) => str.isNotEmpty,
    ));
    return result.map<io.File>(
      (String filePath) => io.File(path.join(root.path, filePath)),
    ).toList();
  }
}
