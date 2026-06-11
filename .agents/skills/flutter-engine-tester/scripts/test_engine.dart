// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main(List<String> args) async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  if (args.isEmpty) {
    stderr.writeln('Error: No test target specified. Example: //flutter/fml/...');
    exit(1);
  }

  final etPath = '${repoRootDir.path}/engine/src/flutter/bin/et';
  if (!File(etPath).existsSync()) {
    stderr.writeln('Error: et binary not found at $etPath');
    exit(1);
  }

  stdout.writeln('Running engine tests using et test ${args.join(' ')}...');
  final Process process = await Process.start(
    etPath,
    <String>['test', ...args],
    workingDirectory: '${repoRootDir.path}/engine/src/flutter',
    mode: ProcessStartMode.inheritStdio,
  );
  exit(await process.exitCode);
}
