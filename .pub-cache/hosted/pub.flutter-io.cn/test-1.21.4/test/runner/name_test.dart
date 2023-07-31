// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  group('with test.dart?name="name" query', () {
    test('selects tests with matching names', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(['test.dart?name=selected']);

      expect(
        test.stdout,
        emitsThrough(contains('+2: All tests passed!')),
      );

      await test.shouldExit(0);
    });

    test('supports RegExp syntax', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test 1", () {});
          test("test 2", () => throw TestFailure("oh no"));
          test("test 3", () {});
        }
      ''').create();

      var test = await runTest(['test.dart?name=test [13]']);

      expect(
        test.stdout,
        emitsThrough(contains('+2: All tests passed!')),
      );

      await test.shouldExit(0);
    });

    test('applies only to the associated file', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("selected 2", () => throw TestFailure("oh no"));
        }
      ''').create();

      await d.file('test2.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(
        ['test.dart?name=selected 1', 'test2.dart?name=selected 2'],
      );

      expect(
        test.stdout,
        emitsThrough(contains('+2: All tests passed!')),
      );
      await test.shouldExit(0);
    });

    test('selects more narrowly when passed multiple times', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(['test.dart?name=selected&name=1']);

      expect(
        test.stdout,
        emitsThrough(contains('+1: All tests passed!')),
      );
      await test.shouldExit(0);
    });

    test('applies to directories', () async {
      await d.dir('dir', [
        d.file('first_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("selected 2", () => throw TestFailure("oh no"));
        }
      '''),
        d.file('second_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("selected 2", () => throw TestFailure("oh no"));
        }
      ''')
      ]).create();

      var test = await runTest(['dir?name=selected 1']);

      expect(
        test.stdout,
        emitsThrough(contains('+2: All tests passed!')),
      );
      await test.shouldExit(0);
    });

    test('produces an error when no tests match', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['test.dart?name=no']);

      expect(
        test.stderr,
        emitsThrough(contains('No tests were found.')),
      );

      await test.shouldExit(exit_codes.noTestsRan);
    });

    test("doesn't filter out load exceptions", () async {
      var test = await runTest(['file?name=name']);
      expect(
        test.stdout,
        containsInOrder([
          '-1: loading file [E]',
          '  Failed to load "file": Does not exist.'
        ]),
      );

      await test.shouldExit(1);
    });
  });

  group('with test.dart?full-name query,', () {
    test('matches with the complete test name', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected nope", () => throw TestFailure("oh no"));
        }
      ''').create();

      var test = await runTest(['test.dart?full-name=selected']);

      expect(
        test.stdout,
        emitsThrough(contains('+1: All tests passed!')),
      );
      await test.shouldExit(0);
    });

    test("doesn't support RegExp syntax", () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test 1", () => throw TestFailure("oh no"));
          test("test 2", () => throw TestFailure("oh no"));
          test("test [12]", () {});
        }
      ''').create();

      var test = await runTest(['test.dart?full-name=test [12]']);

      expect(
        test.stdout,
        emitsThrough(contains('+1: All tests passed!')),
      );
      await test.shouldExit(0);
    });

    test('applies only to the associated file', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("selected 2", () => throw TestFailure("oh no"));
        }
      ''').create();

      await d.file('test2.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(
        ['test.dart?full-name=selected 1', 'test2.dart?full-name=selected 2'],
      );

      expect(
        test.stdout,
        emitsThrough(contains('+2: All tests passed!')),
      );
      await test.shouldExit(0);
    });

    test('produces an error when no tests match', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['test.dart?full-name=no match']);

      expect(
        test.stderr,
        emitsThrough(contains('No tests were found.')),
      );
      await test.shouldExit(exit_codes.noTestsRan);
    });
  });

  test('test?name="name" and --name narrow the selection', () async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("selected 1", () {});
        test("nope 1", () => throw TestFailure("oh no"));
        test("selected 2", () => throw TestFailure("oh no"));
        test("nope 2", () => throw TestFailure("oh no"));
      }
    ''').create();

    var test = await runTest(['--name', '1', 'test.dart?name=selected']);

    expect(
      test.stdout,
      emitsThrough(contains('+1: All tests passed!')),
    );
    await test.shouldExit(0);
  });

  test('test?name="name" and test?full-name="name" throws', () async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("selected 1", () {});
        test("nope 1", () => throw TestFailure("oh no"));
        test("selected 2", () => throw TestFailure("oh no"));
        test("nope 2", () => throw TestFailure("oh no"));
      }
    ''').create();

    var test = await runTest(['test.dart?name=selected&full-name=selected 1']);

    await test.shouldExit(64);
  });

  group('with the --name flag,', () {
    test('selects tests with matching names', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(['--name', 'selected', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });

    test('supports RegExp syntax', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test 1", () {});
          test("test 2", () => throw TestFailure("oh no"));
          test("test 3", () {});
        }
      ''').create();

      var test = await runTest(['--name', 'test [13]', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });

    test('selects more narrowly when passed multiple times', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test =
          await runTest(['--name', 'selected', '--name', '1', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('produces an error when no tests match', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['--name', 'no match', 'test.dart']);
      expect(
          test.stderr,
          emitsThrough(
              contains('No tests match regular expression "no match".')));
      await test.shouldExit(exit_codes.noTestsRan);
    });

    test("doesn't filter out load exceptions", () async {
      var test = await runTest(['--name', 'name', 'file']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: loading file [E]',
            '  Failed to load "file": Does not exist.'
          ]));
      await test.shouldExit(1);
    });
  });

  group('with the --plain-name flag,', () {
    test('selects tests with matching names', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(['--plain-name', 'selected', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't support RegExp syntax", () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test 1", () => throw TestFailure("oh no"));
          test("test 2", () => throw TestFailure("oh no"));
          test("test [12]", () {});
        }
      ''').create();

      var test = await runTest(['--plain-name', 'test [12]', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('selects more narrowly when passed multiple times', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("selected 1", () {});
          test("nope", () => throw TestFailure("oh no"));
          test("selected 2", () {});
        }
      ''').create();

      var test = await runTest(
          ['--plain-name', 'selected', '--plain-name', '1', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('produces an error when no tests match', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['--plain-name', 'no match', 'test.dart']);
      expect(test.stderr, emitsThrough(contains('No tests match "no match".')));
      await test.shouldExit(exit_codes.noTestsRan);
    });
  });

  test('--name and --plain-name together narrow the selection', () async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("selected 1", () {});
        test("nope", () => throw TestFailure("oh no"));
        test("selected 2", () {});
      }
    ''').create();

    var test =
        await runTest(['--name', '.....', '--plain-name', 'e', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
    await test.shouldExit(0);
  });
}
