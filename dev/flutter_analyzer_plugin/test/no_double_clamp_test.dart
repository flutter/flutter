// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_double_clamp.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NoDoubleClampTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoDoubleClamp());
    super.setUp();
  }

  @override
  String get analysisRule => NoDoubleClamp.code.name;

  static const String source = '''
class ClassWithAClampMethod {
  ClassWithAClampMethod clamp(double min, double max) => this;
}

void testNoDoubleClamp(int input) {
  final ClassWithAClampMethod nonDoubleClamp = ClassWithAClampMethod();
  // ignore: unnecessary_nullable_for_final_variable_declarations
  final ClassWithAClampMethod? nonDoubleClamp2 = nonDoubleClamp;
  // ignore: unnecessary_nullable_for_final_variable_declarations
  final int? nullableInt = input;
  final double? nullableDouble = nullableInt?.toDouble();

  nonDoubleClamp.clamp(0, 2);
  input.clamp(0, 2);
  input.clamp(0.0, 2); // ERROR: input.clamp(0.0, 2)
  input.toDouble().clamp(0, 2); // ERROR: input.toDouble().clamp(0, 2)

  nonDoubleClamp2?.clamp(0, 2);
  nullableInt?.clamp(0, 2);
  nullableInt?.clamp(0, 2.0); // ERROR: nullableInt?.clamp(0, 2.0)
  nullableDouble?.clamp(0, 2); // ERROR: nullableDouble?.clamp(0, 2)

  // ignore: unused_local_variable
  final ClassWithAClampMethod Function(double, double)? tearOff1 = nonDoubleClamp2?.clamp;
  // ignore: unused_local_variable
  final num Function(num, num)? tearOff2 = nullableInt?.clamp; // ERROR: nullableInt?.clamp
  // ignore: unused_local_variable
  final num Function(num, num)? tearOff3 = nullableDouble?.clamp; // ERROR: nullableDouble?.clamp
}
''';

  // ignore: non_constant_identifier_names
  Future<void> test_no_double_clamp() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(553, 5),
      lint(617, 5),
      lint(745, 5),
      lint(815, 5),
      lint(1084, 5),
      lint(1214, 5),
      lint(1214, 6), // Expected failure
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDoubleClampTest);
  });
}
