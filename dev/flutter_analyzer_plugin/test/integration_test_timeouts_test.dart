// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/integration_test_timeouts.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class IntegrationTestTimeoutsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(IntegrationTestTimeouts());
    super.setUp();
  }

  @override
  String get analysisRule => IntegrationTestTimeouts.code.name;

  static const String source = '''
class Timeout {
  static const Timeout none = Timeout();
  const Timeout();
}
void test(String name, void Function() body, {Timeout? timeout}) {}

void main() {
  test('a test without timeout', () {}); // ERROR

  test('a test with timeout', () {}, timeout: Timeout.none); // OK
}
''';

  Future<void> testIntegrationTestTimeouts() async {
    await assertDiagnostics(source, [
      lint(158, 4),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IntegrationTestTimeoutsTest);
  });
}
