// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/os.dart';
import '../base/process.dart';
import '../dart/pub.dart';
import '../dart/summary.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class UpgradeCommand extends FlutterCommand {
  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  Future<int> runCommand() async {
    try {
      runCheckedSync(<String>[
        'git', 'rev-parse', '@{u}'
      ], workingDirectory: Cache.flutterRoot);
    } catch (e) {
      printError('Unable to upgrade Flutter: no upstream repository configured.');
      return 1;
    }

    FlutterVersion version = new FlutterVersion(Cache.flutterRoot);
    if (version.channel == 'alpha') {
      // The alpha branch is deprecated. Rather than trying to pull the alpha
      // branch, we should switch upstream to master.
      printStatus('Switching to from alpha to master...');
      runSync(<String>['git', 'branch', '--set-upstream-to=origin/master']);
    }

    printStatus('Upgrading Flutter from ${Cache.flutterRoot}...');

    int code = await runCommandAndStreamOutput(
      <String>['git', 'pull', '--ff-only'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) => matchesGitLine(line) ? null : line
    );

    await buildUnlinkedForPackages(Cache.flutterRoot);

    if (code != 0)
      return code;

    // Check for and download any engine and pkg/ updates.
    // We run the 'flutter' shell script re-entrantly here
    // so that it will download the updated Dart and so forth
    // if necessary.
    printStatus('');
    printStatus('Upgrading engine...');
    code = await runCommandAndStreamOutput(
      <String>[
        'bin/flutter', '--no-color', 'precache'
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true
    );

    printStatus('');
    printStatus(FlutterVersion.getVersion(Cache.flutterRoot).toString());

    String projRoot = findProjectRoot();
    if (projRoot != null) {
      printStatus('');
      code = await pubGet(
          directory: projRoot, upgrade: true, checkLastModified: false);

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
