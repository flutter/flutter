// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../globals.dart';

/// Common behavior for `flutter analyze` and `flutter analyze --watch`
abstract class AnalyzeBase {
  /// The parsed argument results for execution.
  final ArgResults argResults;

  AnalyzeBase(this.argResults);

  /// Called by [AnalyzeCommand] to start the analysis process.
  Future<Null> analyze();

  void dumpErrors(Iterable<String> errors) {
    if (argResults['write'] != null) {
      try {
        final RandomAccessFile resultsFile = fs.file(argResults['write']).openSync(mode: FileMode.WRITE);
        try {
          resultsFile.lockSync();
          resultsFile.writeStringSync(errors.join('\n'));
        } finally {
          resultsFile.close();
        }
      } catch (e) {
        printError('Failed to save output to "${argResults['write']}": $e');
      }
    }
  }

  void writeBenchmark(Stopwatch stopwatch, int errorCount, int membersMissingDocumentation) {
    final String benchmarkOut = 'analysis_benchmark.json';
    Map<String, dynamic> data = <String, dynamic>{
      'time': (stopwatch.elapsedMilliseconds / 1000.0),
      'issues': errorCount,
      'missingDartDocs': membersMissingDocumentation
    };
    fs.file(benchmarkOut).writeAsStringSync(toPrettyJson(data));
    printStatus('Analysis benchmark written to $benchmarkOut ($data).');
  }

  bool get isBenchmarking => argResults['benchmark'];
}

/// Return `true` if [fileList] contains a path that resides inside the Flutter repository.
/// If [fileList] is empty, then return `true` if the current directory resides inside the Flutter repository.
bool inRepo(List<String> fileList) {
  if (fileList == null || fileList.isEmpty)
    fileList = <String>[path.current];
  String root = path.normalize(path.absolute(Cache.flutterRoot));
  String prefix = root + fs.pathSeparator;
  for (String file in fileList) {
    file = path.normalize(path.absolute(file));
    if (file == root || file.startsWith(prefix))
      return true;
  }
  return false;
}
