// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Rolls the dev channel.
// Only tested on Linux.
//
// See: https://github.com/flutter/flutter/wiki/Release-process

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:flutter_conductor/roll_dev.dart';
import 'package:flutter_conductor/stdio.dart';

void main(List<String> args) {
  final CommandRunner<void> runner = CommandRunner<void>(
    'conductor',
    'A tool for coordinating Flutter releases.',
    usageLineLength: 80,
  );
  addCommands(runner);
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );

  if (!assertsEnabled()) {
    stdio.printError('The conductor tool must be run with --enable-asserts.');
    io.exit(1);
  }

  //ArgResults argResults;
  //try {
  //  argResults = parseArguments(runner.argParser, args);
  //} on ArgParserException catch (error) {
  //  stdio.printError(error.message);
  //  stdio.printError(runner.argParser.usage);
  //  io.exit(1);
  //}

  try {
    runner.run(args);
    //run(
    //  usage: argParser.usage,
    //  argResults: argResults,
    //  git: const Git(),
    //  stdio: stdio,
    //  platform: const LocalPlatform(),
    //  fileSystem: const LocalFileSystem(),
    //);
  } on Exception catch (e) {
    stdio.printError(e.toString());
    io.exit(1);
  }
}

void addCommands(CommandRunner<void> runner) {
  <Command<void>>[
    RollDev(),
  ].forEach(runner.addCommand);
}

bool assertsEnabled() {
  // Verify asserts enabled
  bool assertsEnabled = false;

  assert(() {
    assertsEnabled = true;
    return true;
  }());
  return assertsEnabled;
}
