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

  Future<void> testValidDocComment() async {
    const source = '''
/// This is a valid documentation comment.
/// It explains how the function works without taboo words.
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testNonDocCommentsIgnored() async {
    const source = '''
// Simply do this.
// Note: this is a regular comment.
// Note that this is allowed in regular comments.
/*
 * Note: block comments with simply are also ignored.
 */
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testSimilarWordsAllowed() async {
    const source = '''
/// Simplify this expression.
/// Notebook entry.
/// Noted that previously.
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testTabooSimply() async {
    const source = '''
/// Simply avoid this.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 22)]);
  }

  Future<void> testTabooSimplyInMiddleOfSentence() async {
    const source = '''
/// You can simply call this function.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 38)]);
  }

  Future<void> testNoteAllowed() async {
    const source = '''
/// Note: foo is allowed.
/// Note that this is allowed.
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testTabooCaseInsensitive() async {
    const source = '''
/// SIMPLY avoid this.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 22)]);
  }

  Future<void> testTabooMultilineDocComment() async {
    const source = '''
/// First line is fine.
/// and simply do that.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 47)]);
  }
}

void main() {
  late TabooDocumentationTest testSuite;

  setUp(() {
    testSuite = TabooDocumentationTest()..setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('valid_doc_comment', () => testSuite.testValidDocComment());
  test('non_doc_comments_ignored', () => testSuite.testNonDocCommentsIgnored());
  test('similar_words_allowed', () => testSuite.testSimilarWordsAllowed());
  test('taboo_simply', () => testSuite.testTabooSimply());
  test('taboo_simply_in_middle_of_sentence', () => testSuite.testTabooSimplyInMiddleOfSentence());
  test('note_allowed', () => testSuite.testNoteAllowed());
  test('taboo_case_insensitive', () => testSuite.testTabooCaseInsensitive());
  test('taboo_multiline_doc_comment', () => testSuite.testTabooMultilineDocComment());
}
