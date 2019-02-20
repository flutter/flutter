// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl_standalone.dart' as intl_standalone;
import 'package:meta/meta.dart';

import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/process.dart';
import 'src/base/utils.dart';
import 'src/context_runner.dart';
import 'src/crash_reporting.dart';
import 'src/doctor.dart';
import 'src/globals.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';
import 'src/usage.dart';
import 'src/version.dart';

/// Runs the Flutter tool with support for the specified list of [commands].
Future<int> run(
  List<String> args,
  List<FlutterCommand> commands, {
  bool muteCommandLogging = false,
  bool verbose = false,
  bool verboseHelp = false,
  bool reportCrashes,
  String flutterVersion,
  Map<Type, Generator> overrides,
}) {
  reportCrashes ??= !isRunningOnBot;

  if (muteCommandLogging) {
    // Remove the verbose option; for help and doctor, users don't need to see
    // verbose logs.
    args = List<String>.from(args);
    args.removeWhere((String option) => option == '-v' || option == '--verbose');
  }

  final FlutterCommandRunner runner = FlutterCommandRunner(verboseHelp: verboseHelp);
  commands.forEach(runner.addCommand);

  return runInContext<int>(() async {
    // Initialize the system locale.
    final String systemLocale = await intl_standalone.findSystemLocale();
    intl.Intl.defaultLocale = intl.Intl.verifiedLocale(
      systemLocale, intl.NumberFormat.localeExists,
      onFailure: (String _) => 'en_US'
    );

    try {
      await runner.run(args);
      await _exit(0);
    } catch (error, stackTrace) {
      String getVersion() => flutterVersion ?? FlutterVersion.instance.getVersionString();
      return await _handleToolError(error, stackTrace, verbose, args, reportCrashes, getVersion);
    }
    return 0;
  }, overrides: overrides);
}

Future<int> _handleToolError(
    dynamic error,
    StackTrace stackTrace,
    bool verbose,
    List<String> args,
    bool reportCrashes,
    String getFlutterVersion(),
    ) async {
  if (error is UsageException) {
    printError('${error.message}\n');
    printError("Run 'flutter -h' (or 'flutter <command> -h') for available flutter commands and options.");
    // Argument error exit code.
    return _exit(64);
  } else if (error is ToolExit) {
    if (error.message != null)
      printError(error.message);
    if (verbose)
      printError('\n$stackTrace\n');
    return _exit(error.exitCode ?? 1);
  } else if (error is ProcessExit) {
    // We've caught an exit code.
    if (error.immediate) {
      exit(error.exitCode);
      return error.exitCode;
    } else {
      return _exit(error.exitCode);
    }
  } else {
    // We've crashed; emit a log report.
    stderr.writeln();

    if (!reportCrashes) {
      // Print the stack trace on the bots - don't write a crash report.
      stderr.writeln('$error');
      stderr.writeln(stackTrace.toString());
      return _exit(1);
    } else {
      flutterUsage.sendException(error, stackTrace);

      if (error is String)
        stderr.writeln('Oops; flutter has exited unexpectedly: "$error".');
      else
        stderr.writeln('Oops; flutter has exited unexpectedly.');

      await CrashReportSender.instance.sendReport(
        error: error,
        stackTrace: stackTrace,
        getFlutterVersion: getFlutterVersion,
      );
      try {
        final File file = await _createLocalCrashReport(args, error, stackTrace);
        stderr.writeln(
          'Crash report written to ${file.path};\n'
              'please let us know at https://github.com/flutter/flutter/issues.',
        );
        return _exit(1);
      } catch (error) {
        stderr.writeln(
          'Unable to generate crash report due to secondary error: $error\n'
              'please let us know at https://github.com/flutter/flutter/issues.',
        );
        // Any exception throw here (including one thrown by `_exit()`) will
        // get caught by our zone's `onError` handler. In order to avoid an
        // infinite error loop, we throw an error that is recognized above
        // and will trigger an immediate exit.
        throw ProcessExit(1, immediate: true);
      }
    }
  }
}

/// File system used by the crash reporting logic.
///
/// We do not want to use the file system stored in the context because it may
/// be recording. Additionally, in the case of a crash we do not trust the
/// integrity of the [AppContext].
@visibleForTesting
FileSystem crashFileSystem = const LocalFileSystem();

/// Saves the crash report to a local file.
Future<File> _createLocalCrashReport(List<String> args, dynamic error, StackTrace stackTrace) async {
  File crashFile = getUniqueFile(crashFileSystem.currentDirectory, 'flutter', 'log');

  final StringBuffer buffer = StringBuffer();

  buffer.writeln('Flutter crash report; please file at https://github.com/flutter/flutter/issues.\n');

  buffer.writeln('## command\n');
  buffer.writeln('flutter ${args.join(' ')}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('${error.runtimeType}: $error\n');
  buffer.writeln('```\n$stackTrace```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${await _doctorText()}```');

  try {
    await crashFile.writeAsString(buffer.toString());
  } on FileSystemException catch (_) {
    // Fallback to the system temporary directory.
    crashFile = getUniqueFile(crashFileSystem.systemTempDirectory, 'flutter', 'log');
    try {
      await crashFile.writeAsString(buffer.toString());
    } on FileSystemException catch (e) {
      printError('Could not write crash report to disk: $e');
      printError(buffer.toString());
    }
  }

  return crashFile;
}

Future<String> _doctorText() async {
  try {
    final BufferLogger logger = BufferLogger();

    await context.run<bool>(
      body: () => doctor.diagnose(verbose: true),
      overrides: <Type, Generator>{
        Logger: () => logger,
      },
    );

    return logger.statusText;
  } catch (error, trace) {
    return 'encountered exception: $error\n\n${trace.toString().trim()}\n';
  }
}

Future<int> _exit(int code) async {
  if (flutterUsage.isFirstRun)
    flutterUsage.printWelcome();

  // Send any last analytics calls that are in progress without overly delaying
  // the tool's exit (we wait a maximum of 250ms).
  if (flutterUsage.enabled) {
    final Stopwatch stopwatch = Stopwatch()..start();
    await flutterUsage.ensureAnalyticsSent();
    printTrace('ensureAnalyticsSent: ${stopwatch.elapsedMilliseconds}ms');
  }

  // Run shutdown hooks before flushing logs
  await runShutdownHooks();

  final Completer<void> completer = Completer<void>();

  // Give the task / timer queue one cycle through before we hard exit.
  Timer.run(() {
    try {
      printTrace('exiting with code $code');
      exit(code);
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  });

  await completer.future;
  return code;
}
