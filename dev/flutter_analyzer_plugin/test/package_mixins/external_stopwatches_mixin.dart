// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

extension ExternalStopwatchesExtension on PackageConfigFileBuilder {
  PackageConfigFileBuilder addExternalStopwatchesPackage(AnalysisRuleTest test) {
    add(
      name: ExternalStopwatchesPackage._externalStopwatchesPackageName,
      rootPath: test.convertPath(ExternalStopwatchesPackage._externalStopwatchesPackageRoot),
    );
    return this;
  }
}

/// Mixin application that allows for `package:meta` imports in tests.
mixin ExternalStopwatchesPackage on AnalysisRuleTest {
  static const String _externalStopwatchesPackageName = 'external_stopwatches';
  static const String _externalStopwatchesPackageRoot =
      '/packages/$_externalStopwatchesPackageName';

  @override
  void setUp() {
    super.setUp();
    newFile('$_externalStopwatchesPackageRoot/lib/external_stopwatches.dart', '''
// External Library that creates Stopwatches. This file will not be analyzed but
// its symbols will be imported by tests.

class MyStopwatch implements Stopwatch {
  MyStopwatch();
  MyStopwatch.create() : this();

  @override
  Duration get elapsed => throw UnimplementedError();

  @override
  int get elapsedMicroseconds => throw UnimplementedError();

  @override
  int get elapsedMilliseconds => throw UnimplementedError();

  @override
  int get elapsedTicks => throw UnimplementedError();

  @override
  int get frequency => throw UnimplementedError();

  @override
  bool get isRunning => throw UnimplementedError();

  @override
  void reset() {}

  @override
  void start() {}

  @override
  void stop() {}
}

final MyStopwatch stopwatch = MyStopwatch.create();

MyStopwatch createMyStopwatch() => MyStopwatch();
Stopwatch createStopwatch() => Stopwatch();

''');
  }
}
