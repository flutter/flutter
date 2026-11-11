// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/repository_link_syntax.dart';
import 'package:test/test.dart';

class RepositoryLinkSyntaxTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(RepositoryLinkSyntax());
    super.setUp();
  }

  @override
  String get analysisRule => RepositoryLinkSyntax.code.name;
}

void main() {
  late RepositoryLinkSyntaxTest testSuite;

  setUp(() {
    testSuite = RepositoryLinkSyntaxTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('valid repository links', () async {
    const source = r'''
// https://github.com/flutter/flutter/tree/main/file1
// https://flutter.googlesource.com/+/main/file1
// https://cs.opensource.google.com/+/main/file1
// https://chromium.googlesource.com/+/main/file1
// https://source.chromium.org/+/main/file1
// https://raw.githubusercontent.com/flutter/flutter/blob/main/file1

// Exempt repositories whose default branch is master:
// https://github.com/clojure/clojure/tree/master/file1
// https://github.com/dart-lang/test/tree/master/file1
// https://github.com/flutter/flutter-intellij/tree/master/file1
// https://github.com/glfw/glfw/tree/master/file1
// https://github.com/ninja-build/ninja/tree/master/file1
// https://github.com/torvalds/linux/tree/master/file1

void main() {
  const String link1 = 'https://github.com/flutter/flutter/tree/main/file1';
  const String link2 = 'https://github.com/clojure/clojure/tree/master/file1';
  final String name = 'test';
  final String interpolated = '$name: https://github.com/flutter/flutter/tree/main/file1';
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('banned master in comments', () async {
    const source = '''
// Check out https://android.googlesource.com/+/master/file1
// Check out https://chromium.googlesource.com/+/master/file1
// Check out https://cs.opensource.google.com/+/master/file1
// Check out https://dart.googlesource.com/+/master/file1
// Check out https://flutter.googlesource.com/+/master/file1
// Check out https://source.chromium.org/+/master/file1
// Check out https://github.com/flutter/flutter/tree/master/file1
// Check out https://raw.githubusercontent.com/flutter/flutter/blob/master/file1
void main() {}
''';
    await testSuite.assertDiagnostics(source, [
      testSuite.lint(0, 60),
      testSuite.lint(61, 61),
      testSuite.lint(123, 60),
      testSuite.lint(184, 57),
      testSuite.lint(242, 60),
      testSuite.lint(303, 55),
      testSuite.lint(359, 65),
      testSuite.lint(425, 80),
    ]);
  });

  test('banned master in string literal', () async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/flutter/tree/master/file1';
}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(33, 54)]);
  });

  test('banned master in interpolated string', () async {
    const source = r'''
void main() {
  final String foo = 'bar';
  final String s = '$foo https://flutter.googlesource.com/+/master/file1';
}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(61, 54)]);
  });

  test('banned master in adjacent strings', () async {
    const source = '''
void main() {
  const String s = 'https://github.com/flutter/'
      'flutter/tree/master/file1';
}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(33, 63)]);
  });
}
