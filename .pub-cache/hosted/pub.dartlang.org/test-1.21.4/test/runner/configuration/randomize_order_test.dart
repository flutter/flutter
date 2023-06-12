// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('shuffles test order when passed a seed', () async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test 1", () {});
        test("test 2", () {});
        test("test 3", () {});
        test("test 4", () {});
      }
    ''').create();

    // Test with a given seed
    var test =
        await runTest(['test.dart', '--test-randomize-ordering-seed=987654']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: test 4',
          '+1: test 3',
          '+2: test 1',
          '+3: test 2',
          '+4: All tests passed!'
        ]));
    await test.shouldExit(0);

    // Do not shuffle when passed 0
    test = await runTest(['test.dart', '--test-randomize-ordering-seed=0']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: test 1',
          '+1: test 2',
          '+2: test 3',
          '+3: test 4',
          '+4: All tests passed!'
        ]));
    await test.shouldExit(0);

    // Do not shuffle when passed nothing
    test = await runTest(['test.dart']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: test 1',
          '+1: test 2',
          '+2: test 3',
          '+3: test 4',
          '+4: All tests passed!'
        ]));
    await test.shouldExit(0);

    // Shuffle when passed random
    test =
        await runTest(['test.dart', '--test-randomize-ordering-seed=random']);
    expect(
        test.stdout,
        emitsInAnyOrder([
          contains('Shuffling test order with --test-randomize-ordering-seed'),
          isNot(contains(
              'Shuffling test order with --test-randomize-ordering-seed=0'))
        ]));
    await test.shouldExit(0);

    // Doesn't log about shuffling with the json reporter
    test = await runTest(
        ['test.dart', '--test-randomize-ordering-seed=random', '-r', 'json']);
    expect(test.stdout, neverEmits(contains('Shuffling test order')));
    await test.shouldExit(0);
  });

  test('test shuffling can be disabled in dart_test.yml', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'tags': {
                'doNotShuffle': {'allow_test_randomization': false}
              }
            }))
        .create();

    await d.file('test.dart', '''
      @Tags(['doNotShuffle'])
      import 'package:test/test.dart';

      void main() {
        test("test 1", () {});
        test("test 2", () {});
        test("test 3", () {});
        test("test 4", () {});
      }
    ''').create();

    var test =
        await runTest(['test.dart', '--test-randomize-ordering-seed=987654']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: test 1',
          '+1: test 2',
          '+2: test 3',
          '+3: test 4',
          '+4: All tests passed!'
        ]));
    await test.shouldExit(0);
  });

  test('shuffles each suite with the same seed', () async {
    await d.file('1_test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test 1.1", () {});
        test("test 1.2", () {});
        test("test 1.3", () {});
      }
    ''').create();

    await d.file('2_test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test 2.1", () {});
        test("test 2.2", () {});
        test("test 2.3", () {});
      }
    ''').create();

    var test = await runTest(['.', '--test-randomize-ordering-seed=12345']);
    expect(
        test.stdout,
        emitsInAnyOrder([
          containsInOrder([
            '.${Platform.pathSeparator}1_test.dart: test 1.2',
            '.${Platform.pathSeparator}1_test.dart: test 1.3',
            '.${Platform.pathSeparator}1_test.dart: test 1.1'
          ]),
          containsInOrder([
            '.${Platform.pathSeparator}2_test.dart: test 2.2',
            '.${Platform.pathSeparator}2_test.dart: test 2.3',
            '.${Platform.pathSeparator}2_test.dart: test 2.1'
          ]),
          contains('+6: All tests passed!')
        ]));
    await test.shouldExit(0);
  });

  test('shuffles groups as well as tests in groups', () async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
      group("Group 1", () {
        test("test 1.1", () {});
        test("test 1.2", () {});
        test("test 1.3", () {});
        test("test 1.4", () {});
       });
      group("Group 2", () {
        test("test 2.1", () {});
        test("test 2.2", () {});
        test("test 2.3", () {});
        test("test 2.4", () {});
       });
      }
    ''').create();

    // Test with a given seed
    var test =
        await runTest(['test.dart', '--test-randomize-ordering-seed=123']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: Group 2 test 2.4',
          '+1: Group 2 test 2.2',
          '+2: Group 2 test 2.1',
          '+3: Group 2 test 2.3',
          '+4: Group 1 test 1.4',
          '+5: Group 1 test 1.2',
          '+6: Group 1 test 1.1',
          '+7: Group 1 test 1.3',
          '+8: All tests passed!'
        ]));
    await test.shouldExit(0);
  });

  test('shuffles nested groups', () async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
      group("Group 1", () {
        test("test 1.1", () {});
        test("test 1.2", () {});
        group("Group 2", () {
          test("test 2.3", () {});
          test("test 2.4", () {});
        });
       });
      }
    ''').create();

    var test =
        await runTest(['test.dart', '--test-randomize-ordering-seed=123']);
    expect(
        test.stdout,
        containsInOrder([
          '+0: Group 1 test 1.1',
          '+1: Group 1 Group 2 test 2.4',
          '+2: Group 1 Group 2 test 2.3',
          '+3: Group 1 test 1.2',
          '+4: All tests passed!'
        ]));
    await test.shouldExit(0);
  });
}
