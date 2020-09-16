// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Rolls the dev channel.
// Only tested on Linux.
//
// See: https://github.com/flutter/flutter/wiki/Release-process

import 'dart:io';

import 'package:args/args.dart';

import 'package:flutter_conductor/arguments.dart';
import 'package:flutter_conductor/git.dart';
import 'package:flutter_conductor/main.dart';

void main(List<String> args) {
  bool assertsEnabled = false;
  assert(() { assertsEnabled = true; return true; }());
  if (!assertsEnabled) {
    print('The conductor tool must be run with --enable-asserts.');
    exit(1);
  }

  final ArgParser argParser = ArgParser(allowTrailingOptions: false);

  ArgResults argResults;
  try {
    argResults = parseArguments(argParser, args);
  } on ArgParserException catch (error) {
    print(error.message);
    print(argParser.usage);
    exit(1);
  }

  try {
    run(
      usage: argParser.usage,
      argResults: argResults,
      git: const Git(),
    );
  } on Exception catch (e) {
    print(e.toString());
    exit(1);
  }
}
