// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl_standalone.dart' as intl_standalone;

import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/io.dart';
import 'src/base/process.dart';
import 'src/context_runner.dart';
import 'src/globals.dart' as globals;
import 'src/reporting/reporting.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';

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
}) async {
  if (muteCommandLogging) {
    // Remove the verbose option; for help and doctor, users don't need to see
    // verbose logs.
    args = List<String>.from(args);
    args.removeWhere((String option) => option == '-v' || option == '--verbose');
  }

  final FlutterCommandRunner runner = FlutterCommandRunner(verboseHelp: verboseHelp);
  commands.forEach(runner.addCommand);

  return runInContext<int>(() async {
    reportCrashes ??= !await globals.isRunningOnBot;

    // Initialize the system locale.
    final String systemLocale = await intl_standalone.findSystemLocale();
    intl.Intl.defaultLocale = intl.Intl.verifiedLocale(
      systemLocale, intl.NumberFormat.localeExists,
      onFailure: (String _) => 'en_US',
    );

    String getVersion() => flutterVersion ?? globals.flutterVersion.getVersionString(redactUnknownBranches: true);
    Object firstError;
    StackTrace firstStackTrace;
    return await runZoned<Future<int>>(() async {
      try {
        await runner.run(args);
        return await _exit(0);
      // This catches all exceptions to send to crash logging, etc.
      } catch (error, stackTrace) {  // ignore: avoid_catches_without_on_clauses
        firstError = error;
        firstStackTrace = stackTrace;
        return await _handleToolError(
            error, stackTrace, verbose, args, reportCrashes, getVersion);
      }
    }, onError: (Object error, StackTrace stackTrace) async { // ignore: deprecated_member_use
      // If sending a crash report throws an error into the zone, we don't want
      // to re-try sending the crash report with *that* error. Rather, we want
      // to send the original error that triggered the crash report.
      final Object e = firstError ?? error;
      final StackTrace s = firstStackTrace ?? stackTrace;
      await _handleToolError(e, s, verbose, args, reportCrashes, getVersion);
    });
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
    await CrashReportSender.instance.sendReport(
      error: error,
      stackTrace: stackTrace,
      getFlutterVersion: getFlutterVersion,
      command: args.join(' '),
    );

    final String errorString = error.toString();
    globals.printError('Oops; flutter has exited unexpectedly: "$errorString".');

    try {
      await CrashReportSender.instance.informUserOfCrash(args, error, stackTrace, errorString);

      return _exit(1);
    // This catch catches all exceptions to ensure the message below is printed.
    } catch (error) { // ignore: avoid_catches_without_on_clauses
      globals.stdio.stderrWrite(
        'Unable to generate crash report due to secondary error: $error\n'
        'please let us know at https://github.com/flutter/flutter/issues.\n',
      );
      // Any exception throw here (including one thrown by `_exit()`) will
      // get caught by our zone's `onError` handler. In order to avoid an
      // infinite error loop, we throw an error that is recognized above
      // and will trigger an immediate exit.
      throw ProcessExit(1, immediate: true);
    }
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
  await shutdownHooks.runShutdownHooks();

  final Completer<void> completer = Completer<void>();

  // Give the task / timer queue one cycle through before we hard exit.
  Timer.run(() {
    try {
      globals.printTrace('exiting with code $code');
      exit(code);
      completer.complete();
    // This catches all exceptions becauce the error is propagated on the
    // completer.
    } catch (error, stackTrace) { // ignore: avoid_catches_without_on_clauses
      completer.completeError(error, stackTrace);
    }
  });

  await completer.future;
  return code;
}
