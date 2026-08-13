// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
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

  // ignore: non_constant_identifier_names
  Future<void> test_invalid_layer_dependency() async {
    newPackage('flutter').addFile('lib/material.dart', 'const int mat = 1;');
    await assertDiagnostics(
      '''
import 'package:flutter/material.dart';

const int x = mat;
''',
      <ExpectedDiagnostic>[lint(7, 31)],
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_invalid_export_name() async {
    newPackage('flutter').addFile('lib/unknown_layer.dart', 'const int u = 1;');
    await assertDiagnostics(
      '''
import 'package:flutter/unknown_layer.dart';

const int x = u;
''',
      <ExpectedDiagnostic>[lint(7, 36)],
    );
  }

  // ignore: non_constant_identifier_names
  Future<void> test_valid_downward_import() async {
    newPackage('flutter').addFile('lib/foundation.dart', 'const int f = 1;');
    await assertNoDiagnostics(
      '''
import 'package:flutter/foundation.dart';

const int x = f;
''',
    );
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBadImportsInFlutterTest);
  });
}
