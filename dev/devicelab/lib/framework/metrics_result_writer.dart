// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show Encoding, json;
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'task_result.dart';

/// Class for test runner to write device-lab metrics results for Skia Perf.
interface class MetricsResultWriter {
  MetricsResultWriter({
    @visibleForTesting this.fs = const LocalFileSystem(),
    @visibleForTesting this.processRunSync = Process.runSync,
  });

  final ProcessResult Function(
    String,
    List<String>, {
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding? stderrEncoding,
    Encoding? stdoutEncoding,
    String? workingDirectory,
  })
  processRunSync;

  /// Threshold to auto retry a failed test.
  static const int retryNumber = 2;

  /// Underlying [FileSystem] to use.
  final FileSystem fs;

  static final Logger logger = Logger('CocoonClient');

  String get commitSha => _commitSha ?? _readCommitSha();
  String? _commitSha;

  /// Parse the local repo for the current running commit.
  String _readCommitSha() {
    final ProcessResult result = processRunSync('git', <String>['rev-parse', 'HEAD']);
    if (result.exitCode != 0) {
      throw CocoonException(result.stderr as String);
    }

    return _commitSha = result.stdout as String;
  }

  /// Write the given parameters into an update task request and store the JSON in [resultsPath].
  Future<void> writeTaskResultToFile({
    String? builderName,
    String? gitBranch,
    required TaskResult result,
    required String resultsPath,
  }) async {
    final Map<String, dynamic> updateRequest = _constructUpdateRequest(
      gitBranch: gitBranch,
      builderName: builderName,
      result: result,
    );
    final File resultFile = fs.file(resultsPath);
    if (resultFile.existsSync()) {
      resultFile.deleteSync();
    }
    logger.fine('Writing results: ${json.encode(updateRequest)}');
    resultFile.createSync();
    resultFile.writeAsStringSync(json.encode(updateRequest));
  }

  Map<String, dynamic> _constructUpdateRequest({
    String? builderName,
    required TaskResult result,
    String? gitBranch,
  }) {
    final Map<String, dynamic> updateRequest = <String, dynamic>{
      'CommitBranch': gitBranch,
      'CommitSha': commitSha,
      'BuilderName': builderName,
      'NewStatus': result.succeeded ? 'Succeeded' : 'Failed',
    };
    logger.fine('Update request: $updateRequest');

    // Make a copy of result data because we may alter it for validation below.
    updateRequest['ResultData'] = result.data;

    final List<String> validScoreKeys = <String>[];
    if (result.benchmarkScoreKeys != null) {
      for (final String scoreKey in result.benchmarkScoreKeys!) {
        final Object score = result.data![scoreKey] as Object;
        if (score is num) {
          // Convert all metrics to double, which provide plenty of precision
          // without having to add support for multiple numeric types in Cocoon.
          result.data![scoreKey] = score.toDouble();
          validScoreKeys.add(scoreKey);
        }
      }
    }
    updateRequest['BenchmarkScoreKeys'] = validScoreKeys;

    return updateRequest;
  }
}

class CocoonException implements Exception {
  CocoonException(this.message);

  /// The message to show to the issuer to explain the error.
  final String message;

  @override
  String toString() => 'CocoonException: $message';
}
