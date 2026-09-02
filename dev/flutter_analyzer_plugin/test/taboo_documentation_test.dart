// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/taboo_documentation.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class TabooDocumentationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(TabooDocumentation());
    super.setUp();
  }

  @override
  String get analysisRule => TabooDocumentation.code.name;

  // ignore: non_constant_identifier_names
  Future<void> test_valid_doc_comment() async {
    const source = '''
/// This is a valid documentation comment.
/// It explains how the function works without taboo words.
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_non_doc_comments_ignored() async {
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

  // ignore: non_constant_identifier_names
  Future<void> test_similar_words_allowed() async {
    const source = '''
/// Simplify this expression.
/// Notebook entry.
/// Noted that previously.
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_taboo_simply() async {
    const source = '''
/// Simply avoid this.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 22)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_taboo_simply_in_middle_of_sentence() async {
    const source = '''
/// You can simply call this function.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 38)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_note_allowed() async {
    const source = '''
/// Note: foo is allowed.
/// Note that this is allowed.
void validFunction() {}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_taboo_case_insensitive() async {
    const source = '''
/// SIMPLY avoid this.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 22)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_taboo_multiline_doc_comment() async {
    const source = '''
/// First line is fine.
/// and simply do that.
void badFunction() {}
''';
    await assertDiagnostics(source, [lint(0, 47)]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TabooDocumentationTest);
  });
}
