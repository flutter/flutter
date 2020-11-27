// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/src/constants.dart';

const String failureExcerpt = 'Expected: <true>';

dynamic isSuccess(String methodName) => isA<Success>()
  .having((Success s) => s.methodName, 'methodName', methodName);

dynamic isFailure(String methodName) => isA<Failure>()
  .having((Failure e) => e.methodName, 'methodName', methodName)
  .having((Failure e) => e.error.toString(), 'error', contains(failureExcerpt));


Future<List<TestResult>> runAndCollectResults(
  FutureOr<void> Function() testMain,
) async {
  final _TestReporter reporter = _TestReporter();
  await run(testMain, reporter: reporter);
  return reporter.results;
}

class _TestReporter implements Reporter {
  final Completer<List<TestResult>> _resultsCompleter = Completer<List<TestResult>>();
  Future<List<TestResult>> get results => _resultsCompleter.future;

  @override
  Future<void> report(List<TestResult> results) async => _resultsCompleter.complete(results);
}

String testResultsToJson(Map<String, TestResult> results) {
  return jsonEncode(<String, Object>{
    for (TestResult result in results.values)
      result.methodName: result is Failure ? result : success
  });
}
