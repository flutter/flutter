// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Rolls the dev channel.
// Only tested on Linux.
//
// See: https://github.com/flutter/flutter/wiki/Release-process

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

import 'package:flutter_conductor/arguments.dart';
import 'package:flutter_conductor/git.dart';
import 'package:flutter_conductor/main.dart';
import 'package:flutter_conductor/stdio.dart';

void main(List<String> args) {
  final ArgParser argParser = ArgParser(allowTrailingOptions: false);
  // TODO(fujino): only use VerboseStdio if --v flag provided
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );

  // Verify asserts enabled
  bool assertsEnabled = false;

  assert(() {
    assertsEnabled = true;
    return true;
  }());

  if (!assertsEnabled) {
    stdio.printError('The conductor tool must be run with --enable-asserts.');
    io.exit(1);
  }

  ArgResults argResults;
  try {
    argResults = parseArguments(argParser, args);
  } on ArgParserException catch (error) {
    stdio.printError(error.message);
    stdio.printError(argParser.usage);
    io.exit(1);
  }

  try {
    run(
      usage: argParser.usage,
      argResults: argResults,
      git: const Git(),
      stdio: stdio,
      platform: const LocalPlatform(),
      fileSystem: const LocalFileSystem(),
    );
  } on Exception catch (e) {
    stdio.printError(e.toString());
    io.exit(1);
  }
}
