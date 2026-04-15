// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main() async {
  // This script is to be run from its own directory:
  // .agents/skills/rebuilding-flutter-tool/scripts/

  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = Directory(scriptPath).parent;

  // Go up 4 levels to find the repo root:
  // scripts/ -> rebuilding-flutter-tool/ -> skills/ -> .agents/ -> <repo_root>/
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  final snapshotFile = File('${repoRootDir.path}/bin/cache/flutter_tools.snapshot');
  final stampFile = File('${repoRootDir.path}/bin/cache/flutter_tools.stamp');
  final flutterFile = File('${repoRootDir.path}/bin/flutter');

  stdout.writeln('Cleaning cache files...');
  if (snapshotFile.existsSync()) {
    snapshotFile.deleteSync();
    stdout.writeln('Deleted ${snapshotFile.path}');
  }

  if (stampFile.existsSync()) {
    stampFile.deleteSync();
    stdout.writeln('Deleted ${stampFile.path}');
  }

  stdout.writeln('Triggering rebuild by running flutter help...');
  // Triggers the rebuild by executing a flutter command
  final ProcessResult result = await Process.run(flutterFile.path, <String>['help']);

  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }

  stdout.write(result.stdout);
  stdout.writeln('Flutter tool rebuilt successfully!');
}
