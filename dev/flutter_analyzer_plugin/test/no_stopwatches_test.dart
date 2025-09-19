// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/no_stopwatches.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'package_mixins/external_stopwatches_mixin.dart';

@reflectiveTest
class NoStopwatchesTest extends AnalysisRuleTest with ExternalStopwatchesPackage {
  @override
  void setUp() {
    Registry.ruleRegistry.registerWarningRule(NoStopwatches());
    super.setUp();

    writeTestPackageConfig(PackageConfigFileBuilder()..addExternalStopwatchesPackage(this));
  }

  @override
  String get analysisRule => NoStopwatches.code.name;

  static const String source = '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:external_stopwatches/external_stopwatches.dart' as externallib;

typedef ExternalStopwatchConstructor = externallib.MyStopwatch Function();

class StopwatchAtHome extends Stopwatch {
  StopwatchAtHome();
  StopwatchAtHome.create() : this();

  Stopwatch get stopwatch => this;
}

void testNoStopwatches(Stopwatch stopwatch) {
  // OK for now, but we probably want to catch public APIs that take a Stopwatch?
  stopwatch.runtimeType;
  // Bad: introducing Stopwatch from dart:core.
  final Stopwatch localVariable = Stopwatch(); // ERROR: Stopwatch()
  // Bad: introducing Stopwatch from dart:core.
  Stopwatch().runtimeType; // ERROR: Stopwatch()

  (localVariable..runtimeType) // OK: not directly introducing Stopwatch.
      .runtimeType;

  // Bad: introducing a Stopwatch subclass.
  StopwatchAtHome().runtimeType; // ERROR: StopwatchAtHome()

  // OK: not directly introducing Stopwatch.
  Stopwatch anotherStopwatch = stopwatch;
  // Bad: introducing a Stopwatch constructor.
  StopwatchAtHome Function() constructor = StopwatchAtHome.new; // ERROR: StopwatchAtHome.new
  assert(() {
    anotherStopwatch = constructor()..runtimeType;
    // Bad: introducing a Stopwatch constructor.
    constructor = StopwatchAtHome.create; // ERROR: StopwatchAtHome.create
    anotherStopwatch = constructor()..runtimeType;
    return true;
  }());
  anotherStopwatch.runtimeType;

  // Bad: introducing an external Stopwatch constructor.
  externallib.MyStopwatch.create(); // ERROR: externallib.MyStopwatch.create()
  ExternalStopwatchConstructor? externalConstructor;

  assert(() {
    // Bad: introducing an external Stopwatch constructor.
    externalConstructor = externallib.MyStopwatch.new; // ERROR: externallib.MyStopwatch.new
    return true;
  }());
  externalConstructor?.call();

  // Bad: introducing an external Stopwatch.
  externallib.stopwatch.runtimeType; // ERROR: externallib.stopwatch
  // Bad: calling an external function that returns a Stopwatch.
  externallib.createMyStopwatch().runtimeType; // ERROR: externallib.createMyStopwatch()
  // Bad: calling an external function that returns a Stopwatch.
  externallib.createStopwatch().runtimeType; // ERROR: externallib.createStopwatch()
  // Bad: introducing the tear-off form of an external function that returns a Stopwatch.
  externalConstructor = externallib.createMyStopwatch; // ERROR: externallib.createMyStopwatch

  // OK: existing instance.
  constructor.call().stopwatch;
}

void testStopwatchIgnore(Stopwatch stopwatch) {
  Stopwatch().runtimeType; // flutter_ignore: stopwatch (see analyze.dart)
  Stopwatch().runtimeType; // flutter_ignore: some_other_ignores, stopwatch (see analyze.dart)
}
''';

  // ignore: non_constant_identifier_names
  Future<void> test_no_stopwatches() async {
    await assertDiagnostics(source, <ExpectedDiagnostic>[
      lint(696, 9),
      lint(781, 9),
      lint(970, 15),
      lint(1207, 19),
      lint(1390, 22),
      lint(1615, 30),
      lint(1845, 27),
      lint(2028, 9),
      lint(2162, 17),
      lint(2316, 15),
      lint(2513, 17),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoStopwatchesTest);
  });
}
