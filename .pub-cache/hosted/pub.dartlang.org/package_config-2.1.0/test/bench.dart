// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:package_config/src/package_config_json.dart';

void throwError(Object error) => throw error;

void bench(final int size, final bool doPrint) {
  var sb = StringBuffer();
  sb.writeln('{');
  sb.writeln('"configVersion": 2,');
  sb.writeln('"packages": [');
  for (var i = 0; i < size; i++) {
    if (i != 0) {
      sb.writeln(',');
    }
    sb.writeln('{');
    sb.writeln('  "name": "p_$i",');
    sb.writeln('  "rootUri": "file:///p_$i/",');
    sb.writeln('  "packageUri": "lib/",');
    sb.writeln('  "languageVersion": "2.5",');
    sb.writeln('  "nonstandard": true');
    sb.writeln('}');
  }
  sb.writeln('],');
  sb.writeln('"generator": "pub",');
  sb.writeln('"other": [42]');
  sb.writeln('}');
  var stopwatch = Stopwatch()..start();
  var config = parsePackageConfigBytes(
      // ignore: unnecessary_cast
      utf8.encode(sb.toString()) as Uint8List,
      Uri.parse('file:///tmp/.dart_tool/file.dart'),
      throwError);
  final int read = stopwatch.elapsedMilliseconds;

  stopwatch.reset();
  for (var i = 0; i < size; i++) {
    if (config.packageOf(Uri.parse('file:///p_$i/lib/src/foo.dart'))!.name !=
        'p_$i') {
      throw "Unexpected result!";
    }
  }
  final int lookup = stopwatch.elapsedMilliseconds;

  if (doPrint) {
    print('Read file with $size packages in $read ms, '
        'looked up all packages in $lookup ms');
  }
}

void main(List<String> args) {
  if (args.length != 1 && args.length != 2) {
    throw "Expects arguments: <size> <warmup iterations>?";
  }
  final size = int.parse(args[0]);
  if (args.length > 1) {
    final warmups = int.parse(args[1]);
    print("Performing $warmups warmup iterations.");
    for (var i = 0; i < warmups; i++) {
      bench(10, false);
    }
  }

  // Benchmark.
  bench(size, true);
}
