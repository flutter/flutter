// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'runner.dart' as runner;
import 'src/base/context.dart';
// The build_runner code generation is provided here to make it easier to
// avoid introducing the dependency into google3. Not all build* packages
// are synced internally.
import 'src/build_runner/build_runner.dart';
import 'src/build_runner/resident_web_runner.dart';
import 'src/build_runner/web_compilation_delegate.dart';

import 'src/codegen.dart';
import 'src/commands/analyze.dart';
import 'src/commands/assemble.dart';
import 'src/commands/attach.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/clean.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/downgrade.dart';
import 'src/commands/drive.dart';
import 'src/commands/emulators.dart';
import 'src/commands/format.dart';
import 'src/commands/generate.dart';
import 'src/commands/ide_config.dart';
import 'src/commands/inject_plugins.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/make_host_app_editable.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/shell_completion.dart';
import 'src/commands/symbolize.dart';
import 'src/commands/test.dart';
import 'src/commands/train.dart';
import 'src/commands/unpack.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/commands/version.dart';
import 'src/globals.dart' as globals;
import 'src/runner/flutter_command.dart';
import 'src/web/compile.dart';
import 'src/web/web_runner.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<void> main(List<String> args) async {
  final bool verbose = args.contains('-v') || args.contains('--verbose');

  final bool doctor = (args.isNotEmpty && args.first == 'doctor') ||
      (args.length == 2 && verbose && args.last == 'doctor');
  final bool help = args.contains('-h') || args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') || (args.length == 1 && verbose);
  final bool muteCommandLogging = help || doctor;
  final bool verboseHelp = help && verbose;

  await runner.run(args, <FlutterCommand>[
    AnalyzeCommand(verboseHelp: verboseHelp),
    AssembleCommand(),
    AttachCommand(verboseHelp: verboseHelp),
    BuildCommand(verboseHelp: verboseHelp),
    ChannelCommand(verboseHelp: verboseHelp),
    CleanCommand(),
    ConfigCommand(verboseHelp: verboseHelp),
    CreateCommand(),
    DaemonCommand(hidden: !verboseHelp),
    DevicesCommand(),
    DoctorCommand(verbose: verbose),
    DowngradeCommand(),
    DriveCommand(),
    EmulatorsCommand(),
    FormatCommand(),
    GenerateCommand(),
    IdeConfigCommand(hidden: !verboseHelp),
    InjectPluginsCommand(hidden: !verboseHelp),
    InstallCommand(),
    LogsCommand(),
    MakeHostAppEditableCommand(),
    PackagesCommand(),
    PrecacheCommand(verboseHelp: verboseHelp),
    RunCommand(verboseHelp: verboseHelp),
    ScreenshotCommand(),
    ShellCompletionCommand(),
    TestCommand(verboseHelp: verboseHelp),
    TrainingCommand(),
    UnpackCommand(),
    UpdatePackagesCommand(hidden: !verboseHelp),
    UpgradeCommand(),
    VersionCommand(),
    SymbolizeCommand(
      stdio: globals.stdio,
      fileSystem: globals.fs,
    ),
  ], verbose: verbose,
     muteCommandLogging: muteCommandLogging,
     verboseHelp: verboseHelp,
     overrides: <Type, Generator>{
       // The build runner instance is not supported in google3 because
       // the build runner packages are not synced internally.
       CodeGenerator: () => const BuildRunner(),
       WebCompilationProxy: () => BuildRunnerWebCompilationProxy(),
       // The web runner is not supported internally because it depends
       // on dwds.
       WebRunnerFactory: () => DwdsWebRunnerFactory(),
     });
}
