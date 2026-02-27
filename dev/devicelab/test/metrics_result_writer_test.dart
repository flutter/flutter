// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_devicelab/framework/metrics_result_writer.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

import 'common.dart';

void main() {
  late ProcessResult processResult;
  ProcessResult runSyncStub(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stderrEncoding,
    Encoding? stdoutEncoding,
    String? workingDirectory,
  }) => processResult;

  // Expected test values.
  const commitSha = 'a4952838bf288a81d8ea11edfd4b4cd649fa94cc';

  late MetricsResultWriter writer;
  late FileSystem fs;

  setUp(() {
    fs = MemoryFileSystem();
  });

  test('returns expected commit sha', () {
    processResult = ProcessResult(1, 0, commitSha, '');
    writer = MetricsResultWriter(fs: fs, processRunSync: runSyncStub);

    expect(writer.commitSha, commitSha);
  });

  test('throws exception on git cli errors', () {
    processResult = ProcessResult(1, 1, '', '');
    writer = MetricsResultWriter(fs: fs, processRunSync: runSyncStub);

    expect(() => writer.commitSha, throwsA(isA<CocoonException>()));
  });

  test('writes expected update task json', () async {
    processResult = ProcessResult(1, 0, commitSha, '');
    final result = TaskResult.fromJson(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'i': 0, 'j': 0, 'not_a_metric': 'something'},
      'benchmarkScoreKeys': <String>['i', 'j'],
    });

    writer = MetricsResultWriter(fs: fs, processRunSync: runSyncStub);

    const resultsPath = 'results.json';
    await writer.writeTaskResultToFile(
      builderName: 'builderAbc',
      gitBranch: 'master',
      result: result,
      resultsPath: resultsPath,
    );

    final String resultJson = fs.file(resultsPath).readAsStringSync();
    const expectedJson =
        '{'
        '"CommitBranch":"master",'
        '"CommitSha":"$commitSha",'
        '"BuilderName":"builderAbc",'
        '"NewStatus":"Succeeded",'
        '"ResultData":{"i":0.0,"j":0.0,"not_a_metric":"something"},'
        '"BenchmarkScoreKeys":["i","j"]}';
    expect(resultJson, expectedJson);
  });
}
