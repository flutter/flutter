// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  group('a skipped expect', () {
    test('marks the test as skipped', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("skipped", () => expect(1, equals(2), skip: true));
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, emitsThrough(contains('~1: All tests skipped.')));
      await test.shouldExit(0);
    });

    test('prints the skip reason if there is one', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("skipped", () => expect(1, equals(2),
              reason: "1 is 2", skip: "is failing"));
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: skipped',
            '  Skip expect: is failing',
            '~1: All tests skipped.'
          ]));
      await test.shouldExit(0);
    });

    test("prints the expect reason if there's no skip reason", () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("skipped", () => expect(1, equals(2),
              reason: "1 is 2", skip: true));
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: skipped',
            '  Skip expect (1 is 2).',
            '~1: All tests skipped.'
          ]));
      await test.shouldExit(0);
    });

    test('prints the matcher description if there are no reasons', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("skipped", () => expect(1, equals(2), skip: true));
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: skipped',
            '  Skip expect (<2>).',
            '~1: All tests skipped.'
          ]));
      await test.shouldExit(0);
    });

    test('still allows the test to fail', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("failing", () {
            expect(1, equals(2), skip: true);
            expect(1, equals(2));
          });
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: failing',
            '  Skip expect (<2>).',
            '+0 -1: failing [E]',
            '  Expected: <2>',
            '    Actual: <1>',
            '+0 -1: Some tests failed.'
          ]));
      await test.shouldExit(1);
    });
  });

  group('markTestSkipped', () {
    test('prints the skip reason', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test('skipped', () {
            markTestSkipped('some reason');
          });
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: skipped',
            '  some reason',
            '~1: All tests skipped.',
          ]));
      await test.shouldExit(0);
    });

    test('still allows the test to fail', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test('failing', () {
            markTestSkipped('some reason');
            expect(1, equals(2));
          });
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: failing',
            '  some reason',
            '+0 -1: failing [E]',
            '  Expected: <2>',
            '    Actual: <1>',
            '+0 -1: Some tests failed.'
          ]));
      await test.shouldExit(1);
    });

    test('error when called after the test succeeded', () async {
      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          var skipCompleter = Completer();
          var waitCompleter = Completer();
          test('skip', () {
            skipCompleter.future.then((_) {
              waitCompleter.complete();
              markTestSkipped('some reason');
            });
          });

          // Trigger the skip completer in a following test to ensure that it
          // only fires after skip has completed successfully.
          test('wait', () async {
            skipCompleter.complete();
            await waitCompleter.future;
          });
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: skip',
            '+1: wait',
            '+0 -1: skip',
            'This test was marked as skipped after it had already completed. '
                'Make sure to use',
            '[expectAsync] or the [completes] matcher when testing async code.',
            '+1 -1: Some tests failed.'
          ]));
      await test.shouldExit(1);
    });
  });

  group('errors', () {
    test('when called after the test succeeded', () async {
      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          var skipCompleter = Completer();
          var waitCompleter = Completer();
          test("skip", () {
            skipCompleter.future.then((_) {
              waitCompleter.complete();
              expect(1, equals(2), skip: true);
            });
          });

          // Trigger the skip completer in a following test to ensure that it
          // only fires after skip has completed successfully.
          test("wait", () async {
            skipCompleter.complete();
            await waitCompleter.future;
          });
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: skip',
            '+1: wait',
            '+0 -1: skip',
            'This test was marked as skipped after it had already completed. '
                'Make sure to use',
            '[expectAsync] or the [completes] matcher when testing async code.',
            '+1 -1: Some tests failed.'
          ]));
      await test.shouldExit(1);
    });

    test('when an invalid type is used for skip', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("failing", () {
            expect(1, equals(2), skip: 10);
          });
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          containsInOrder(
              ['Invalid argument (skip)', '+0 -1: Some tests failed.']));
      await test.shouldExit(1);
    });
  });
}
