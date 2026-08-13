// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/skip_test_comments.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
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

  // ignore: non_constant_identifier_names
  Future<void> test_skip_test_comments() async {
    await assertDiagnostics(source, [
      lint(108, 10), // skip: true
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SkipTestCommentsTest);
  });
}
