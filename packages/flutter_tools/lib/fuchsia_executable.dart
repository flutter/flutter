// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';

import 'runner.dart' as runner;

import 'src/artifacts.dart';
import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/commands/attach.dart';
import 'src/commands/devices.dart';
import 'src/commands/shell_completion.dart';
import 'src/fuchsia/fuchsia_sdk.dart';
import 'src/run_hot.dart';
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
  )
  ..addOption(
    'ssh-config',
    help: 'The path to the ssh configuration file.',
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
  final File sshConfig = fs.file(results['ssh-config']);

  if (!dartSdk.existsSync()) {
    throwToolExit('--dart-sdk is required: ${dartSdk.path} does not exist.');
  }
  if (!frontendServer.existsSync()) {
    throwToolExit('--frontend-server is required: ${frontendServer.path} does not exist.');
  }
  if (!sshConfig.existsSync()) {
    throwToolExit('--ssh-config is required: ${sshConfig.path} does not exist.');
  }

  await runner.run(args, <FlutterCommand>[
    AttachCommand(verboseHelp: verboseHelp),
    DevicesCommand(),
    ShellCompletionCommand(),
  ], verbose: verbose,
     muteCommandLogging: help,
     verboseHelp: verboseHelp,
     overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      Artifacts: () => OverrideArtifacts(
        parent: CachedArtifacts(),
        frontendServer: frontendServer,
        engineDartBinary: dartSdk,
      ),
      HotRunnerConfig: () => HotRunnerConfig()
        ..computeDartDependencies = false,
     });
}
