// ignore_for_file: non_constant_identifier_names, use_raw_strings
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/null_initialized_debug_expensive_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NullInitializedDebugExpensiveFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NullInitializedDebugExpensiveFields());
    super.setUp();
  }

  @override
  String get analysisRule => NullInitializedDebugExpensiveFields.code.name;

  static const String source = '''
import 'package:flutter/foundation.dart';

class GoodClass {
  @_debugOnly
  final int? _foo = kDebugMode ? 1 : null;
}

class BadClass {
  @_debugOnly
  final int? _foo = 1;
}

class BadClass2 {
  @_debugOnly
  int? _foo;
}

class BadClass3 {
  @_debugOnly
  final int? _foo = kDebugMode ? 1 : 2;
}

class GoodClass2 {
  @_debugOnly
  int? _foo = kDebugMode ? 1 : null;
}

const _debugOnly = Object();
const kDebugMode = true;
''';

  Future<void> test_null_initialized() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[

    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullInitializedDebugExpensiveFieldsTest);
  });
}
