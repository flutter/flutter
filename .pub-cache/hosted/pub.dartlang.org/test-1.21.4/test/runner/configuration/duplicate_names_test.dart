// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  group('duplicate names', () {
    group('can be disabled for', () {
      for (var function in ['group', 'test']) {
        test('${function}s', () async {
          await d
              .file('dart_test.yaml',
                  jsonEncode({'allow_duplicate_test_names': false}))
              .create();

          var testName = 'test';
          await d.file('test.dart', '''
          import 'package:test/test.dart';

          void main() {
            $function("$testName", () {});
            $function("$testName", () {});
          }
        ''').create();

          var test = await runTest([
            'test.dart',
            '--configuration',
            p.join(d.sandbox, 'dart_test.yaml')
          ]);

          expect(
              test.stdout,
              emitsThrough(contains(
                  'A test with the name "$testName" was already declared.')));

          await test.shouldExit(1);
        });
      }
    });
    group('are allowed by default for', () {
      for (var function in ['group', 'test']) {
        test('${function}s', () async {
          var testName = 'test';
          await d.file('test.dart', '''
          import 'package:test/test.dart';

          void main() {
            $function("$testName", () {});
            $function("$testName", () {});

            // Needed so at least one test runs when testing groups.
            test('a test', () {
              expect(true, isTrue);
            });
          }
        ''').create();

          var test = await runTest(
            ['test.dart'],
          );

          expect(test.stdout, emitsThrough(contains('All tests passed!')));

          await test.shouldExit(0);
        });
      }
    });
  });
}
