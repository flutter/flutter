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

  static const String _fooDeclaration =
      'Stream<int> foo() async* {\n'
      '        yield 1;\n'
      '      }';

  static const String _barDeclaration =
      'Iterable<int> bar() sync* {\n'
      '        yield 1;\n'
      '      }';

  static const String _nestedClosure = '() async* { yield 1; }';

  static const String source = '''
      $_fooDeclaration
      $_barDeclaration
      // The following uses async* because: Fake reason.
      Stream<int> baz() async* {
        yield 1;
      }
      // The following uses sync* because: Fake reason
      Iterable<int> qux() sync* {
        yield 1;
      }
      void nest() {
        final f = $_nestedClosure;
      }
''';

  // ignore: non_constant_identifier_names
  Future<void> test_no_sync_async_star() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(source.indexOf(_fooDeclaration), _fooDeclaration.length),
      lint(source.indexOf(_barDeclaration), _barDeclaration.length),
      lint(source.indexOf(_nestedClosure), _nestedClosure.length),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoSyncAsyncStarTest);
  });
}
