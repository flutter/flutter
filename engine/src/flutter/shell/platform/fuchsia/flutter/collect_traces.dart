// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.9

import 'dart:io';
import 'dart:convert';

bool includeFunction(String function) {
  return function.startsWith("dart:") ||
         function.startsWith("package:flutter/") ||
         function.startsWith("package:vector_math/");
}

main(List<String> args) async {
  if (args.length != 1) {
    print("Usage:\n"
          " fx syslog | dart topaz/runtime/flutter_runner/collect_traces.dart output.txt");
    exitCode = 1;
    return;
  }

  var functionCounts = Map<String, int>();

  ProcessSignal.sigint.watch().listen((_) {
    var functions = List<String>();
    // TODO(flutter): Investigate consensus functions to avoid bloat.
    var minimumCount = 1;
    functionCounts.forEach((String function, int count) {
      if (count >= minimumCount) {
        functions.add(function);
      }
    });

    functions.sort();

    var sb = StringBuffer();
    for (var function in functions) {
      sb.writeln(function);
    }

    File(args[0]).writeAsString(sb.toString(), flush: true).then((_) { exit(0); });
  });

  final stdinAsLines = LineSplitter().bind(Utf8Decoder().bind(stdin));
  await for (final line in stdinAsLines) {
    final marker = "compilation-trace: ";
    final markerPosition = line.indexOf(marker);
    if (markerPosition == -1) {
      continue;
    }

    final function = line.substring(markerPosition + marker.length);
    if (!includeFunction(function)) {
      continue;
    }
    print(function);

    var count = functionCounts[function];
    if (count == null) {
      count = 1;
    } else {
      count++;
    }
    functionCounts[function] = count;
  }
}
