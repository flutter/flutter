// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
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

    newFile('/packages/flutter_tools/lib/src/base/utils.dart', 'const int utils = 1;');
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'flutter_tools', rootPath: convertPath('/packages/flutter_tools')),
    );
  }

  @override
  String get analysisRule => NoBadImportsInFlutterTools.code.name;

  static const String source = '''
import 'package:flutter_tools/src/base/utils.dart';

const int x = utils;
''';

  // ignore: non_constant_identifier_names
  Future<void> test_no_bad_imports_in_flutter_tools() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(7, 43)]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBadImportsInFlutterToolsTest);
  });
}
