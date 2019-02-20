// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'channel.dart';

class UpgradeCommand extends FlutterCommand {
  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    try {
      await runCheckedAsync(<String>[
        'git', 'rev-parse', '@{u}'
      ], workingDirectory: Cache.flutterRoot);
    } catch (e) {
      throwToolExit('Unable to upgrade Flutter: no upstream repository configured.');
    }

    final FlutterVersion flutterVersion = FlutterVersion.instance;

    printStatus('Upgrading Flutter from ${Cache.flutterRoot}...');

    await ChannelCommand.upgradeChannel();

    int code = await runCommandAndStreamOutput(
      <String>['git', 'pull', '--ff-only'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) => matchesGitLine(line) ? null : line
    );

    if (code != 0)
      throwToolExit(null, exitCode: code);

    // Check for and download any engine and pkg/ updates.
    // We run the 'flutter' shell script re-entrantly here
    // so that it will download the updated Dart and so forth
    // if necessary.
    printStatus('');
    printStatus('Upgrading engine...');
    code = await runCommandAndStreamOutput(
      <String>[
        fs.path.join('bin', 'flutter'), '--no-color', '--no-version-check', 'precache',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true
    );

    printStatus('');
    printStatus(flutterVersion.toString());

    final String projectRoot = findProjectRoot();
    if (projectRoot != null) {
      printStatus('');
      await pubGet(context: PubContext.pubUpgrade, directory: projectRoot, upgrade: true, checkLastModified: false);
    }

    // Run a doctor check in case system requirements have changed.
    printStatus('');
    printStatus('Running flutter doctor...');
    code = await runCommandAndStreamOutput(
      <String>[
        fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );

    return null;
  }

  //  dev/benchmarks/complex_layout/lib/main.dart        |  24 +-
  static final RegExp _gitDiffRegex = RegExp(r' (\S+)\s+\|\s+\d+ [+-]+');

  //  rename {packages/flutter/doc => dev/docs}/styles.html (92%)
  //  delete mode 100644 doc/index.html
  //  create mode 100644 examples/flutter_gallery/lib/gallery/demo.dart
  static final RegExp _gitChangedRegex = RegExp(r' (rename|delete mode|create mode) .+');

  @visibleForTesting
  static bool matchesGitLine(String line) {
    return _gitDiffRegex.hasMatch(line)
      || _gitChangedRegex.hasMatch(line)
      || line == 'Fast-forward';
  }
}
