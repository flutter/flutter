// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl_standalone.dart' as intl_standalone;
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'src/base/async_guard.dart';
import 'src/base/common.dart';
import 'src/base/context.dart';
import 'src/base/error_handling_io.dart';
import 'src/base/exit.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/platform.dart';
import 'src/base/process.dart';
import 'src/base/terminal.dart';
import 'src/context/tool_context.dart';
import 'src/context/tool_dependencies.dart';
import 'src/context_runner.dart';
import 'src/doctor.dart';
import 'src/features.dart';
import 'src/reporting/crash_reporting.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';

/// Runs the Flutter tool with support for the specified list of [commands].
Future<int> run(
  List<String> args,
  List<FlutterCommand> Function(ToolDependencies toolDependencies) commands, {
  required ShutdownHooks shutdownHooks,
  String? flutterVersion,
  bool muteCommandLogging = false,
  bool? reportCrashes,
  bool verbose = false,
  bool verboseHelp = false,
  Logger? logger,
  OutputPreferences? outputPreferences,
  Platform? platform,
  Stdio? stdio,
  AnsiTerminal? terminal,
  ToolDependencies? toolDependencies,
  Map<Type, Generator>? contextOverrides,
}) async {
  return runInContext<int>(() async {
    if (muteCommandLogging) {
      // Remove the verbose option; for help and doctor, users don't need to see
      // verbose logs.
      args = List<String>.of(args);
      args.removeWhere(
        (String option) => option == '-vv' || option == '-v' || option == '--verbose',
      );
    }

    // Reset this on each run to ensure we don't leak state across tests.
    _alreadyHandlingToolError = null;

    final bool usingLocalEngine = args.any((a) => a.startsWith('--local-engine'));

    final ToolDependencies toolDeps =
        toolDependencies ??
        await ToolDependencies.bootstrap(
          logger: logger,
          outputPreferences: outputPreferences,
          platform: platform,
          shutdownHooks: shutdownHooks,
          stdio: stdio,
          terminal: terminal,
        );
    final ToolContext toolContext = toolDeps.toolContext;
    toolContext.terminal.applyFeatureFlags(featureFlags);

    reportCrashes ??= !await toolContext.botDetector.isRunningOnBot;

    final runner = FlutterCommandRunner(
      analytics: toolDeps.analytics,
      toolContext: toolDeps.toolContext,
      verboseHelp: verboseHelp,
    );
    commands(toolDeps).forEach(runner.addCommand);

    // Initialize the system locale.
    final String systemLocale = await intl_standalone.findSystemLocale();
    intl.Intl.defaultLocale = intl.Intl.verifiedLocale(
      systemLocale,
      intl.NumberFormat.localeExists,
      onFailure: (String _) => 'en_US',
    );

    String getVersion() =>
        flutterVersion ?? toolContext.flutterVersion.getVersionString(redactUnknownBranches: true);
    Object? firstError;
    StackTrace? firstStackTrace;
    return runZonedGuarded<Future<int>>(
      () async {
        try {
          if (args.contains('--disable-analytics') && args.contains('--enable-analytics')) {
            throwToolExit(
              'Both enable and disable analytics commands were detected '
              'when only one can be supplied per invocation.',
              exitCode: 1,
            );
          }

          if (args.contains('--disable-analytics')) {
            if (toolDeps.analytics.telemetryEnabled) {
              toolDeps.analytics.send(Event.analyticsCollectionEnabled(status: false));
              // Before disabling analytics, we need to close the client to make
              // sure the above collection event is sent.
              await toolDeps.analytics.close();
            }
            await toolDeps.analytics.setTelemetry(false);
            toolContext.logger.printStatus('Analytics reporting disabled.');
          }

          if (args.contains('--enable-analytics')) {
            final bool alreadyEnabled = toolDeps.analytics.telemetryEnabled;
            await toolDeps.analytics.setTelemetry(true);
            if (!alreadyEnabled) {
              toolDeps.analytics.send(Event.analyticsCollectionEnabled(status: true));
            }
            toolContext.logger.printStatus('Analytics reporting enabled.');
          }

          await runner.run(args);

          // Triggering [runZoned]'s error callback does not necessarily mean that
          // we stopped executing the body. See https://github.com/dart-lang/sdk/issues/42150.
          if (firstError == null) {
            return await exitWithHooks(
              0,
              shutdownHooks: shutdownHooks,
              analytics: toolDeps.analytics,
              logger: toolContext.logger,
            );
          }

          // We already hit some error, so don't return success. The error path
          // (which should be in progress) is responsible for calling _exit().
          return 1;
          // This catches all exceptions to send to crash logging, etc.
          // ignore: avoid_catches_without_on_clauses
        } catch (error, stackTrace) {
          firstError = error;
          firstStackTrace = stackTrace;
          return _handleToolError(
            error,
            stackTrace,
            verbose,
            args,
            reportCrashes!,
            getVersion,
            shutdownHooks,
            featureFlags: featureFlags,
            usingLocalEngine: usingLocalEngine,
            toolContext: toolContext,
            analytics: toolDeps.analytics,
            crashReporter: toolDeps.crashReporter,
          );
        }
      },
      (Object error, StackTrace stackTrace) async {
        // If sending a crash report throws an error into the zone, we don't want
        // to re-try sending the crash report with *that* error. Rather, we want
        // to send the original error that triggered the crash report.
        firstError ??= error;
        firstStackTrace ??= stackTrace;
        await _handleToolError(
          firstError!,
          firstStackTrace,
          verbose,
          args,
          reportCrashes!,
          getVersion,
          shutdownHooks,
          featureFlags: featureFlags,
          usingLocalEngine: usingLocalEngine,
          toolContext: toolContext,
          analytics: toolDeps.analytics,
          crashReporter: toolDeps.crashReporter,
        );
      },
    )!;
  }, overrides: contextOverrides);
}

