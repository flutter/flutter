// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:file/file.dart';

import 'runner.dart' as runner;

import 'src/artifacts.dart';
import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/commands/fuchsia_reload.dart';
import 'src/runner/flutter_command.dart';

/// The location of the fuchsia tools directory.
const String _kFuchsiaToolsOptions = 'fuchsia_tools';
const String _kVerboseFlag = 'verbose';
const String _kHelpFlag = 'help';

// A parser to retrieve to location of the fuchsia tools directory regardless
// of the passed command.
final ArgParser _fuchsiaArgParser = ArgParser.allowAnything()
  ..addFlag(_kVerboseFlag, abbr: 'v')
  ..addFlag(_kHelpFlag, abbr: 'h')
  ..addOption(_kFuchsiaToolsOptions, help: 'The location of the fuchsia tools directory.', hide: true);

/// Main entry point for fuchsia commands.
///
/// This function is intended to be used from the `fx` command line tool.
Future<void> main(List<String> args) async {
  final ArgResults results = _fuchsiaArgParser.parse(args);
  final bool verbose = results[_kVerboseFlag];
  final bool help = results[_kHelpFlag];
  final Directory fuchsiaToolsDirectory = fs.directory(results[_kFuchsiaToolsOptions]);
  if (!fuchsiaToolsDirectory.existsSync()) {
    throwToolExit('the fuchsia_tools directory ${fuchsiaToolsDirectory.path} could not be found.');
  }

  await runner.run(args, <FlutterCommand>[
    FuchsiaReloadCommand(),
  ], verbose: verbose,
     muteCommandLogging: help,
     verboseHelp: help && verbose,
     overrides: <Type, Generator>{
       Artifacts: () => FuchsiaArtifacts(fuchsiaToolsDirectory),
     },
  );
}
