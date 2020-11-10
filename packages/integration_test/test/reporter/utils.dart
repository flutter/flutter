// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/src/constants.dart';

const String _failureExcerpt = 'Expected: <true>';

bool isFailure(Object object) {
  if (object is! Failure) {
    return false;
  }
  final Failure failure = object as Failure;
  return failure.error.toString().contains(_failureExcerpt);
}

bool isSerializedFailure(dynamic object) =>
    object.toString().contains(_failureExcerpt);

bool isSuccess(Object object) => object == success;

Future<Map<String, Object>> runAndCollectResults(
  FutureOr<void> Function() testMain,
) async {
  final _TestReporter reporter = _TestReporter();
  await run(testMain, reporter: reporter);
  return reporter.results;
}

class _TestReporter implements Reporter {
  final Completer<Map<String, Object>> _resultsCompleter = Completer<Map<String, Object>>();
  Future<Map<String, Object>> get results => _resultsCompleter.future;

  @override
  Future<void> report(Map<String, Object> results) async => _resultsCompleter.complete(results);
}
