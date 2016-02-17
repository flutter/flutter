// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/base/context.dart';
import 'src/base/logger.dart';
import 'src/base/process.dart';
import 'src/commands/analyze.dart';
import 'src/commands/apk.dart';
import 'src/commands/build.dart';
import 'src/commands/cache.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/install.dart';
import 'src/commands/listen.dart';
import 'src/commands/logs.dart';
import 'src/commands/refresh.dart';
import 'src/commands/run.dart';
import 'src/commands/run_mojo.dart';
import 'src/commands/stop.dart';
import 'src/commands/test.dart';
import 'src/commands/trace.dart';
import 'src/commands/upgrade.dart';
import 'src/device.dart';
import 'src/runner/flutter_command_runner.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the [flutter] command line tool.
Future main(List<String> args) async {
  bool help = args.contains('-h') || args.contains('--help');
  bool verbose = args.contains('-v') || args.contains('--verbose');
  bool verboseHelp = help && verbose;

  FlutterCommandRunner runner = new FlutterCommandRunner(verboseHelp: verboseHelp)
    ..addCommand(new AnalyzeCommand())
    ..addCommand(new ApkCommand())
    ..addCommand(new BuildCommand())
    ..addCommand(new CacheCommand())
    ..addCommand(new CreateCommand())
    ..addCommand(new DaemonCommand(hideCommand: !verboseHelp))
    ..addCommand(new DevicesCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new ListenCommand())
    ..addCommand(new LogsCommand())
    ..addCommand(new RefreshCommand())
    ..addCommand(new RunCommand())
    ..addCommand(new RunMojoCommand(hideCommand: !verboseHelp))
    ..addCommand(new StopCommand())
    ..addCommand(new TestCommand())
    ..addCommand(new TraceCommand())
    ..addCommand(new UpgradeCommand());

  return Chain.capture(() async {
    // Initialize globals.
    context[Logger] = new StdoutLogger();
    context[DeviceManager] = new DeviceManager();

    dynamic result = await runner.run(args);

    if (result is int)
      exit(result);
  }, onError: (error, Chain chain) {
    if (error is UsageException) {
      stderr.writeln(error);
      // Argument error exit code.
      exit(64);
    } else if (error is ProcessExit) {
      // We've caught an exit code.
      exit(error.exitCode);
    } else {
      stderr.writeln(error);
      stderr.writeln(chain.terse);
      exit(1);
    }
  });
}
