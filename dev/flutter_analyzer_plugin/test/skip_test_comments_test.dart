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

  static const String source = '''
void test(String name, void Function() body, {bool skip = false}) {}

void main() {
  test('a test', () {}, skip: true); // ERROR
}
''';

  Future<void> testSkipTestComments() async {
    await assertDiagnostics(source, [
      lint(108, 10), // skip: true
    ]);
  }
}

void main() {
  late SkipTestCommentsTest testSuite;

  setUp(() {
    testSuite = SkipTestCommentsTest()..setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('skip_test_comments', () => testSuite.testSkipTestComments());
}
