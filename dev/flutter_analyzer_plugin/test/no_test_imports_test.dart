// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_test_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class NoTestImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoTestImports());
    super.setUp();

    newFile('$testPackageLibPath/foo.dart', 'const int foo = 1;');
    newFile('$testPackageLibPath/hit_test.dart', 'const int hitTest = 1;');
    newFile('$testPackageLibPath/foo_test.dart', 'const int fooTest = 1;');
    newPackage('flutter_test').addFile('lib/flutter_test.dart', 'const int flutterTest = 1;');
    newPackage('test_api').addFile('lib/src/backend/live_test.dart', 'const int liveTest = 1;');
    newPackage(
      'integration_test',
    ).addFile('lib/integration_test.dart', 'const int integrationTest = 1;');
    newPackage('some_pkg').addFile('lib/bar_test.dart', 'const int barTest = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder());
  }

  @override
  String get analysisRule => NoTestImports.code.name;

  // ignore: non_constant_identifier_names
  Future<void> test_standard_import() async {
    const source = '''
import 'foo.dart';

void main() {
  const int x = foo;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_exempt_flutter_test_import() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  const int x = flutterTest;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_exempt_hit_test_import() async {
    const source = '''
import 'hit_test.dart';

void main() {
  const int x = hitTest;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_exempt_live_test_import() async {
    const source = '''
import 'package:test_api/src/backend/live_test.dart';

void main() {
  const int x = liveTest;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_exempt_integration_test_import() async {
    const source = '''
import 'package:integration_test/integration_test.dart';

void main() {
  const int x = integrationTest;
}
''';
    await assertNoDiagnostics(source);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_relative_test_import_fails() async {
    const source = '''
import 'foo_test.dart';

void main() {
  const int x = fooTest;
}
''';
    await assertDiagnostics(source, [lint(7, 15)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_package_test_import_fails() async {
    const source = '''
import 'package:some_pkg/bar_test.dart';

void main() {
  const int x = barTest;
}
''';
    await assertDiagnostics(source, [lint(7, 32)]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoTestImportsTest);
  });
}
