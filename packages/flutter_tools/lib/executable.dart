// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/logger.dart';
import 'src/base/process.dart';
import 'src/base/utils.dart';
import 'src/commands/analyze.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/drive.dart';
import 'src/commands/format.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/setup.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/refresh.dart';
import 'src/commands/run.dart';
import 'src/commands/run_mojo.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/skia.dart';
import 'src/commands/stop.dart';
import 'src/commands/test.dart';
import 'src/commands/trace.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/device.dart';
import 'src/doctor.dart';
import 'src/globals.dart';
import 'src/runner/flutter_command_runner.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<Null> main(List<String> args) async {
  bool verbose = args.contains('-v') || args.contains('--verbose');
  bool help = args.contains('-h') || args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') || (args.length == 1 && verbose);
  bool verboseHelp = help && verbose;

  if (verboseHelp) {
    // Remove the verbose option; for help, users don't need to see verbose logs.
    args = new List<String>.from(args);
    args.removeWhere((String option) => option == '-v' || option == '--verbose');
  }

  FlutterCommandRunner runner = new FlutterCommandRunner(verboseHelp: verboseHelp)
    ..addCommand(new AnalyzeCommand(verboseHelp: verboseHelp))
    ..addCommand(new BuildCommand(verboseHelp: verboseHelp))
    ..addCommand(new ChannelCommand())
    ..addCommand(new ConfigCommand())
    ..addCommand(new CreateCommand())
    ..addCommand(new DaemonCommand(hidden: !verboseHelp))
    ..addCommand(new DevicesCommand())
    ..addCommand(new DoctorCommand())
    ..addCommand(new DriveCommand())
    ..addCommand(new FormatCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new LogsCommand())
    ..addCommand(new PackagesCommand())
    ..addCommand(new PrecacheCommand())
    ..addCommand(new RefreshCommand())
    ..addCommand(new RunCommand(verboseHelp: verboseHelp))
    ..addCommand(new RunMojoCommand(hidden: !verboseHelp))
    ..addCommand(new ScreenshotCommand())
    ..addCommand(new SetupCommand(hidden: !verboseHelp))
    ..addCommand(new SkiaCommand())
    ..addCommand(new StopCommand())
    ..addCommand(new TestCommand())
    ..addCommand(new TraceCommand())
    ..addCommand(new UpdatePackagesCommand(hidden: !verboseHelp))
    ..addCommand(new UpgradeCommand());

  return Chain.capture/*<Future<Null>>*/(() async {
    // Initialize globals.
    context[Logger] = new StdoutLogger();
    context[DeviceManager] = new DeviceManager();
    Doctor.initGlobal();

    dynamic result = await runner.run(args);
    _exit(result is int ? result : 0);
  }, onError: (dynamic error, Chain chain) {
    if (error is UsageException) {
      stderr.writeln(error.message);
      stderr.writeln();
      stderr.writeln(
        "Run 'flutter -h' (or 'flutter <command> -h') for available "
        "flutter commands and options."
      );
      // Argument error exit code.
      _exit(64);
    } else if (error is ToolExit) {
      stderr.writeln(error.message);
      if (verbose) {
        stderr.writeln();
        stderr.writeln(chain.terse.toString());
        stderr.writeln();
      }
      stderr.writeln('If this problem persists, please report the problem at');
      stderr.writeln('https://github.com/flutter/flutter/issues/new');
      _exit(error.exitCode ?? 65);
    } else if (error is ProcessExit) {
      // We've caught an exit code.
      _exit(error.exitCode);
    } else {
      // We've crashed; emit a log report.
      stderr.writeln();

      flutterUsage.sendException(error, chain);

      if (isRunningOnBot) {
        // Print the stack trace on the bots - don't write a crash report.
        stderr.writeln('$error');
        stderr.writeln(chain.terse.toString());
        _exit(1);
      } else {
        if (error is String)
          stderr.writeln('Oops; flutter has exited unexpectedly: "$error".');
        else
          stderr.writeln('Oops; flutter has exited unexpectedly.');

        _createCrashReport(args, error, chain).then((File file) {
          stderr.writeln(
              'Crash report written to ${file.path};\n'
              'please let us know at https://github.com/flutter/flutter/issues.'
          );
          _exit(1);
        });
      }
    }
  });
}

Future<File> _createCrashReport(List<String> args, dynamic error, Chain chain) async {
  File crashFile = getUniqueFile(Directory.current, 'flutter', 'log');

  StringBuffer buffer = new StringBuffer();

  buffer.writeln('Flutter crash report; please file at https://github.com/flutter/flutter/issues.\n');

  buffer.writeln('## command\n');
  buffer.writeln('flutter ${args.join(' ')}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('$error\n');
  buffer.writeln('```\n${chain.terse}```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${await _doctorText()}```');

  try {
    crashFile.writeAsStringSync(buffer.toString());
  } on FileSystemException catch (_) {
    // Fallback to the system temporary directory.
    crashFile = getUniqueFile(Directory.systemTemp, 'flutter', 'log');
    try {
      crashFile.writeAsStringSync(buffer.toString());
    } on FileSystemException catch (e) {
      printError('Could not write crash report to disk: $e');
      printError(buffer.toString());
    }
  }

  return crashFile;
}

Future<String> _doctorText() async {
  try {
    BufferLogger logger = new BufferLogger();
    AppContext appContext = new AppContext();

    appContext[Logger] = logger;

    await appContext.runInZone(() => doctor.diagnose());

    return logger.statusText;
  } catch (error, trace) {
    return 'encountered exception: $error\n\n${trace.toString().trim()}\n';
  }
}

Future<Null> _exit(int code) async {
  if (flutterUsage.isFirstRun)
    flutterUsage.printUsage();

  // Send any last analytics calls that are in progress without overly delaying
  // the tool's exit (we wait a maximum of 250ms).
  if (flutterUsage.enabled) {
    Stopwatch stopwatch = new Stopwatch()..start();
    await flutterUsage.ensureAnalyticsSent();
    printTrace('ensureAnalyticsSent: ${stopwatch.elapsedMilliseconds}ms');
  }

  // Write any buffered output.
  logger.flush();

  // Give the task / timer queue one cycle through before we hard exit.
  Timer.run(() {
    printTrace('exiting with code $code');
    exit(code);
  });
}
