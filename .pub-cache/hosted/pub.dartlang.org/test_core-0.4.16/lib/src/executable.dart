// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test_api/src/backend/util/pretty_print.dart'; // ignore: implementation_imports
import 'package:test_core/src/runner/no_tests_found_exception.dart';

import 'runner.dart';
import 'runner/application_exception.dart';
import 'runner/configuration.dart';
import 'runner/version.dart';
import 'util/errors.dart';
import 'util/exit_codes.dart' as exit_codes;
import 'util/io.dart';

StreamSubscription? signalSubscription;
bool isShutdown = false;

/// Returns the path to the global test configuration file.
final String _globalConfigPath = () {
  if (Platform.environment.containsKey('DART_TEST_CONFIG')) {
    return Platform.environment['DART_TEST_CONFIG']!;
  } else if (Platform.operatingSystem == 'windows') {
    return p.join(Platform.environment['LOCALAPPDATA']!, 'DartTest.yaml');
  } else {
    return '${Platform.environment['HOME']}/.dart_test.yaml';
  }
}();

Future<void> main(List<String> args) async {
  await _execute(args);
  completeShutdown();
}

Future<void> runTests(List<String> args) async {
  await _execute(args);
}

void completeShutdown() {
  if (isShutdown) return;
  if (signalSubscription != null) {
    signalSubscription!.cancel();
    signalSubscription = null;
  }
  isShutdown = true;
  cancelStdinLines();
}

Future<void> _execute(List<String> args) async {
  /// A merged stream of all signals that tell the test runner to shut down
  /// gracefully.
  ///
  /// Signals will only be captured as long as this has an active subscription.
  /// Otherwise, they'll be handled by Dart's default signal handler, which
  /// terminates the program immediately.
  final signals = Platform.isWindows
      ? ProcessSignal.sigint.watch()
      : Platform.isFuchsia // Signals don't exist on Fuchsia.
          ? Stream.empty()
          : StreamGroup.merge(
              [ProcessSignal.sigterm.watch(), ProcessSignal.sigint.watch()]);

  Configuration configuration;
  try {
    configuration = Configuration.parse(args);
  } on FormatException catch (error) {
    _printUsage(error.message);
    exitCode = exit_codes.usage;
    return;
  }

  if (configuration.help) {
    _printUsage();
    return;
  }

  if (configuration.version) {
    var version = testVersion;
    if (version == null) {
      stderr.writeln("Couldn't find version number.");
      exitCode = exit_codes.data;
    } else {
      print(version);
    }
    return;
  }

  try {
    var fileConfiguration = Configuration.empty;
    if (File(_globalConfigPath).existsSync()) {
      fileConfiguration = fileConfiguration
          .merge(Configuration.load(_globalConfigPath, global: true));
    }

    if (File(configuration.configurationPath).existsSync()) {
      fileConfiguration = fileConfiguration
          .merge(Configuration.load(configuration.configurationPath));
    }

    configuration = fileConfiguration.merge(configuration);
  } on SourceSpanFormatException catch (error) {
    stderr.writeln(error.toString(color: configuration.color));
    exitCode = exit_codes.data;
    return;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = exit_codes.data;
    return;
  } on IOException catch (error) {
    stderr.writeln(error.toString());
    exitCode = exit_codes.noInput;
    return;
  }

  var undefinedPresets = configuration.chosenPresets
      .where((preset) => !configuration.knownPresets.contains(preset))
      .toList();
  if (undefinedPresets.isNotEmpty) {
    _printUsage("Undefined ${pluralize('preset', undefinedPresets.length)} "
        "${toSentence(undefinedPresets.map((preset) => '"$preset"'))}.");
    exitCode = exit_codes.usage;
    return;
  }

  if (!configuration.explicitPaths &&
      !Directory(configuration.paths.single.testPath).existsSync()) {
    _printUsage('No test files were passed and the default "test/" '
        "directory doesn't exist.");
    exitCode = exit_codes.data;
    return;
  }

  Runner? runner;

  signalSubscription ??= signals.listen((signal) async {
    completeShutdown();
    await runner?.close();
  });

  try {
    runner = Runner(configuration);
    exitCode = (await runner.run()) ? 0 : 1;
  } on ApplicationException catch (error) {
    stderr.writeln(error.message);
    exitCode = exit_codes.data;
  } on SourceSpanFormatException catch (error) {
    stderr.writeln(error.toString(color: configuration.color));
    exitCode = exit_codes.data;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = exit_codes.data;
  } on NoTestsFoundException catch (error) {
    stderr.writeln(error.message);
    exitCode = exit_codes.noTestsRan;
  } catch (error, stackTrace) {
    stderr.writeln(getErrorMessage(error));
    stderr.writeln(Trace.from(stackTrace).terse);
    stderr.writeln('This is an unexpected error. Please file an issue at '
        'http://github.com/dart-lang/test\n'
        'with the stack trace and instructions for reproducing the error.');
    exitCode = exit_codes.software;
  } finally {
    await runner?.close();
  }

  return;
}

/// Print usage information for this command.
///
/// If [error] is passed, it's used in place of the usage message and the whole
/// thing is printed to stderr instead of stdout.
void _printUsage([String? error]) {
  var output = stdout;

  var message = 'Runs tests in this package.';
  if (error != null) {
    message = error;
    output = stderr;
  }

  output.write('''${wordWrap(message)}

Usage: dart test [files or directories...]

${Configuration.usage}
''');
}
