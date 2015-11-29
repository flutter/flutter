// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/base/process.dart';
import 'src/commands/analyze.dart';
import 'src/commands/apk.dart';
import 'src/commands/build.dart';
import 'src/commands/cache.dart';
import 'src/commands/daemon.dart';
import 'src/commands/init.dart';
import 'src/commands/install.dart';
import 'src/commands/list.dart';
import 'src/commands/listen.dart';
import 'src/commands/logs.dart';
import 'src/commands/run_mojo.dart';
import 'src/commands/start.dart';
import 'src/commands/stop.dart';
import 'src/commands/test.dart';
import 'src/commands/trace.dart';
import 'src/commands/upgrade.dart';
import 'src/runner/flutter_command_runner.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the [flutter] command line tool.
Future main(List<String> args) async {
  DateTime startTime = new DateTime.now();

  // This level can be adjusted by users through the `--verbose` option.
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((LogRecord record) {
    String prefix = '';
    if (Logger.root.level <= Level.FINE) {
      Duration elapsed = record.time.difference(startTime);
      prefix = '[${elapsed.inMilliseconds.toString().padLeft(4)} ms] ';
    }
    String level = record.level.name.toLowerCase();
    if (record.level >= Level.WARNING) {
      stderr.writeln('$prefix$level: ${record.message}');
    } else {
      print('$prefix$level: ${record.message}');
    }
    if (record.error != null)
      stderr.writeln(record.error);
    if (record.stackTrace != null)
      stderr.writeln(record.stackTrace);
  });

  FlutterCommandRunner runner = new FlutterCommandRunner()
    ..addCommand(new AnalyzeCommand())
    ..addCommand(new ApkCommand())
    ..addCommand(new BuildCommand())
    ..addCommand(new CacheCommand())
    ..addCommand(new DaemonCommand())
    ..addCommand(new InitCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new ListCommand())
    ..addCommand(new ListenCommand())
    ..addCommand(new LogsCommand())
    ..addCommand(new RunMojoCommand())
    ..addCommand(new StartCommand())
    ..addCommand(new StopCommand())
    ..addCommand(new TestCommand())
    ..addCommand(new TraceCommand())
    ..addCommand(new UpgradeCommand());

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
