// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')

import 'package:test/test.dart';

import 'fixtures/context.dart';
import 'evaluate_common.dart';

void main() async {
  // Enable verbose logging for debugging.
  final debug = false;

  for (var nullSafety in NullSafety.values) {
    group('${nullSafety.name} null safety |', () {
      testAll(
        compilationMode: CompilationMode.buildDaemon,
        nullSafety: nullSafety,
        debug: debug,
      );
    });
  }
}
