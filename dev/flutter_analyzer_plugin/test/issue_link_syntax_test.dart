// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/issue_link_syntax.dart';
import 'package:test/test.dart';

class IssueLinkSyntaxTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(IssueLinkSyntax());
    super.setUp();
  }

  @override
  String get analysisRule => IssueLinkSyntax.code.name;

  Future<void> testValidIssueLinks() async {
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

  Future<void> testDirectLinkInComment() async {
    const source = '''
// https://github.com/flutter/flutter/issues/new
void main() {}
''';
    await assertDiagnostics(source, [lint(0, 48)]);
  }

  Future<void> testDirectLinkInString() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new';
}
''';
    await assertDiagnostics(source, [lint(33, 47)]);
  }

  Future<void> testInvalidTemplateInString() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?template=invalid.yml';
}
''';
    await assertDiagnostics(source, [lint(33, 68)]);
  }

  Future<void> testNoTemplateArgInString() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?title=bug';
}
''';
    await assertDiagnostics(source, [lint(33, 57)]);
  }

  Future<void> testExtraQueryParamsInString() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?template=02_bug.yml&labels=p1';
}
''';
    await assertDiagnostics(source, [lint(33, 77)]);
  }

  Future<void> testInterpolatedInvalidIssueLink() async {
    const source = r'''
void main() {
  final String foo = 'bar';
  final String s = '$foo https://github.com/flutter/flutter/issues/new';
}
''';
    await assertDiagnostics(source, [lint(61, 52)]);
  }

  Future<void> testAdjacentStringsInvalidLink() async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/'
      'flutter/issues/new?title=bug';
}
''';
    await assertDiagnostics(source, [lint(33, 66)]);
  }
}

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

  Future<void> testTestFileSkipped() async {
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
  group('IssueLinkSyntaxTest', () {
    late IssueLinkSyntaxTest testSuite;

    setUp(() {
      testSuite = IssueLinkSyntaxTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test('valid_issue_links', () => testSuite.testValidIssueLinks());
    test('direct_link_in_comment', () => testSuite.testDirectLinkInComment());
    test('direct_link_in_string', () => testSuite.testDirectLinkInString());
    test('invalid_template_in_string', () => testSuite.testInvalidTemplateInString());
    test('no_template_arg_in_string', () => testSuite.testNoTemplateArgInString());
    test('extra_query_params_in_string', () => testSuite.testExtraQueryParamsInString());
    test('interpolated_invalid_issue_link', () => testSuite.testInterpolatedInvalidIssueLink());
    test('adjacent_strings_invalid_link', () => testSuite.testAdjacentStringsInvalidLink());
  });
  group('IssueLinkSyntaxTestFileTest', () {
    late IssueLinkSyntaxTestFileTest testSuite;

    setUp(() {
      testSuite = IssueLinkSyntaxTestFileTest()..setUp();
    });

    tearDown(() => testSuite.tearDown());

    test('test_file_skipped', () => testSuite.testTestFileSkipped());
  });
}
