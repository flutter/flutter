// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_checked_mode.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NoCheckedModeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoCheckedMode());
    super.setUp();
  }

  @override
  String get analysisRule => NoCheckedMode.code.name;

  // ignore: non_constant_identifier_names
  Future<void> test_valid_code() async {
    const source = r'''
// This is a debug mode comment.
/// This documentation mentions debug mode.
void validFunction() {
  const String message = 'Running in debug mode';
  final String debugMode = 'debug mode';
  print('Status: $debugMode');
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_simple_string_literal() async {
    const source = '''
void test() {
  const String bad = 'This is checked mode.';
}
''';
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(35, 23)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_simple_string_literal_case_insensitive() async {
    const source = '''
void test() {
  const String bad = 'CHECKED MODE active';
}
''';
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(35, 21)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_interpolation_string() async {
    const source = r'''
void test(String value) {
  print('Value $value in checked mode');
}
''';
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(47, 17)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_doc_comment() async {
    const source = '''
/// Doc comment explaining checked mode.
void test() {}
''';
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(0, 40)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_multiline_doc_comment() async {
    const source = '''
/**
 * Explanation about checked mode.
 */
void test() {}
''';
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(0, 42)]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoCheckedModeTest);
  });
}
