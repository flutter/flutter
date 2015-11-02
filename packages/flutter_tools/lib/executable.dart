// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/commands/build.dart';
import 'src/commands/cache.dart';
import 'src/commands/flutter_command_runner.dart';
import 'src/commands/init.dart';
import 'src/commands/install.dart';
import 'src/commands/list.dart';
import 'src/commands/listen.dart';
import 'src/commands/logs.dart';
import 'src/commands/run_mojo.dart';
import 'src/commands/start.dart';
import 'src/commands/stop.dart';
import 'src/commands/trace.dart';
import 'src/process.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the [flutter] command line tool.
Future main(List<String> args) async {
  // This level can be adjusted by users through the `--verbose` option.
  Logger.root.level = Level.SEVERE;
  Logger.root.onRecord.listen((LogRecord record) {
    if (record.level >= Level.WARNING) {
      stderr.writeln(record.message);
    } else {
      print(record.message);
    }
    if (record.error != null)
      stderr.writeln(record.error);
    if (record.stackTrace != null)
      stderr.writeln(record.stackTrace);
  });

  FlutterCommandRunner runner = new FlutterCommandRunner()
    ..addCommand(new BuildCommand())
    ..addCommand(new CacheCommand())
    ..addCommand(new InitCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new ListCommand())
    ..addCommand(new ListenCommand())
    ..addCommand(new LogsCommand())
    ..addCommand(new RunMojoCommand())
    ..addCommand(new StartCommand())
    ..addCommand(new StopCommand())
    ..addCommand(new TraceCommand());

  return Chain.capture(() async {
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
      Logger.root.log(Level.SEVERE, '\nException:', null, chain.terse.toTrace());
      exit(1);
    }
  });
}
