// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' as argslib;
import 'package:meta/meta.dart';

void exitWithError(String errorMessage) {
  if (errorMessage == null)
    return;
  stderr.writeln('Fatal Error: $errorMessage');
  exit(1);
}

void checkCwdIsRepoRoot(String commandName) {
  final bool isRepoRoot = new Directory('.git').existsSync();

  if (!isRepoRoot) {
    exitWithError(
      '$commandName must be run from the root of the Flutter repository. The '
      'current working directory is: ${Directory.current.path}'
    );
  }
}

GeneratorOptions parseArgs(List<String> rawArgs) {
  final argslib.ArgParser argParser = new argslib.ArgParser()
    ..addFlag(
      'overwrite',
      abbr: 'w',
      defaultsTo: false,
    );
  final argslib.ArgResults args = argParser.parse(rawArgs);
  final bool writeToFile = args['overwrite'];

  return new GeneratorOptions(writeToFile: writeToFile);
}

class GeneratorOptions {
  GeneratorOptions({
    @required this.writeToFile,
  });

  final bool writeToFile;
}
