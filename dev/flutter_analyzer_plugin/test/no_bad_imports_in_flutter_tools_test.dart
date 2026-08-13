// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_bad_imports_in_flutter_tools.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NoBadImportsInFlutterToolsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoBadImportsInFlutterTools());
    super.setUp();
  }

  @override
  String get analysisRule => NoBadImportsInFlutterTools.code.name;

  static const String source = '''
// ignore_for_file: uri_does_not_exist

import 'package:flutter_tools/src/base/utils.dart'; // ERROR: import 'package:flutter_tools/src/base/utils.dart'
import 'package:flutter/flutter.dart'; // OK
import 'utils.dart'; // OK
''';

  Future<void> test_no_bad_imports_in_flutter_tools() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(47, 43),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBadImportsInFlutterToolsTest);
  });
}
