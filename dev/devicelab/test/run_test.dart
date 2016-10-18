// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('run.dart script', () {
    Future<int> runScript(List<String> testNames) async {
      List<String> options = <String>['bin/run.dart'];
      for (String testName in testNames) {
        options..addAll(<String>['-t', testName]);
      }
      Process scriptProcess = await Process.start(
        '../../bin/cache/dart-sdk/bin/dart',
        options,
      );
      return scriptProcess.exitCode;
    }

    test('Exits with code 0 when succeeds', () async {
      expect(await runScript(<String>['smoke_test_success']), 0);
    });

    test('Exits with code 1 when task throws', () async {
      expect(await runScript(<String>['smoke_test_throws']), 1);
    });

    test('Exits with code 1 when fails', () async {
      expect(await runScript(<String>['smoke_test_failure']), 1);
    });

    test('Exits with code 1 when fails to connect', () async {
      expect(await runScript(<String>['smoke_test_setup_failure']), 1);
    });

    test('Exits with code 1 when results are mixed', () async {
      expect(
        await runScript(<String>[
          'smoke_test_failure',
          'smoke_test_success',
        ]),
        1,
      );
    });
  });
}
