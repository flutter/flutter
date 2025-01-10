// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';

void main(List<String> args) async {
  final ArgResults argResults = _argParser.parse(args);
  if (argResults.flag('help')) {
    return _printUsage();
  }

  final List<String> testFiles = argResults.rest;
  if (testFiles.length != 1) {
    io.stderr.writeln('Exactly one test-file must be specified');
    _printUsage();
    io.exitCode = 1;
    return;
  }

  final io.File testFile = io.File(testFiles.single);
  if (!testFile.existsSync()) {
    io.stderr.writeln('Not a file: ${testFile.path}');
    _printUsage();
    io.exitCode = 1;
    return;
  }
}

final ArgParser _argParser =
    ArgParser()..addFlag('help', abbr: 'h', help: 'Display usage information.', negatable: false);

void _printUsage() {
  io.stdout.writeln('Usage: dart tool/deflake.dart lib/<path-to-main>.dart');
  io.stdout.writeln(_argParser.usage);
}
