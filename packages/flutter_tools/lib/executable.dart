// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'runner.dart' as runner;
import 'src/commands/analyze.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/clean.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/drive.dart';
import 'src/commands/format.dart';
import 'src/commands/fuchsia_reload.dart';
import 'src/commands/ide_config.dart';
import 'src/commands/inject_plugins.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/stop.dart';
import 'src/commands/test.dart';
import 'src/commands/trace.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/runner/flutter_command.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<Null> main(List<String> args) async {
  final bool verbose = args.contains('-v') || args.contains('--verbose');

  final bool doctor = (args.isNotEmpty && args.first == 'doctor') ||
      (args.length == 2 && verbose && args.last == 'doctor');
  final bool help = args.contains('-h') || args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') || (args.length == 1 && verbose);
  final bool muteCommandLogging = help || doctor;
  final bool verboseHelp = help && verbose;

  await runner.run(args, <FlutterCommand>[
    new AnalyzeCommand(verboseHelp: verboseHelp),
    new BuildCommand(verboseHelp: verboseHelp),
    new ChannelCommand(verboseHelp: verboseHelp),
    new CleanCommand(),
    new InjectPluginsCommand(hidden: !verboseHelp),
    new ConfigCommand(verboseHelp: verboseHelp),
    new CreateCommand(),
    new DaemonCommand(hidden: !verboseHelp),
    new DevicesCommand(),
    new DoctorCommand(verbose: verbose),
    new DriveCommand(),
    new FormatCommand(),
    new FuchsiaReloadCommand(),
    new IdeConfigCommand(hidden: !verboseHelp),
    new InstallCommand(),
    new LogsCommand(),
    new PackagesCommand(),
    new PrecacheCommand(),
    new RunCommand(verboseHelp: verboseHelp),
    new ScreenshotCommand(),
    new StopCommand(),
    new TestCommand(verboseHelp: verboseHelp),
    new TraceCommand(),
    new UpdatePackagesCommand(hidden: !verboseHelp),
    new UpgradeCommand(),
  ], verbose: verbose,
     muteCommandLogging: muteCommandLogging,
     verboseHelp: verboseHelp);
}
