// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Runs `dart test -p chrome` in the root of the cross_file package.
//
// Called from the custom-tests CI action.
//
// usage: dart run tool/run_tests.dart
// (needs a `chrome` executable in $PATH, or a tweak to dart_test.yaml)
import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final Directory workingDir =
      Directory(p.dirname(Platform.script.path)).parent;

  final int status = await _runProcess(
    'dart',
    <String>[
      'test',
      '-p',
      'chrome',
    ],
    workingDirectory: workingDir.path,
  );

  exit(status);
}

Future<Process> _streamOutput(Future<Process> processFuture) async {
  final Process process = await processFuture;
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  return process;
}

Future<int> _runProcess(
  String command,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final Process process = await _streamOutput(Process.start(
    command,
    arguments,
    workingDirectory: workingDirectory,
  ));
  return process.exitCode;
}
