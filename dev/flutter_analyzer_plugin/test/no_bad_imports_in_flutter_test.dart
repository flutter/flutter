// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_bad_imports_in_flutter.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package_mixins/meta_mixin.dart';

@reflectiveTest
class NoBadImportsInFlutterTest extends AnalysisRuleTest with MetaPackage {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoBadImportsInFlutter());
    super.setUp();

    newPackage('flutter').addFile('lib/widgets.dart', 'const int widget = 1;');
    writeTestPackageConfig(PackageConfigFileBuilder()..addMetaPackage(this));
  }

  @override
  String get analysisRule => NoBadImportsInFlutter.code.name;

  @override
  String get testPackageRootPath => '$workspaceRootPath/packages/flutter';

  @override
  String get testPackageLibPath => '$testPackageRootPath/lib/src/widgets';

  static const String source = '''
import 'package:meta/meta.dart';

@protected
class Foo {}
''';

  // ignore: non_constant_identifier_names
  Future<void> test_no_bad_imports_in_flutter() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[lint(7, 24)]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_recursive_self_import() async {
    await assertDiagnostics(
      '''
import 'package:flutter/widgets.dart';

const int x = widget;
''',
      <ExpectedDiagnostic>[lint(7, 30)],
    );
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBadImportsInFlutterTest);
  });
}
