// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ this.hidden: false }) {
    argParser.addFlag(
      'upgrade',
      help: 'Ignores pubspec.lock and retrieves newer versions of packages.',
      defaultsTo: false
    );
  }

  @override
  final String name = 'update-packages';

  @override
  final String description = 'Update the packages inside the Flutter repo.';

  @override
  final bool hidden;

  Future<Null> _downloadCoverageData() async {
    Status status = logger.startProgress("Downloading lcov data for package:flutter...");
    final List<int> data = await fetchUrl(Uri.parse('https://storage.googleapis.com/flutter_infra/flutter/coverage/lcov.info'));
    final String coverageDir = path.join(Cache.flutterRoot, 'packages/flutter/coverage');
    fs.file(path.join(coverageDir, 'lcov.base.info'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data, flush: true);
    fs.file(path.join(coverageDir, 'lcov.info'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data, flush: true);
    status.stop();
  }

  @override
  Future<Null> runCommand() async {
    final Stopwatch timer = new Stopwatch()..start();
    int count = 0;
    final bool upgrade = argResults['upgrade'];

    for (Directory dir in runner.getRepoPackages()) {
      await pubGet(directory: dir.path, upgrade: upgrade, checkLastModified: false);
      count++;
    }

    await _downloadCoverageData();

    final double seconds = timer.elapsedMilliseconds / 1000.0;
    printStatus('\nRan \'pub\' $count time${count == 1 ? "" : "s"} and fetched coverage data in ${seconds.toStringAsFixed(1)}s.');
  }
}
