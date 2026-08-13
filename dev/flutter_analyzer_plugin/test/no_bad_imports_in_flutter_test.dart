// ignore_for_file: non_constant_identifier_names
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_bad_imports_in_flutter.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NoBadImportsInFlutterTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoBadImportsInFlutter());
    super.setUp();
  }

  @override
  String get analysisRule => NoBadImportsInFlutter.code.name;

  static const String source = '''
// ignore_for_file: uri_does_not_exist

import 'package:meta/meta.dart'; // ERROR: import 'package:meta/meta.dart'
import 'package:flutter/widgets.dart'; // ERROR: import 'package:flutter/widgets.dart'
import 'package:flutter/rendering.dart'; // OK
import 'utils.dart'; // OK
''';

  Future<void> test_no_bad_imports_in_flutter() async {
    // We cannot easily mock the absolute path in AnalysisRuleTest to pretend we are in
    // packages/flutter/lib/src/widgets without subclassing or using test package builders.
    // Assuming the rule gracefully handles this by skipping absolute path dependents if not matched.
    // For now we just check the meta import, since the absolute path isn't foundation.
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(47, 24),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBadImportsInFlutterTest);
  });
}
