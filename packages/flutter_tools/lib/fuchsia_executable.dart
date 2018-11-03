// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'runner.dart' as runner;
import 'src/commands/attach.dart';
import 'src/commands/devices.dart';
import 'src/commands/shell_completion.dart';
import 'src/runner/flutter_command.dart';

 final ArgParser parser = ArgParser.allowAnything()
  ..addOption('verbose', abbr: 'v')
  ..addOption('help', abbr: 'h')
  ..addOption(
    'frontend-server',
    help: 'The path to the frontend server snapshot.',
  )
  ..addOption(
    'dart-sdk',
    help: 'The path to the patched dart-sdk binary.',
  );

/// Main entry point for fuchsia commands.
///
/// This function is intended to be used within the fuchsia source tree.
Future<void> main(List<String> args) async {
  final ArgResults results = parser.parse(args);
  final bool verbose = results['verbose'];
  final bool help = results['help'];
  final bool verboseHelp = help && verbose;
  final File dartSdk = fs.file(results['dart-sdk']);
  final File frontendServer = fs.file(results['frontend-server']);

  if (!dartSdk.existsSync()) {
    throwToolExit('--frontend-server is required');
  }
  if (!frontendServer.existsSync()) {
    throwToolExit('--dart-sdk is required');
  }

  await runner.run(args, <FlutterCommand>[
    AttachCommand(verboseHelp: verboseHelp),
    DevicesCommand(),
    ShellCompletionCommand(),
  ], verbose: verbose,
     muteCommandLogging: help,
     verboseHelp: verboseHelp,
     overrides: <Type, Generator>{
      Artifacts: () => OverrideArtifacts(
        parent: CachedArtifacts(),
          frontendServer: frontendServer,
          engineDartBinary: dartSdk,
       )
     });
}
