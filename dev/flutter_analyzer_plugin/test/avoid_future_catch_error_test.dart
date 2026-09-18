// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/avoid_future_catch_error.dart';
import 'package:test/test.dart';

class AvoidFutureCatchErrorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(AvoidFutureCatchError());
    super.setUp();
  }

  @override
  String get analysisRule => AvoidFutureCatchError.code.name;
}

const String _source = '''
import 'dart:async';

// This extension isn't picked up from dart:async, so we just fake it.
extension MyFutureExtension<T> on Future<T> {
  Future<T> onError<E extends Object>(
    FutureOr<T> handleError(E error, StackTrace stackTrace), {
    bool test(E error)?,
  }) {
    return this;
  }
}

void main() {
  Future<void>.value().catchError((e, st) => null); // ERROR
  Future<void>.value().onError((e, st) => null); // ERROR
  Future<void>.value().then((_) => null, onError: (e, st) => null); // OK
}
''';

void main() {
  late AvoidFutureCatchErrorTest testSuite;

  setUp(() {
    testSuite = AvoidFutureCatchErrorTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('avoid future catch error', () async {
    await testSuite.assertDiagnostics(_source, <ExpectedDiagnostic>[
      testSuite.lint(313, 48),
      testSuite.lint(374, 45),
    ]);
  });
}
