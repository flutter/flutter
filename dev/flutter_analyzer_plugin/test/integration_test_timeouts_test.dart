// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/integration_test_timeouts.dart';
import 'package:test/test.dart';

class IntegrationTestTimeoutsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(IntegrationTestTimeouts());
    super.setUp();
  }

  @override
  String get testPackageLibPath => '$testPackageRootPath/test_driver';

  @override
  String get analysisRule => IntegrationTestTimeouts.code.name;
}

const String _source = '''
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

void main() {
  late IntegrationTestTimeoutsTest testSuite;

  setUp(() {
    testSuite = IntegrationTestTimeoutsTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('integration test timeouts', () async {
    await testSuite.assertDiagnostics(_source, [testSuite.lint(163, 4)]);
  });
}
