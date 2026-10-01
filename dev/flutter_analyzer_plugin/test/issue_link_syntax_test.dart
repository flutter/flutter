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
}

void main() {
  group('IssueLinkSyntaxTest', () {
    late IssueLinkSyntaxTest testSuite;

    setUp(() {
      testSuite = IssueLinkSyntaxTest();
      testSuite.setUp();
    });

    tearDown(() => testSuite.tearDown());

    test('valid issue links', () async {
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
      await testSuite.assertNoDiagnostics(source);
    });

    test('direct link in comment', () async {
      const source = '''
// https://github.com/flutter/flutter/issues/new
void main() {}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(0, 48)]);
    });

    test('direct link in string', () async {
      const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new';
}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(33, 47)]);
    });

    test('invalid template in string', () async {
      const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?template=invalid.yml';
}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(33, 68)]);
    });

    test('no template arg in string', () async {
      const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?title=bug';
}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(33, 57)]);
    });

    test('extra query params in string', () async {
      const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new?template=02_bug.yml&labels=p1';
}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(33, 77)]);
    });

    test('interpolated invalid issue link', () async {
      const source = r'''
void main() {
  final String foo = 'bar';
  final String s = '$foo https://github.com/flutter/flutter/issues/new';
}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(61, 52)]);
    });

    test('adjacent strings invalid link', () async {
      const source = '''
void main() {
  const String s = 'https://github.com/flutter/'
      'flutter/issues/new?title=bug';
}
''';
      await testSuite.assertDiagnostics(source, [testSuite.lint(33, 66)]);
    });
  });
  group('IssueLinkSyntaxTestFileTest', () {
    late IssueLinkSyntaxTestFileTest testSuite;

    setUp(() {
      testSuite = IssueLinkSyntaxTestFileTest();
      testSuite.setUp();
    });

    tearDown(() => testSuite.tearDown());

    test('test file skipped', () async {
      const source = '''
// https://github.com/flutter/flutter/issues/new
void main() {
  const String s = 'https://github.com/flutter/flutter/issues/new';
}
''';
      await testSuite.assertNoDiagnostics(source);
    });
  });
}
