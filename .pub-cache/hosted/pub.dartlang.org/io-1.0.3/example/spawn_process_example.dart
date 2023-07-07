// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:io/io.dart';

/// Runs a few subcommands in the `dart` command.
Future<void> main() async {
  final manager = ProcessManager();

  // Print `dart` tool version to stdout.
  print('** Running `dart --version`');
  var spawn = await manager.spawn('dart', ['--version']);
  await spawn.exitCode;

  // Check formatting and print the result to stdout.
  print('** Running `dart format --output=none .`');
  spawn = await manager.spawn('dart', ['format', '--output=none', '.']);
  await spawn.exitCode;

  // Check if a package is ready for publishing.
  // Upon hitting a blocking stdin state, you may directly
  // output to the processes's stdin via your own, similar to how a bash or
  // shell script would spawn a process.
  print('** Running pub publish');
  spawn = await manager.spawn('dart', ['pub', 'publish', '--dry-run']);
  await spawn.exitCode;

  // Closes stdin for the entire program.
  await sharedStdIn.terminate();
}
