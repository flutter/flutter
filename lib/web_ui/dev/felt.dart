// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';

import 'build.dart';
import 'licenses.dart';
import 'test_runner.dart';

CommandRunner runner = CommandRunner<bool>(
  'felt',
  'Command-line utility for building and testing Flutter web engine.',
)
  ..addCommand(LicensesCommand())
  ..addCommand(TestsCommand())
  ..addCommand(BuildCommand());

void main(List<String> args) async {
  if (args.isEmpty) {
    // The felt tool was invoked with no arguments. Print usage.
    runner.printUsage();
    io.exit(64); // Exit code 64 indicates a usage error.
  }

  try {
    final bool result = await runner.run(args);
    if (result == false) {
      print('Sub-command returned false: `${args.join(' ')}`');
      io.exit(1);
    }
  } on UsageException catch (e) {
    print(e);
    io.exit(64); // Exit code 64 indicates a usage error.
  } catch (e) {
    rethrow;
  }

  // Sometimes the Dart VM refuses to quit.
  io.exit(io.exitCode);
}
