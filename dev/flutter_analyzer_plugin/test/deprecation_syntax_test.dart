// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/deprecation_syntax.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class DeprecationSyntaxTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(DeprecationSyntax());
    super.setUp();
  }

  @override
  String get analysisRule => DeprecationSyntax.code.name;

  static const String source = '''
      @Deprecated(
        'This is a valid deprecation message. '
        'This feature was deprecated after v3.12.0-1.0.pre.'
      )
      void foo() {}

      @Deprecated(
        'This is an invalid deprecation message. ' // missing version
      )
      void bar() {}
''';

  // ignore: non_constant_identifier_names
  Future<void> test_deprecation_syntax() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(163, 90), // Dummy offset
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecationSyntaxTest);
  });
}
