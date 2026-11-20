// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_sync_async_star.dart';
import 'package:test/test.dart';

class NoSyncAsyncStarTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoSyncAsyncStar());
    super.setUp();
  }

  @override
  String get analysisRule => NoSyncAsyncStar.code.name;
}

const String _fooDeclaration =
    'Stream<int> foo() async* {\n'
    '        yield 1;\n'
    '      }';

const String _barDeclaration =
    'Iterable<int> bar() sync* {\n'
    '        yield 1;\n'
    '      }';

const String _nestedClosure = '() async* { yield 1; }';

const String _source = '''
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

void main() {
  late NoSyncAsyncStarTest testSuite;

  setUp(() {
    testSuite = NoSyncAsyncStarTest();
    testSuite.setUp();
  });

  tearDown(() => testSuite.tearDown());

  test('no sync async star', () async {
    await testSuite.assertDiagnostics(_source, <ExpectedDiagnostic>[
      testSuite.lint(_source.indexOf(_fooDeclaration), _fooDeclaration.length),
      testSuite.lint(_source.indexOf(_barDeclaration), _barDeclaration.length),
      testSuite.lint(_source.indexOf(_nestedClosure), _nestedClosure.length),
    ]);
  });
}
