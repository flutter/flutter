// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/lazy_initialized_debug_expensive_fields.dart';
import 'package:test/test.dart';

class LazyInitializedDebugExpensiveFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(LazyInitializedDebugExpensiveFields());
    super.setUp();
  }

  @override
  String get analysisRule => LazyInitializedDebugExpensiveFields.code.name;
}

const String _source = '''
class GoodClass {
  @_debugOnly
  late final int _foo = 1;
}

class GoodClassStatic {
  @_debugOnly
  static int _foo = 1;
}

class BadClass {
  @_debugOnly
  final int _foo = 1;
}

const _debugOnly = Object();
''';

void main() {
  late LazyInitializedDebugExpensiveFieldsTest testSuite;

  setUp(() {
    testSuite = LazyInitializedDebugExpensiveFieldsTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('lazy initialized', () async {
    await testSuite.assertDiagnostics(_source, <ExpectedDiagnostic>[testSuite.lint(145, 33)]);
  });
}
