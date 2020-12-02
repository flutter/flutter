// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_log_processor.dart';

import '../../src/common.dart';

final List<String> gradleErrorOutputLines = r'''
Some other stuff.
FAILURE: Build failed with an exception.

* Where:
Script '/Users/mit/dev/flutter/packages/flutter_tools/gradle/flutter.gradle' line: 900

* What went wrong:
Execution failed for task ':app:compileFlutterBuildRelease'.
> Process 'command '/Users/mit/dev/flutter/bin/flutter'' finished with non-zero exit value 1

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 24s
'''.split('\n');

void main() {
  testWithoutContext('Does not print failure footer in non-verbose mode', () async {
    final GradleLogProcessor gradleLogProcessor = GradleLogProcessor(<GradleHandledError>[], false);

    expect(gradleErrorOutputLines.map(gradleLogProcessor.consumeLog).where((String line) => line != null), <String>['Some other stuff.']);
    expect(gradleLogProcessor.atFailureFooter, true);
  });

  testWithoutContext('Does print failure footer in verbose mode', () async {
    final GradleLogProcessor gradleLogProcessor = GradleLogProcessor(<GradleHandledError>[], true);

    expect(gradleErrorOutputLines.map(gradleLogProcessor.consumeLog).where((String line) => line != null), gradleErrorOutputLines);
    expect(gradleLogProcessor.atFailureFooter, false);
  });
}
