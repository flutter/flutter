// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Reads through the print commands from [process] waiting for the magic phase
/// that contains microbenchmarks results as defined in
/// `dev/benchmarks/microbenchmarks/lib/common.dart`.
Future<Map<String, double>> readJsonResults(Process process) {
  // IMPORTANT: keep these values in sync with dev/benchmarks/microbenchmarks/lib/common.dart
  const String jsonStart = '================ RESULTS ================';
  const String jsonEnd = '================ FORMATTED ==============';
  const String jsonPrefix = ':::JSON:::';
  bool jsonStarted = false;
  final StringBuffer jsonBuf = StringBuffer();
  final Completer<Map<String, double>> completer = Completer<Map<String, double>>();

  final StreamSubscription<String> stderrSub = process.stderr
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) {
        stderr.writeln('[STDERR] $line');
      });

  bool processWasKilledIntentionally = false;
  bool resultsHaveBeenParsed = false;
  final StreamSubscription<String> stdoutSub = process.stdout
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) async {
    print('[STDOUT] $line');

    if (line.contains(jsonStart)) {
      jsonStarted = true;
      return;
    }

    if (jsonStarted && line.contains(jsonEnd)) {
      final String jsonOutput = jsonBuf.toString();

      // If we end up here and have already parsed the results, it suggests that
      // we have received output from another test because our `flutter run`
      // process did not terminate correctly.
      // https://github.com/flutter/flutter/issues/19096#issuecomment-402756549
      if (resultsHaveBeenParsed) {
        throw 'Additional JSON was received after results has already been '
              'processed. This suggests the `flutter run` process may have lived '
              'past the end of our test and collected additional output from the '
              'next test.\n\n'
              'The JSON below contains all collected output, including both from '
              'the original test and what followed.\n\n'
              '$jsonOutput';
      }

      jsonStarted = false;
      processWasKilledIntentionally = true;
      resultsHaveBeenParsed = true;
      // Sending a SIGINT/SIGTERM to the process here isn't reliable because [process] is
      // the shell (flutter is a shell script) and doesn't pass the signal on.
      // Sending a `q` is an instruction to quit using the console runner.
      // See https://github.com/flutter/flutter/issues/19208
      process.stdin.write('q');
      await process.stdin.flush();
      // Also send a kill signal in case the `q` above didn't work.
      process.kill(ProcessSignal.sigint);
      try {
        completer.complete(Map<String, double>.from(json.decode(jsonOutput) as Map<String, dynamic>));
      } catch (ex) {
        completer.completeError('Decoding JSON failed ($ex). JSON string was: $jsonOutput');
      }
      return;
    }

    if (jsonStarted && line.contains(jsonPrefix)) {
      jsonBuf.writeln(line.substring(line.indexOf(jsonPrefix) + jsonPrefix.length));
    }
  });

  process.exitCode.then<void>((int code) async {
    await Future.wait<void>(<Future<void>>[
      stdoutSub.cancel(),
      stderrSub.cancel(),
    ]);
    if (!processWasKilledIntentionally && code != 0) {
      completer.completeError('flutter run failed: exit code=$code');
    }
  });

  return completer.future;
}
