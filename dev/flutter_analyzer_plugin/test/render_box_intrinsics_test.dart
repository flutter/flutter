// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/render_box_intrinsics.dart';
import 'package:test/test.dart';

class RenderBoxIntrinsicCalculationRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(RenderBoxIntrinsicCalculationRule());
    super.setUp();
  }

  @override
  String get analysisRule => RenderBoxIntrinsicCalculationRule.code.name;
}

const String _source = '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

abstract class RenderBox {
  void computeDryBaseline() {}
  void computeDryLayout() {}
  void computeDistanceToActualBaseline() {}
  void computeMaxIntrinsicHeight() {}
  void computeMinIntrinsicHeight() {}
  void computeMaxIntrinsicWidth() {}
  void computeMinIntrinsicWidth() {}
}

mixin ARenderBoxMixin on RenderBox {
  @override
  void computeMaxIntrinsicWidth() {}

  @override
  void computeMinIntrinsicWidth() => computeMaxIntrinsicWidth(); // ERROR: computeMaxIntrinsicWidth(). Consider calling getMaxIntrinsicWidth instead.

  @override
  void computeMinIntrinsicHeight() {
    final void Function() f =
        computeMaxIntrinsicWidth; // ERROR: f = computeMaxIntrinsicWidth. Consider calling getMaxIntrinsicWidth instead.
    f();
  }
}

extension ARenderBoxExtension on RenderBox {
  void test() {
    computeDryBaseline(); // ERROR: computeDryBaseline(). Consider calling getDryBaseline instead.
    computeDryLayout(); // ERROR: computeDryLayout(). Consider calling getDryLayout instead.
  }
}

class RenderBoxSubclass1 extends RenderBox {
  @override
  void computeDryLayout() {
    computeDistanceToActualBaseline(); // ERROR: computeDistanceToActualBaseline(). Consider calling getDistanceToBaseline, or getDistanceToActualBaseline instead.
  }

  @override
  void computeDistanceToActualBaseline() {
    computeMaxIntrinsicHeight(); // ERROR: computeMaxIntrinsicHeight(). Consider calling getMaxIntrinsicHeight instead.
  }

  /// [RenderBox.computeDryLayout]: // OK
  double? getDryBaseline() {
    return 0;
  }
}

class RenderBoxSubclass2 extends RenderBox with ARenderBoxMixin {
  @override
  void computeMaxIntrinsicWidth() {
    super.computeMinIntrinsicHeight(); // OK
    super.computeMaxIntrinsicWidth(); // OK
    final void Function() f = super.computeDryBaseline; // OK
    f();
  }
}
''';

void main() {
  late RenderBoxIntrinsicCalculationRuleTest testSuite;

  setUp(() {
    testSuite = RenderBoxIntrinsicCalculationRuleTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('render box intrinsics', () async {
    await testSuite.assertDiagnostics(_source, <ExpectedDiagnostic>[
      testSuite.lint(585, 24),
      testSuite.lint(786, 24),
      testSuite.lint(980, 18),
      testSuite.lint(1079, 16),
      testSuite.lint(1264, 31),
      testSuite.lint(1488, 25),
    ]);
  });
}
