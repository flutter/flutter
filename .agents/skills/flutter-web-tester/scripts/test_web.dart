// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main(List<String> args) async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  final feltPath = '${repoRootDir.path}/engine/src/flutter/lib/web_ui/dev/felt';
  if (!File(feltPath).existsSync()) {
    stderr.writeln('Error: felt binary not found at $feltPath');
    exit(1);
  }

  final feltArgs = <String>['test', ...args];

  stdout.writeln('Running web engine tests using felt ${feltArgs.join(' ')}...');
  final Process process = await Process.start(
    feltPath,
    feltArgs,
    workingDirectory: '${repoRootDir.path}/engine/src/flutter/lib/web_ui',
    mode: ProcessStartMode.inheritStdio,
  );
  exit(await process.exitCode);
}
