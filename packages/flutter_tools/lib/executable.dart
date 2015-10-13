// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import 'src/commands/flutter_command_runner.dart';
import 'src/commands/build.dart';
import 'src/commands/cache.dart';
import 'src/commands/init.dart';
import 'src/commands/install.dart';
import 'src/commands/list.dart';
import 'src/commands/listen.dart';
import 'src/commands/logs.dart';
import 'src/commands/run_mojo.dart';
import 'src/commands/start.dart';
import 'src/commands/stop.dart';
import 'src/commands/trace.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the [flutter] command line tool.
Future main(List<String> args) async {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((LogRecord record) {
    print('${record.level.name}: ${record.message}');
    if (record.error != null)
      print(record.error);
    if (record.stackTrace != null)
      print(record.stackTrace);
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

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(1);
  }
}
