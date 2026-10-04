// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main() async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;

  // Go up 4 levels to find the repo root:
  // scripts/ -> rebuilding-flutter-tool/ -> skills/ -> .agents/ -> <repo_root>/
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  stdout.writeln('Cleaning cache files...');
  final snapshotFile = File('${repoRootDir.path}/bin/cache/flutter_tools.snapshot');
  final stampFile = File('${repoRootDir.path}/bin/cache/flutter_tools.stamp');
  if (snapshotFile.existsSync()) {
    snapshotFile.deleteSync();
    stdout.writeln('Deleted ${snapshotFile.path}');
  }
  if (stampFile.existsSync()) {
    stampFile.deleteSync();
    stdout.writeln('Deleted ${stampFile.path}');
  }

  // Triggers the rebuild by executing any flutter command
  stdout.writeln('Triggering rebuild by running flutter help...');
  final process = await Process.start('flutter', <String>[
    'help',
  ], mode: ProcessStartMode.inheritStdio);
  exit(await process.exitCode);
}