/// Track if we're actively processing an error so we don't try and process
/// additional asynchronous exceptions while we're trying to shut down.
///
/// NOTE: This state is cleared at the beginning of [run] to ensure state
/// doesn't leak when running tests.
Future<int>? _alreadyHandlingToolError;

Future<int> _handleToolError(
  Object error,
  StackTrace? stackTrace,
  bool verbose,
  List<String> args,
  bool reportCrashes,
  String Function() getFlutterVersion,
  ShutdownHooks shutdownHooks, {
  required bool usingLocalEngine,
  required FeatureFlags featureFlags,
  required ToolContext toolContext,
  required Analytics analytics,
  required CrashReporter crashReporter,
}) async {
  return _alreadyHandlingToolError ??= _handleToolErrorImpl(
    error,
    stackTrace,
    verbose,
    args,
    reportCrashes,
    getFlutterVersion,
    shutdownHooks,
    usingLocalEngine: usingLocalEngine,
    featureFlags: featureFlags,
    toolContext: toolContext,
    analytics: analytics,
    crashReporter: crashReporter,
  );
}

Future<int> _handleToolErrorImpl(
  Object error,
  StackTrace? stackTrace,
  bool verbose,
  List<String> args,
  bool reportCrashes,
  String Function() getFlutterVersion,
  ShutdownHooks shutdownHooks, {
  required bool usingLocalEngine,
  required FeatureFlags featureFlags,
  required ToolContext toolContext,
  required Analytics analytics,
  required CrashReporter crashReporter,
}) async {
  if (error is UsageException) {
    toolContext.logger.printError('${error.message}\n');
    toolContext.logger.printError(
      "Run 'flutter -h' (or 'flutter <command> -h') for available flutter commands and options.",
    );
    // Argument error exit code.
    return exitWithHooks(
      64,
      shutdownHooks: shutdownHooks,
      analytics: analytics,
      logger: toolContext.logger,
    );
  } else if (error is ToolExit) {
    if (error.message != null) {
      toolContext.logger.printError(error.message!);
    }
    if (verbose) {
      toolContext.logger.printError('\n$stackTrace\n');
    }
    return exitWithHooks(
      error.exitCode ?? 1,
      shutdownHooks: shutdownHooks,
      analytics: analytics,
      logger: toolContext.logger,
    );
  } else if (error is ProcessExit) {
    // We've caught an exit code.
    if (error.immediate) {
      exit(error.exitCode);
      return error.exitCode;
    } else {
      return exitWithHooks(
        error.exitCode,
        shutdownHooks: shutdownHooks,
        analytics: analytics,
        logger: toolContext.logger,
      );
    }
  } else if (error is ProcessException &&
      _isErrorDueToGitMissing(error, toolContext.processManager, toolContext.logger)) {
    toolContext.logger.printError('${error.message}\n');
    toolContext.logger.printError(
      'An error was encountered when trying to run git.\n'
      "Please ensure git is installed and available in your system's search path. "
      'See https://docs.flutter.dev/get-started for instructions on '
      'installing git for your platform.',
    );
    return exitWithHooks(
      1,
      shutdownHooks: shutdownHooks,
      analytics: analytics,
      logger: toolContext.logger,
    );
  } else {
    // We've crashed; emit a log report.
    toolContext.stdio.stderrWrite('\n');
    if (!reportCrashes) {
      // Print the stack trace on the bots - don't write a crash report.
      toolContext.stdio.stderrWrite('$error\n');
      toolContext.stdio.stderrWrite('$stackTrace\n');

      final String featureFlagsEnabled = allConfigurableFeatures
          .where(featureFlags.isEnabled)
          .map((Feature f) => f.configSetting)
          .join(', ');
      toolContext.stdio.stderrWrite('Feature flags enabled: $featureFlagsEnabled\n');
      return exitWithHooks(
        1,
        shutdownHooks: shutdownHooks,
        analytics: analytics,
        logger: toolContext.logger,
      );
    }

    // Flutter tool crash analytics benefits from the concrete Dart error type.
    // The tool is not obfuscated, and collapsing unknown types to Object loses useful signal.
    // ignore: avoid_type_to_string
    analytics.send(Event.exception(exception: error.runtimeType.toString()));

    if (!usingLocalEngine) {
      await asyncGuard(
        () async {
          final crashReportSender = CrashReportSender(
            platform: toolContext.platform,
            logger: toolContext.logger,
            operatingSystemUtils: toolContext.os,
            analytics: analytics,
          );
          await crashReportSender.sendReport(
            error: error,
            stackTrace: stackTrace!,
            getFlutterVersion: getFlutterVersion,
            command: args.join(' '),
          );
        },
        onError: (dynamic error) {
          toolContext.logger.printError('Error sending crash report: $error');
        },
      );
    }

    toolContext.logger.printError('Oops; flutter has exited unexpectedly: "$error".');

    try {
      final logger = BufferLogger(
        terminal: toolContext.terminal,
        outputPreferences: toolContext.outputPreferences,
        verbose: true /* Capture flutter doctor -v */,
      );

      final doctorText = DoctorText(logger);

      final details = CrashDetails(
        command: _crashCommand(args),
        error: error,
        stackTrace: stackTrace!,
        doctorText: doctorText,
      );
      final File file = await _createLocalCrashReport(details, toolContext: toolContext);
      await crashReporter.informUser(details, file);

      return await exitWithHooks(
        1,
        shutdownHooks: shutdownHooks,
        analytics: analytics,
        logger: toolContext.logger,
      );
      // This catch catches all exceptions to ensure the message below is printed.
      // ignore: avoid_catches_without_on_clauses
    } catch (error, st) {
      toolContext.stdio.stderrWrite(
        'Unable to generate crash report due to secondary error: $error\n$st\n'
        '${toolContext.userMessages.flutterToolBugInstructions}\n',
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
Future<File> _createLocalCrashReport(
  CrashDetails details, {
  required ToolContext toolContext,
}) async {
  final buffer = StringBuffer();

  buffer.writeln('Flutter crash report.');
  buffer.writeln('${toolContext.userMessages.flutterToolBugInstructions}\n');

  buffer.writeln('## command\n');
  buffer.writeln('${details.command}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('${_crashException(details.error)}\n');
  buffer.writeln('```\n${details.stackTrace}```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${await details.doctorText.text}```');

  late File crashFile;
  ErrorHandlingFileSystem.noExitOnFailure(() {
    try {
      crashFile = toolContext.fileSystemUtils.getUniqueFile(
        toolContext.fs.currentDirectory,
        'flutter',
        'log',
      );
      crashFile.writeAsStringSync(buffer.toString());
    } on FileSystemException catch (_) {
      // Fallback to the system temporary directory.
      try {
        crashFile = toolContext.fileSystemUtils.getUniqueFile(
          toolContext.fs.systemTempDirectory,
          'flutter',
          'log',
        );
        crashFile.writeAsStringSync(buffer.toString());
      } on FileSystemException catch (e) {
        toolContext.logger.printError('Could not write crash report to disk: $e');
        toolContext.logger.printError(buffer.toString());

        rethrow;
      }
    }
  });

  return crashFile;
}

bool _isErrorDueToGitMissing(
  ProcessException exception,
  ProcessManager processManager,
  Logger logger,
) {
  if (!exception.message.contains('git')) {
    return false;
  }

  try {
    return !processManager.canRun('git');
  } on Object catch (error) {
    logger.printTrace('Unable to check whether git is runnable: $error\n');
    return true;
  }
}
