// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl_standalone.dart' as intl_standalone;

import 'src/base/async_guard.dart';
import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/process.dart';
import 'src/context_runner.dart';
import 'src/doctor.dart';
import 'src/globals.dart' as globals;
import 'src/reporting/crash_reporting.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';

/// Runs the Flutter tool with support for the specified list of [commands].
Future<int> run(
  List<String> args,
  List<FlutterCommand> Function() commands, {
    bool muteCommandLogging = false,
    bool verbose = false,
    bool verboseHelp = false,
    bool reportCrashes,
    String flutterVersion,
    Map<Type, Generator> overrides,
  }) async {
  if (muteCommandLogging) {
    // Remove the verbose option; for help and doctor, users don't need to see
    // verbose logs.
    args = List<String>.of(args);
    args.removeWhere((String option) => option == '-vv' || option == '-v' || option == '--verbose');
  }

  return runInContext<int>(() async {
    reportCrashes ??= !await globals.isRunningOnBot;
    final FlutterCommandRunner runner = FlutterCommandRunner(verboseHelp: verboseHelp);
    commands().forEach(runner.addCommand);

    // Initialize the system locale.
    final String systemLocale = await intl_standalone.findSystemLocale();
    intl.Intl.defaultLocale = intl.Intl.verifiedLocale(
      systemLocale, intl.NumberFormat.localeExists,
      onFailure: (String _) => 'en_US',
    );

    String getVersion() => flutterVersion ?? globals.flutterVersion.getVersionString(redactUnknownBranches: true);
    Object firstError;
    StackTrace firstStackTrace;
    return runZoned<Future<int>>(() async {
      try {
        await runner.run(args);

        // Triggering [runZoned]'s error callback does not necessarily mean that
        // we stopped executing the body.  See https://github.com/dart-lang/sdk/issues/42150.
        if (firstError == null) {
          return await _exit(0);
        }

        // We already hit some error, so don't return success.  The error path
        // (which should be in progress) is responsible for calling _exit().
        return 1;
      } catch (error, stackTrace) { // ignore: avoid_catches_without_on_clauses
        // This catches all exceptions to send to crash logging, etc.
        firstError = error;
        firstStackTrace = stackTrace;
        return _handleToolError(error, stackTrace, verbose, args, reportCrashes, getVersion);
      }
    }, onError: (Object error, StackTrace stackTrace) async { // ignore: deprecated_member_use
      // If sending a crash report throws an error into the zone, we don't want
      // to re-try sending the crash report with *that* error. Rather, we want
      // to send the original error that triggered the crash report.
      firstError ??= error;
      firstStackTrace ??= stackTrace;
      await _handleToolError(firstError, firstStackTrace, verbose, args, reportCrashes, getVersion);
    });
  }, overrides: overrides);
}

Future<int> _handleToolError(
  dynamic error,
  StackTrace stackTrace,
  bool verbose,
  List<String> args,
  bool reportCrashes,
  String Function() getFlutterVersion,
) async {
  if (error is UsageException) {
    globals.printError('${error.message}\n');
    globals.printError("Run 'flutter -h' (or 'flutter <command> -h') for available flutter commands and options.");
    // Argument error exit code.
    return _exit(64);
  } else if (error is ToolExit) {
    if (error.message != null) {
      globals.printError(error.message);
    }
    if (verbose) {
      globals.printError('\n$stackTrace\n');
    }
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
    globals.stdio.stderrWrite('\n');

    if (!reportCrashes) {
      // Print the stack trace on the bots - don't write a crash report.
      globals.stdio.stderrWrite('$error\n');
      globals.stdio.stderrWrite('$stackTrace\n');
      return _exit(1);
    }

    // Report to both [Usage] and [CrashReportSender].
    globals.flutterUsage.sendException(error);
    await asyncGuard(() async {
      final CrashReportSender crashReportSender = CrashReportSender(
        usage: globals.flutterUsage,
        platform: globals.platform,
        logger: globals.logger,
        operatingSystemUtils: globals.os,
      );
      await crashReportSender.sendReport(
        error: error,
        stackTrace: stackTrace,
        getFlutterVersion: getFlutterVersion,
        command: args.join(' '),
      );
    }, onError: (dynamic error) {
      globals.printError('Error sending crash report: $error');
    });

    globals.printError('Oops; flutter has exited unexpectedly: "$error".');

    try {
      final CrashDetails details = CrashDetails(
        command: _crashCommand(args),
        error: error,
        stackTrace: stackTrace,
        doctorText: await _doctorText(),
      );
      final File file = await _createLocalCrashReport(details);
      await globals.crashReporter.informUser(details, file);

      return _exit(1);
    // This catch catches all exceptions to ensure the message below is printed.
    } catch (error) { // ignore: avoid_catches_without_on_clauses
      globals.stdio.stderrWrite(
        'Unable to generate crash report due to secondary error: $error\n'
        '${globals.userMessages.flutterToolBugInstructions}\n',
      );
      // Any exception thrown here (including one thrown by `_exit()`) will
      // get caught by our zone's `onError` handler. In order to avoid an
      // infinite error loop, we throw an error that is recognized above
      // and will trigger an immediate exit.
      throw ProcessExit(1, immediate: true);
    }
  }
}

