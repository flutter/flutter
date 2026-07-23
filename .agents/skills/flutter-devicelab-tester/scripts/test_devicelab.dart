// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

void main(List<String> args) async {
  final String scriptPath = Platform.script.toFilePath();
  final Directory scriptDir = File(scriptPath).parent;
  final Directory repoRootDir = scriptDir.parent.parent.parent.parent;

  final testRunnerPath = '${repoRootDir.path}/dev/devicelab/bin/test_runner.dart';
  if (!File(testRunnerPath).existsSync()) {
    stderr.writeln('Error: test_runner.dart not found at $testRunnerPath');
    exit(1);
  }

  final runnerArgs = <String>['test', ...args];

  stdout.writeln('Running devicelab task using dart ${runnerArgs.join(' ')}...');
  final Process process = await Process.start(
    'dart',
    runnerArgs,
    workingDirectory: '${repoRootDir.path}/dev/devicelab',
    mode: ProcessStartMode.inheritStdio,
  );
  exit(await process.exitCode);
}
