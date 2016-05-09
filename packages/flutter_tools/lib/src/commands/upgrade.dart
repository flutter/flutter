// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../artifacts.dart';
import '../base/process.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class UpgradeCommand extends FlutterCommand {
  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    try {
      runCheckedSync(<String>[
        'git', 'rev-parse', '@{u}'
      ], workingDirectory: ArtifactStore.flutterRoot);
    } catch (e) {
      printError('Unable to upgrade Flutter: no upstream repository configured.');
      return 1;
    }

    printStatus('Upgrading Flutter...');

    int code = await runCommandAndStreamOutput(
      <String>['git', 'pull', '--ff-only'],
      workingDirectory: ArtifactStore.flutterRoot,
      mapFunction: (String line) => matchesGitLine(line) ? null : line
    );

    if (code != 0)
      return code;

    // Check for and download any engine and pkg/ updates.
    printStatus('');
    printStatus('Upgrading engine...');
    code = await runCommandAndStreamOutput(<String>[
      'bin/flutter', '--no-color', 'precache'
    ], workingDirectory: ArtifactStore.flutterRoot);

    printStatus('');
    printStatus(FlutterVersion.getVersion(ArtifactStore.flutterRoot).toString());

    if (FileSystemEntity.isFileSync('pubspec.yaml')) {
      printStatus('');
      code = await pubGet(upgrade: true, checkLastModified: false);

      if (code != 0)
        return code;
    }

    return 0;
  }

  //  dev/benchmarks/complex_layout/lib/main.dart        |  24 +-
  static final RegExp _gitDiffRegex = new RegExp(r' (\S+)\s+\|\s+\d+ [+-]+');

  //  rename {packages/flutter/doc => dev/docs}/styles.html (92%)
  //  delete mode 100644 doc/index.html
  //  create mode 100644 examples/flutter_gallery/lib/gallery/demo.dart
  static final RegExp _gitChangedRegex = new RegExp(r' (rename|delete mode|create mode) .+');

  // Public for testing.
  static bool matchesGitLine(String line) {
    return _gitDiffRegex.hasMatch(line)
      || _gitChangedRegex.hasMatch(line)
      || line == 'Fast-forward';
  }
}
