// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

const _numTrials = 100;
const _formatsPerTrial = 30;

/// Note, these files use ".txt" because while they can be *parsed* correctly,
/// they don't resolve without error. That's OK because the formatter doesn't
/// care about that.
final source = loadFile('before.dart.txt');
final expected = loadFile('after.dart.txt');

void main(List<String> args) {
  var best = 99999999.0;

  // Run the benchmark several times. This ensures the VM is warmed up and lets
  // us see how much variance there is.
  for (var i = 0; i <= _numTrials; i++) {
    var start = DateTime.now();

    // For a single benchmark, format the source multiple times.
    String? result;
    for (var j = 0; j < _formatsPerTrial; j++) {
      result = formatSource();
    }

    var elapsed =
        DateTime.now().difference(start).inMilliseconds / _formatsPerTrial;

    // Keep track of the best run so far.
    if (elapsed >= best) continue;
    best = elapsed;

    // Sanity check to make sure the output is what we expect and to make sure
    // the VM doesn't optimize "dead" code away.
    if (result != expected) {
      print('Incorrect output:\n$result');
      exit(1);
    }

    // Don't print the first run. It's always terrible since the VM hasn't
    // warmed up yet.
    if (i == 0) continue;
    printResult("Run ${padLeft('#$i', 3)}", elapsed);
  }

  printResult('Best   ', best);
}

String loadFile(String name) {
  var path = p.join(p.dirname(p.fromUri(Platform.script)), name);
  return File(path).readAsStringSync();
}

void printResult(String label, double time) {
  print('$label: ${padLeft(time.toStringAsFixed(2), 4)}ms '
      "${'=' * ((time * 5).toInt())}");
}

String padLeft(input, int length) {
  var result = input.toString();
  if (result.length < length) {
    result = ' ' * (length - result.length) + result;
  }

  return result;
}

String formatSource() {
  var formatter = DartFormatter();
  return formatter.format(source);
}
