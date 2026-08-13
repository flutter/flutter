// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_sync_async_star.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NoSyncAsyncStarTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoSyncAsyncStar());
    super.setUp();
  }

  @override
  String get analysisRule => NoSyncAsyncStar.code.name;

  static const String source = '''
      Stream<int> foo() async* {
        yield 1;
      }
      Iterable<int> bar() sync* {
        yield 1;
      }
      // The following uses async* because: Fake reason.
      Stream<int> baz() async* {
        yield 1;
      }
      // The following uses sync* because: Fake reason
      Iterable<int> qux() sync* {
        yield 1;
      }
      void nest() {
        final f = () async* { yield 1; };
      }
''';

  // ignore: non_constant_identifier_names
  Future<void> test_no_sync_async_star() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(6, 51),
      lint(64, 52),
      lint(384, 22),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoSyncAsyncStarTest);
  });
}
