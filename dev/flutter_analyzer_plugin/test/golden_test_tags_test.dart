// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:flutter_analyzer_plugin/src/rules/golden_test_tags.dart';
import 'package:test/test.dart';

class GoldenTestTagsTest extends AnalysisRuleTest {
  static const String _flutterTestPackageName = 'flutter_test';
  static const String _flutterTestPackageRoot = '/packages/$_flutterTestPackageName';

  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(GoldenTestTags());
    super.setUp();

    newFile('$_flutterTestPackageRoot/lib/flutter_test.dart', '''
class Tags {
  const Tags(Object tags);
}

void matchesGoldenFile(Object key) {}
void expect(Object? actual, Object? matcher) {}
''');
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: _flutterTestPackageName, rootFolder: getFolder(_flutterTestPackageRoot)),
    );
  }

  @override
  String get analysisRule => GoldenTestTags.code.name;

  Future<void> testMissingTag() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertDiagnostics(source, [lint(66, 29)]);
  }

  Future<void> testValidTagWithTypeArg() async {
    const source = '''
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testValidTagWithoutTypeArg() async {
    const source = '''
@Tags(['reduced-test-set'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testValidTagSingleStringLiteral() async {
    const source = '''
@Tags('reduced-test-set')
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testValidTagOnImport() async {
    const source = '''
@Tags(['reduced-test-set'])
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testValidTagWithMultipleTags() async {
    const source = '''
@Tags(<String>['other-tag', 'reduced-test-set'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testMissingReducedTag() async {
    const source = '''
@Tags(<String>['other-tag'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertDiagnostics(source, [lint(105, 29)]);
  }

  Future<void> testIgnoreTrailingComment() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png'); // ignore: golden_test_tags
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testIgnorePreviousLineComment() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ignore: golden_test_tags
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testIgnoreForFile() async {
    const source = '''
// ignore_for_file: golden_test_tags

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  Future<void> testNoGoldenCalls() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  expect(1, 1);
}
''';
    await assertNoDiagnostics(source);
  }
}

void main() {
  late GoldenTestTagsTest testSuite;

  setUp(() {
    testSuite = GoldenTestTagsTest()..setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('missing_tag', () => testSuite.testMissingTag());
  test('valid_tag_with_type_arg', () => testSuite.testValidTagWithTypeArg());
  test('valid_tag_without_type_arg', () => testSuite.testValidTagWithoutTypeArg());
  test('valid_tag_single_string_literal', () => testSuite.testValidTagSingleStringLiteral());
  test('valid_tag_on_import', () => testSuite.testValidTagOnImport());
  test('valid_tag_with_multiple_tags', () => testSuite.testValidTagWithMultipleTags());
  test('missing_reduced_tag', () => testSuite.testMissingReducedTag());
  test('ignore_trailing_comment', () => testSuite.testIgnoreTrailingComment());
  test('ignore_previous_line_comment', () => testSuite.testIgnorePreviousLineComment());
  test('ignore_for_file', () => testSuite.testIgnoreForFile());
  test('no_golden_calls', () => testSuite.testNoGoldenCalls());
}