String _crashCommand(List<String> args) => 'flutter ${args.join(' ')}';

String _crashException(dynamic error) => '${error.runtimeType}: $error';

/// Saves the crash report to a local file.
Future<File> _createLocalCrashReport(CrashDetails details) async {
  File crashFile = globals.fsUtils.getUniqueFile(
    globals.fs.currentDirectory,
    'flutter',
    'log',
  );

  final StringBuffer buffer = StringBuffer();

  buffer.writeln('Flutter crash report.');
  buffer.writeln('${globals.userMessages.flutterToolBugInstructions}\n');

  buffer.writeln('## command\n');
  buffer.writeln('${details.command}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('${_crashException(details.error)}\n');
  buffer.writeln('```\n${details.stackTrace}```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${details.doctorText}```');

  try {
    crashFile.writeAsStringSync(buffer.toString());
  } on FileSystemException catch (_) {
    // Fallback to the system temporary directory.
    crashFile = globals.fsUtils.getUniqueFile(
      globals.fs.systemTempDirectory,
      'flutter',
      'log',
    );
    try {
      crashFile.writeAsStringSync(buffer.toString());
    } on FileSystemException catch (e) {
      globals.printError('Could not write crash report to disk: $e');
      globals.printError(buffer.toString());
    }
  }

  return crashFile;
}

Future<String> _doctorText() async {
  try {
    final BufferLogger logger = BufferLogger(
      terminal: globals.terminal,
      outputPreferences: globals.outputPreferences,
    );

    final Doctor doctor = Doctor(logger: logger);
    await doctor.diagnose(showColor: false);

    return logger.statusText;
  } on Exception catch (error, trace) {
    return 'encountered exception: $error\n\n${trace.toString().trim()}\n';
  }
}

Future<int> _exit(int code) async {
  // Prints the welcome message if needed.
  globals.flutterUsage.printWelcome();

  // Send any last analytics calls that are in progress without overly delaying
  // the tool's exit (we wait a maximum of 250ms).
  if (globals.flutterUsage.enabled) {
    final Stopwatch stopwatch = Stopwatch()..start();
    await globals.flutterUsage.ensureAnalyticsSent();
    globals.printTrace('ensureAnalyticsSent: ${stopwatch.elapsedMilliseconds}ms');
  }

  // Run shutdown hooks before flushing logs
  await globals.shutdownHooks.runShutdownHooks();

  final Completer<void> completer = Completer<void>();

  // Give the task / timer queue one cycle through before we hard exit.
  Timer.run(() {
    try {
      globals.printTrace('exiting with code $code');
      exit(code);
      completer.complete();
    // This catches all exceptions because the error is propagated on the
    // completer.
    } catch (error, stackTrace) { // ignore: avoid_catches_without_on_clauses
      completer.completeError(error, stackTrace);
    }
  });

  await completer.future;
  return code;
}
