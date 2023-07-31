// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';

import 'package:test/test.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('ignores an empty file', () async {
    await d.file('global_test.yaml', '').create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("success", () {});
      }
    ''').create();

    var test = await runTest(['test.dart'],
        environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('uses supported test configuration', () async {
    await d
        .file('global_test.yaml', jsonEncode({'verbose_trace': true}))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("failure", () => throw "oh no");
      }
    ''').create();

    var test = await runTest(['test.dart'],
        environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
    expect(test.stdout, emitsThrough(contains('dart:async')));
    await test.shouldExit(1);
  });

  test('uses supported runner configuration', () async {
    await d.file('global_test.yaml', jsonEncode({'reporter': 'json'})).create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("success", () {});
      }
    ''').create();

    var test = await runTest(['test.dart'],
        environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
    expect(test.stdout, emitsThrough(contains('"testStart"')));
    await test.shouldExit(0);
  });

  test('local configuration takes precedence', () async {
    await d
        .file('global_test.yaml', jsonEncode({'verbose_trace': true}))
        .create();

    await d
        .file('dart_test.yaml', jsonEncode({'verbose_trace': false}))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("failure", () => throw "oh no");
      }
    ''').create();

    var test = await runTest(['test.dart'],
        environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
    expect(test.stdout, neverEmits(contains('dart:isolate-patch')));
    await test.shouldExit(1);
  });

  group('disallows local-only configuration:', () {
    for (var field in [
      'skip', 'retry', 'test_on', 'paths', 'filename', 'names', 'tags', //
      'plain_names', 'include_tags', 'exclude_tags', 'pub_serve', 'add_tags',
      'define_platforms', 'allow_duplicate_test_names',
    ]) {
      test('for $field', () async {
        await d.file('global_test.yaml', jsonEncode({field: null})).create();

        await d.file('test.dart', '''
          import 'package:test/test.dart';

          void main() {
            test("success", () {});
          }
        ''').create();

        var test = await runTest(['test.dart'],
            environment: {'DART_TEST_CONFIG': 'global_test.yaml'});
        expect(
            test.stderr,
            containsInOrder(
                ["of global_test.yaml: $field isn't supported here.", '^^']));
        await test.shouldExit(exit_codes.data);
      });
    }
  });
}
