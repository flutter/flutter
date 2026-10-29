// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/skip_test_comments.dart';
import 'package:test/test.dart';

class SkipTestCommentsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(SkipTestComments());
    super.setUp();
  }

  @override
  String get analysisRule => SkipTestComments.code.name;
}

const String _source = '''
void test(String name, void Function() body, {bool skip = false}) {}

void main() {
  test('a test', () {}, skip: true); // ERROR
}
''';

void main() {
  late SkipTestCommentsTest testSuite;

  setUp(() {
    testSuite = SkipTestCommentsTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('skip test comments', () async {
    await testSuite.assertDiagnostics(_source, [
      testSuite.lint(108, 10), // skip: true
    ]);
  });
}
