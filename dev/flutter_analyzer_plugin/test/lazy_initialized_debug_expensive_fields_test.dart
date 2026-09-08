// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/lazy_initialized_debug_expensive_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class LazyInitializedDebugExpensiveFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(LazyInitializedDebugExpensiveFields());
    super.setUp();
  }

  @override
  String get analysisRule => LazyInitializedDebugExpensiveFields.code.name;

  static const String source = '''
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

  // ignore: non_constant_identifier_names
  Future<void> test_lazy_initialized() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(145, 33)]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LazyInitializedDebugExpensiveFieldsTest);
  });
}
