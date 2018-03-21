// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<Null> main() async {
  await task(() async {
    final Stopwatch clock = new Stopwatch()..start();
    final Process analysis = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['analyze', '--no-preamble', '--no-congratulate', '--flutter-repo', '--dartdocs'],
      workingDirectory: flutterDirectory.path,
    );
    int publicMembers = 0;
    int otherErrors = 0;
    int otherLines = 0;
    await for (String entry in analysis.stderr.transform(utf8.decoder).transform(const LineSplitter())) {
      print('analyzer stderr: $entry');
      if (entry.startsWith('[lint] Document all public members')) {
        publicMembers += 1;
      } else if (entry.startsWith('[')) {
        otherErrors += 1;
      } else if (entry.startsWith('(Ran in ')) {
        // ignore this line
      } else {
        otherLines += 1;
      }
    }
    await for (String entry in analysis.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      print('analyzer stdout: $entry');
      if (entry == 'Building flutter tool...') {
        // ignore this line
      } else {
        otherLines += 1;
      }
    }
    final int result = await analysis.exitCode;
    clock.stop();
    if (publicMembers == 0 && otherErrors == 0 && result != 0)
      throw new Exception('flutter analyze exited with unexpected error code $result');
    if (publicMembers != 0 && otherErrors != 0 && result == 0)
      throw new Exception('flutter analyze exited with successful status code despite reporting errors');
    if (otherLines != 0)
      throw new Exception('flutter analyze had unexpected output (we saw $otherLines unexpected line${ otherLines == 1 ? "" : "s" })');
    final Map<String, dynamic> data = <String, dynamic>{
      'members_missing_dartdocs': publicMembers,
      'analysis_errors': otherErrors,
      'elapsed_time_ms': clock.elapsedMilliseconds,
    };
    return new TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
  });
}
