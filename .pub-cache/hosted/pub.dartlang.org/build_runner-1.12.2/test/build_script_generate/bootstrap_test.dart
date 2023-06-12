// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(2)
import 'dart:io';

import 'package:build_runner/build_script_generate.dart';
import 'package:test/test.dart';

import '../integration_tests/utils/build_descriptor.dart';

void main() {
  test('invokes custom error function', () async {
    Object error;
    StackTrace stackTrace;

    final pkgDir = (await package([])).rootPackageDir;

    await IOOverrides.runZoned(
      () {
        return expectLater(
          generateAndRun(
            [],
            generateBuildScript: () async {
              return '''
              void main() {
                throw 'expected error';
              }
              ''';
            },
            handleUncaughtError: (err, trace) {
              error = err;
              stackTrace = trace;
            },
          ),
          completion(1),
        );
      },
      getCurrentDirectory: () => Directory(pkgDir),
    );

    expect(error, 'expected error');
    expect(stackTrace, isNotNull);
  });
}
