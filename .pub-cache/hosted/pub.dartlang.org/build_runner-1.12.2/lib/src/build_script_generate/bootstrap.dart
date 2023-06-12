// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:build_runner/src/build_script_generate/build_script_generate.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

final _logger = Logger('Bootstrap');

/// Generates the build script, snapshots it if needed, and runs it.
///
/// The [handleUncaughtError] function will be invoked when the build script
/// terminates with an uncaught error.
///
/// Will retry once on [IsolateSpawnException]s to handle SDK updates.
///
/// Returns the exit code from running the build script.
///
/// If an exit code of 75 is returned, this function should be re-ran.
Future<int> generateAndRun(
  List<String> args, {
  Logger logger,
  Future<String> Function() generateBuildScript = generateBuildScript,
  void Function(Object error, StackTrace stackTrace) handleUncaughtError,
}) async {
  logger ??= _logger;
  handleUncaughtError ??= (error, stackTrace) {
    stderr
      ..writeln('\n\nYou have hit a bug in build_runner')
      ..writeln('Please file an issue with reproduction steps at '
          'https://github.com/dart-lang/build/issues\n\n')
      ..writeln(error)
      ..writeln(stackTrace);
  };
  ReceivePort exitPort;
  ReceivePort errorPort;
  ReceivePort messagePort;
  StreamSubscription errorListener;
  int scriptExitCode;

  var tryCount = 0;
  var succeeded = false;
  while (tryCount < 2 && !succeeded) {
    tryCount++;
    exitPort?.close();
    errorPort?.close();
    messagePort?.close();
    await errorListener?.cancel();

    try {
      var buildScript = File(scriptLocation);
      var oldContents = '';
      if (buildScript.existsSync()) {
        oldContents = buildScript.readAsStringSync();
      }
      var newContents = await generateBuildScript();
      // Only trigger a build script update if necessary.
      if (newContents != oldContents) {
        buildScript
          ..createSync(recursive: true)
          ..writeAsStringSync(newContents);
      }
    } on CannotBuildException {
      return ExitCode.config.code;
    }

    scriptExitCode = await _createSnapshotIfNeeded(logger);
    if (scriptExitCode != 0) return scriptExitCode;

    exitPort = ReceivePort();
    errorPort = ReceivePort();
    messagePort = ReceivePort();
    errorListener = errorPort.listen((e) {
      final error = e[0];
      final trace = Trace.parse(e[1] as String).terse;

      handleUncaughtError(error, trace);
      if (scriptExitCode == 0) scriptExitCode = 1;
    });
    try {
      await Isolate.spawnUri(Uri.file(p.absolute(scriptSnapshotLocation)), args,
          messagePort.sendPort,
          errorsAreFatal: true,
          onExit: exitPort.sendPort,
          onError: errorPort.sendPort);
      succeeded = true;
    } on IsolateSpawnException catch (e) {
      if (tryCount > 1) {
        logger.severe(
            'Failed to spawn build script after retry. '
            'This is likely due to a misconfigured builder definition. '
            'See the generated script at $scriptLocation to find errors.',
            e);
        messagePort.sendPort.send(ExitCode.config.code);
        exitPort.sendPort.send(null);
      } else {
        logger.warning(
            'Error spawning build script isolate, this is likely due to a Dart '
            'SDK update. Deleting snapshot and retrying...');
      }
      await File(scriptSnapshotLocation).delete();
    }
  }

  StreamSubscription exitCodeListener;
  exitCodeListener = messagePort.listen((isolateExitCode) {
    if (isolateExitCode is int) {
      scriptExitCode = isolateExitCode;
    } else {
      throw StateError(
          'Bad response from isolate, expected an exit code but got '
          '$isolateExitCode');
    }
    exitCodeListener.cancel();
    exitCodeListener = null;
  });
  await exitPort.first;
  await errorListener.cancel();
  await exitCodeListener?.cancel();

  return scriptExitCode;
}

/// Creates a script snapshot for the build script in necessary.
///
/// A snapshot is generated if:
///
/// - It doesn't exist currently
/// - Either build_runner or build_daemon point at a different location than
///   they used to, see https://github.com/dart-lang/build/issues/1929.
///
/// Returns zero for success or a number for failure which should be set to the
/// exit code.
Future<int> _createSnapshotIfNeeded(Logger logger) async {
  var assetGraphFile = File(assetGraphPathFor(scriptSnapshotLocation));
  var snapshotFile = File(scriptSnapshotLocation);

  if (await snapshotFile.exists()) {
    // If we failed to serialize an asset graph for the snapshot, then we don't
    // want to re-use it because we can't check if it is up to date.
    if (!await assetGraphFile.exists()) {
      await snapshotFile.delete();
      logger.warning('Deleted previous snapshot due to missing asset graph.');
    } else if (!await _checkImportantPackageDeps()) {
      await snapshotFile.delete();
      logger.warning('Deleted previous snapshot due to core package update');
    }
  }

  if (!await snapshotFile.exists()) {
    var mode = stdin.hasTerminal
        ? ProcessStartMode.normal
        : ProcessStartMode.detachedWithStdio;
    var hadStdOut = false;
    await logTimedAsync(logger, 'Creating build script snapshot...', () async {
      var snapshot = await Process.start(Platform.executable,
          ['--snapshot=$scriptSnapshotLocation', scriptLocation],
          mode: mode);
      await Future.wait([
        snapshot.stderr
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((l) {
          logger.warning('stderr: $l');
        }).asFuture(),
        snapshot.stdout
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((l) {
          hadStdOut = true;
          logger.fine('stdout: $l');
        }).asFuture(),
      ]);
    });
    if (hadStdOut) {
      logger.info('There was output on stdout while compiling the build script '
          'snapshot, run with `--verbose` to see it (you will need to run '
          'a `clean` first to re-snapshot).\n');
    }
    if (!await snapshotFile.exists()) {
      logger.severe('''
Failed to snapshot build script $scriptLocation.
This is likely caused by a misconfigured builder definition.
''');
      return ExitCode.config.code;
    }
    // Create _previousLocationsFile.
    await _checkImportantPackageDeps();
  }
  return 0;
}

const _importantPackages = [
  'build_daemon',
  'build_runner',
];
final _previousLocationsFile = File(
    p.url.join(p.url.dirname(scriptSnapshotLocation), '.packageLocations'));

/// Returns whether the [_importantPackages] are all pointing at same locations
/// from the previous run.
///
/// Also updates the [_previousLocationsFile] with the new locations if not.
///
/// This is used to detect potential changes to the user facing api and
/// pre-emptively resolve them by resnapshotting, see
/// https://github.com/dart-lang/build/issues/1929.
Future<bool> _checkImportantPackageDeps() async {
  var currentLocations = await Future.wait(_importantPackages.map((pkg) =>
      Isolate.resolvePackageUri(
          Uri(scheme: 'package', path: '$pkg/fake.dart'))));
  var currentLocationsContent = currentLocations.join('\n');

  if (!_previousLocationsFile.existsSync()) {
    _logger.fine('Core package locations file does not exist');
    _previousLocationsFile.writeAsStringSync(currentLocationsContent);
    return false;
  }

  if (currentLocationsContent != _previousLocationsFile.readAsStringSync()) {
    _logger.fine('Core packages locations have changed');
    _previousLocationsFile.writeAsStringSync(currentLocationsContent);
    return false;
  }

  return true;
}
