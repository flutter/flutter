// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/base/context.dart';
import 'src/base/process.dart';
import 'src/commands/analyze.dart';
import 'src/commands/apk.dart';
import 'src/commands/build.dart';
import 'src/commands/cache.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/install.dart';
import 'src/commands/ios.dart';
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
  FlutterCommandRunner runner = new FlutterCommandRunner()
    ..addCommand(new AnalyzeCommand())
    ..addCommand(new ApkCommand())
    ..addCommand(new BuildCommand())
    ..addCommand(new CacheCommand())
    ..addCommand(new CreateCommand())
    ..addCommand(new DaemonCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new IOSCommand())
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
    // Convert `flutter init` invocations to `flutter create` ones.
    // TODO(devoncarew): Remove this after a few releases.
    if (args.isNotEmpty && args[0] == 'init')
      args[0] = 'create';

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
      printError(error, chain.terse.toTrace());
      exit(1);
    }
  });
}
