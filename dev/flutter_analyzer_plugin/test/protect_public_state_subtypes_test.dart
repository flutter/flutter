// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/protect_public_state_subtypes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package_mixins/meta_mixin.dart';
import 'package_mixins/widgets_mixin.dart';

@reflectiveTest
class ProtectPublicStateSubtypesTest extends AnalysisRuleTest
    with MetaPackage, FlutterWidgetsPackage {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(ProtectPublicStateSubtypes());
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..addFlutterWidgetsPackage(this)
        ..addMetaPackage(this),
    );
  }

  @override
  String get analysisRule => ProtectPublicStateSubtypes.code.name;

  static const String source = '''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends StatefulWidget {

  @override
  State createState() => MyWidgetStateBad();
}

class MyWidgetStateBad extends State<MyWidget>{
  @override
  void initState() { // ERROR
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyWidget oldWidget) { // ERROR
    super.didUpdateWidget(oldWidget);
  }

  @override
  void reassemble() { // ERROR
    super.reassemble();
  }

  @override
  void setState(VoidCallback fn) {} // ERROR

  @override
  void deactivate() { // ERROR
    super.deactivate();
  }

  @override
  void activate() { // ERROR
    super.activate();
  }

  @override
  void dispose() { // ERROR
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Widget();

  @override
  void didChangeDependencies() { // ERROR
    super.didChangeDependencies();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) { // ERROR
    super.debugFillProperties(properties);
  }
}

class MyWidgetStateValid extends State<MyWidget>{
  @override
  @protected
  void initState() {
    super.initState();
  }

  @override
  @protected
  void didUpdateWidget(covariant MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  @protected
  void reassemble() {
    super.reassemble();
  }

  @override
  @protected
  void setState(VoidCallback fn) {}

  @override
  @protected
  void deactivate() {
    super.deactivate();
  }

  @override
  @protected
  void activate() {
    super.activate();
  }

  @override
  @protected
  void dispose() {
    super.dispose();
  }

  @override
  @protected
  Widget build(BuildContext context) => Widget();

  @override
  @protected
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  @protected
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''';

  // ignore: non_constant_identifier_names
  Future<void> test_protect_public_state_subtypes() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(224, 66),
      lint(294, 115),
      lint(413, 68),
      lint(485, 45),
      lint(543, 68),
      lint(615, 64),
      lint(683, 62),
      lint(749, 59),
      lint(812, 90),
      lint(906, 134),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProtectPublicStateSubtypesTest);
  });
}
