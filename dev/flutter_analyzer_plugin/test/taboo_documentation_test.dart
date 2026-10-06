// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/taboo_documentation.dart';
import 'package:test/test.dart';

class TabooDocumentationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(TabooDocumentation());
    super.setUp();
  }

  @override
  String get analysisRule => TabooDocumentation.code.name;
}

void main() {
  late TabooDocumentationTest testSuite;

  setUp(() {
    testSuite = TabooDocumentationTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('valid doc comment', () async {
    const source = '''
/// This is a valid documentation comment.
/// It explains how the function works without taboo words.
void validFunction() {}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('non doc comments ignored', () async {
    const source = '''
// Simply do this.
// Note: this is a regular comment.
// Note that this is allowed in regular comments.
/*
 * Note: block comments with simply are also ignored.
 */
void validFunction() {}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('similar words allowed', () async {
    const source = '''
/// Simplify this expression.
/// Notebook entry.
/// Noted that previously.
void validFunction() {}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('taboo simply', () async {
    const source = '''
/// Simply avoid this.
void badFunction() {}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(0, 22)]);
  });

  test('taboo simply in middle of sentence', () async {
    const source = '''
/// You can simply call this function.
void badFunction() {}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(0, 38)]);
  });

  test('note allowed', () async {
    const source = '''
/// Note: foo is allowed.
/// Note that this is allowed.
void validFunction() {}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('taboo case insensitive', () async {
    const source = '''
/// SIMPLY avoid this.
void badFunction() {}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(0, 22)]);
  });

  test('taboo multiline doc comment', () async {
    const source = '''
/// First line is fine.
/// and simply do that.
void badFunction() {}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(0, 47)]);
  });
}
