// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:flutter_analyzer_plugin/src/rules/golden_test_tags.dart';
import 'package:test/test.dart';

class GoldenTestTagsTest extends AnalysisRuleTest {
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
}

const String _flutterTestPackageName = 'flutter_test';

const String _flutterTestPackageRoot = '/packages/$_flutterTestPackageName';

void main() {
  late GoldenTestTagsTest testSuite;

  setUp(() {
    testSuite = GoldenTestTagsTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('missing tag', () async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(66, 29)]);
  });

  test('valid tag with type arg', () async {
    const source = '''
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('valid tag without type arg', () async {
    const source = '''
@Tags(['reduced-test-set'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('valid tag single string literal', () async {
    const source = '''
@Tags('reduced-test-set')
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('valid tag on import', () async {
    const source = '''
@Tags(['reduced-test-set'])
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('valid tag with multiple tags', () async {
    const source = '''
@Tags(<String>['other-tag', 'reduced-test-set'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('missing reduced tag', () async {
    const source = '''
@Tags(<String>['other-tag'])
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertDiagnostics(source, [testSuite.lint(105, 29)]);
  });

  test('ignore trailing comment', () async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png'); // ignore: golden_test_tags
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('ignore previous line comment', () async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ignore: golden_test_tags
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('ignore for file', () async {
    const source = '''
// ignore_for_file: golden_test_tags

import 'package:flutter_test/flutter_test.dart';

void main() {
  matchesGoldenFile('test.png');
}
''';
    await testSuite.assertNoDiagnostics(source);
  });

  test('no golden calls', () async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  expect(1, 1);
}
''';
    await testSuite.assertNoDiagnostics(source);
  });
}
