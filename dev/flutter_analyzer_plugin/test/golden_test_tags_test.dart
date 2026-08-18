// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/golden_test_tags.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
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
        ..add(name: _flutterTestPackageName, rootPath: convertPath(_flutterTestPackageRoot)),
    );
  }

  @override
  String get analysisRule => GoldenTestTags.code.name;

  // ignore: non_constant_identifier_names
  Future<void> test_missing_tag() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertDiagnostics(source, [lint(66, 29)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_valid_tag_with_type_arg() async {
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

  // ignore: non_constant_identifier_names
  Future<void> test_valid_tag_without_type_arg() async {
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

  // ignore: non_constant_identifier_names
  Future<void> test_valid_tag_single_string_literal() async {
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

  // ignore: non_constant_identifier_names
  Future<void> test_valid_tag_on_import() async {
    const source = '''
@Tags(['reduced-test-set'])
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_valid_tag_with_multiple_tags() async {
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

  // ignore: non_constant_identifier_names
  Future<void> test_missing_reduced_tag() async {
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

  // ignore: non_constant_identifier_names
  Future<void> test_ignore_trailing_comment() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png'); // ignore: golden_test_tags
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_ignore_previous_line_comment() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ignore: golden_test_tags
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_ignore_for_file() async {
    const source = '''
// ignore_for_file: golden_test_tags

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_no_golden_calls() async {
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
  defineReflectiveSuite(() {
    defineReflectiveTests(GoldenTestTagsTest);
  });
}
