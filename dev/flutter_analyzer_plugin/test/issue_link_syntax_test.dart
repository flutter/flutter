// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/issue_link_syntax.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class IssueLinkSyntaxTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(IssueLinkSyntax());
    super.setUp();
  }

  @override
  String get analysisRule => IssueLinkSyntax.code.name;

  // ignore: non_constant_identifier_names
  Future<void> test_valid_issue_links() async {
    const source = r'''
// https://github.com/flutter/flutter/issues/new/choose
// https://github.com/flutter/flutter/issues/new?template=02_bug.yml
// https://github.com/flutter/flutter/issues/new?template=01_activation.yml

void main() {
  const String link1 = 'https://github.com/flutter/flutter/issues/new/choose';
  const String link2 = 'https://github.com/flutter/flutter/issues/new?template=02_bug.yml';
  final String name = 'test';
  final String interpolated = '$name: https://github.com/flutter/flutter/issues/new/choose';
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_direct_link_in_comment() async {
    const source = '''
// https://github.com/flutter/flutter/issues/new
void main() {}
''';
    await assertDiagnostics(source, [lint(0, 48)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_direct_link_in_string() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new';
}
''';
    await assertDiagnostics(source, [lint(33, 47)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_invalid_template_in_string() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?template=invalid.yml';
}
''';
    await assertDiagnostics(source, [lint(33, 68)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_no_template_arg_in_string() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?title=bug';
}
''';
    await assertDiagnostics(source, [lint(33, 57)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_extra_query_params_in_string() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?template=02_bug.yml&labels=p1';
}
''';
    await assertDiagnostics(source, [lint(33, 77)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_interpolated_invalid_issue_link() async {
    const source = r'''
void main() {
  final String foo = 'bar';
  final String s = '$foo https://github.com/flutter/flutter/issues/new';
}
''';
    await assertDiagnostics(source, [lint(61, 52)]);
  }
}

@reflectiveTest
class IssueLinkSyntaxTestFileTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(IssueLinkSyntax());
    super.setUp();
  }

  @override
  String get analysisRule => IssueLinkSyntax.code.name;

  @override
  String get testFileName => 'sample_test.dart';

  // ignore: non_constant_identifier_names
  Future<void> test_test_file_skipped() async {
    const source = '''
// https://github.com/flutter/flutter/issues/new
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new';
}
''';
    await assertNoDiagnostics(source);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IssueLinkSyntaxTest);
    defineReflectiveTests(IssueLinkSyntaxTestFileTest);
  });
}
