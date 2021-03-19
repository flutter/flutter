// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  final String dot = Platform.isWindows ? '-' : '•';
  await flutter('update-packages');
  await task(() async {
    final Stopwatch clock = Stopwatch()..start();
    final Process analysis = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['analyze', '--no-preamble', '--flutter-repo', '--dartdocs'],
      workingDirectory: flutterDirectory.path,
    );
    int publicMembers = 0;
    int otherErrors = 0;
    int otherLines = 0;
    bool sawFinalLine = false;
    await for (String entry in analysis.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter())) {
      entry = entry.trim();
      print('analyzer stdout: $entry');
      if (entry == 'Building flutter tool...') {
        // ignore this line
      } else if (entry.startsWith('info $dot Document all public members $dot')) {
        publicMembers += 1;
      } else if (entry.startsWith('info $dot') || entry.startsWith('warning $dot') || entry.startsWith('error $dot')) {
        otherErrors += 1;
      } else if (entry.contains(' (ran in ') && !sawFinalLine) {
        // ignore this line once
        sawFinalLine = true;
      } else if (entry.isNotEmpty) {
        otherLines += 1;
        print('^ not sure what to do with that line ^');
      }
    }
    await for (final String entry in analysis.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter())) {
      print('analyzer stderr: $entry');
      if (entry.contains(' (ran in ') && !sawFinalLine) {
        // ignore this line once
        sawFinalLine = true;
      } else {
        otherLines += 1;
        print('^ not sure what to do with that line ^');
      }
    }
    final int result = await analysis.exitCode;
    clock.stop();
    if (!sawFinalLine)
      throw Exception('flutter analyze did not output final message');
    if (publicMembers == 0 && otherErrors == 0 && result != 0)
      throw Exception('flutter analyze exited with unexpected error code $result');
    if (publicMembers != 0 && otherErrors != 0 && result == 0)
      throw Exception('flutter analyze exited with successful status code despite reporting errors');
    if (otherLines != 0)
      throw Exception('flutter analyze had unexpected output (we saw $otherLines unexpected line${ otherLines == 1 ? "" : "s" })');
    final Map<String, dynamic> data = <String, dynamic>{
      'members_missing_dartdocs': publicMembers,
      'analysis_errors': otherErrors,
      'elapsed_time_ms': clock.elapsedMilliseconds,
    };
    return TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
  });
}
