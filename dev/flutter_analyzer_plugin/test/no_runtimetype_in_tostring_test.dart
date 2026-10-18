// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_runtimetype_in_tostring.dart';
import 'package:test/test.dart';

class NoRuntimeTypeInToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(NoRuntimeTypeInToString());
    super.setUp();
  }

  @override
  String get analysisRule => NoRuntimeTypeInToString.code.name;
}

const String _source = r'''
class GoodToString {
  @override
  String toString() {
    return 'GoodToString';
  }
}

class BadToString {
  @override
  String toString() {
    return 'BadToString with $runtimeType';
  }
}

class BadToString2 {
  @override
  String toString() => 'BadToString2 with ' + runtimeType.toString();
}

class OtherMethodWithRuntimeType {
  void someMethod() {
    print(runtimeType);
  }
}

class GoodToStringWithAssert {
  @override
  String toString() {
    assert(() {
      print(runtimeType);
      return true;
    }());
    return 'GoodToStringWithAssert';
  }
}
''';

void main() {
  late NoRuntimeTypeInToStringTest testSuite;

  setUp(() {
    testSuite = NoRuntimeTypeInToStringTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('no runtimeType', () async {
    await testSuite.assertDiagnostics(_source, <ExpectedDiagnostic>[
      testSuite.lint(173, 11),
      testSuite.lint(273, 11),
    ]);
  });
}
