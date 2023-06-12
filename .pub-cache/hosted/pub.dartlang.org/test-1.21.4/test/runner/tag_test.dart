// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  setUp(() async {
    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("no tags", () {});
        test("a", () {}, tags: "a");
        test("b", () {}, tags: "b");
        test("bc", () {}, tags: ["b", "c"]);
      }
    ''').create();
  });

  group('--tags', () {
    test('runs all tests when no tags are specified', () async {
      var test = await runTest(['test.dart']);
      expect(test.stdout, tagWarnings(['a', 'b', 'c']));
      expect(test.stdout, emitsThrough(contains(': no tags')));
      expect(test.stdout, emitsThrough(contains(': a')));
      expect(test.stdout, emitsThrough(contains(': b')));
      expect(test.stdout, emitsThrough(contains(': bc')));
      expect(test.stdout, emitsThrough(contains('+4: All tests passed!')));
      await test.shouldExit(0);
    });

    test('runs a test with only a specified tag', () async {
      var test = await runTest(['--tags=a', 'test.dart']);
      expect(test.stdout, tagWarnings(['b', 'c']));
      expect(test.stdout, emitsThrough(contains(': a')));
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('runs a test with a specified tag among others', () async {
      var test = await runTest(['--tags=c', 'test.dart']);
      expect(test.stdout, tagWarnings(['a', 'b']));
      expect(test.stdout, emitsThrough(contains(': bc')));
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('with multiple tags, runs only tests matching all of them', () async {
      var test = await runTest(['--tags=b,c', 'test.dart']);
      expect(test.stdout, tagWarnings(['a']));
      expect(test.stdout, emitsThrough(contains(': bc')));
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('supports boolean selector syntax', () async {
      var test = await runTest(['--tags=b || c', 'test.dart']);
      expect(test.stdout, tagWarnings(['a']));
      expect(test.stdout, emitsThrough(contains(': b')));
      expect(test.stdout, emitsThrough(contains(': bc')));
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });

    test('prints no warnings when all tags are specified', () async {
      var test = await runTest(['--tags=a,b,c', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });
  });

  group('--exclude-tags', () {
    test("dosn't run a test with only an excluded tag", () async {
      var test = await runTest(['--exclude-tags=a', 'test.dart']);
      expect(test.stdout, tagWarnings(['b', 'c']));
      expect(test.stdout, emitsThrough(contains(': no tags')));
      expect(test.stdout, emitsThrough(contains(': b')));
      expect(test.stdout, emitsThrough(contains(': bc')));
      expect(test.stdout, emitsThrough(contains('+3: All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't run a test with an excluded tag among others", () async {
      var test = await runTest(['--exclude-tags=c', 'test.dart']);
      expect(test.stdout, tagWarnings(['a', 'b']));
      expect(test.stdout, emitsThrough(contains(': no tags')));
      expect(test.stdout, emitsThrough(contains(': a')));
      expect(test.stdout, emitsThrough(contains(': b')));
      expect(test.stdout, emitsThrough(contains('+3: All tests passed!')));
      await test.shouldExit(0);
    });

    test("dosn't load a suite with an excluded tag", () async {
      await d.file('test.dart', '''
        @Tags(const ["a"])

        import 'package:test/test.dart';

        void main() {
          throw "error";
        }
      ''').create();

      var test = await runTest(['--exclude-tags=a', 'test.dart']);
      expect(test.stdout, emits('No tests ran.'));
      await test.shouldExit(79);
    });

    test('allows unused tags', () async {
      var test = await runTest(['--exclude-tags=b,z', 'test.dart']);
      expect(test.stdout, tagWarnings(['a', 'c']));
      expect(test.stdout, emitsThrough(contains(': no tags')));
      expect(test.stdout, emitsThrough(contains(': a')));
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });

    test('supports boolean selector syntax', () async {
      var test = await runTest(['--exclude-tags=b && c', 'test.dart']);
      expect(test.stdout, tagWarnings(['a']));
      expect(test.stdout, emitsThrough(contains(': no tags')));
      expect(test.stdout, emitsThrough(contains(': a')));
      expect(test.stdout, emitsThrough(contains(': b')));
      expect(test.stdout, emitsThrough(contains('+3: All tests passed!')));
      await test.shouldExit(0);
    });

    test('prints no warnings when all tags are specified', () async {
      var test = await runTest(['--exclude-tags=a,b,c', 'test.dart']);
      expect(test.stdout, emitsThrough(contains(': no tags')));
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });

  group('with a tagged group', () {
    setUp(() async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          group("a", () {
            test("in", () {});
          }, tags: "a");

          test("out", () {});
        }
      ''').create();
    });

    test('includes tags specified on the group', () async {
      var test = await runTest(['-x', 'a', 'test.dart']);
      expect(test.stdout, emitsThrough(contains(': out')));
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    test('excludes tags specified on the group', () async {
      var test = await runTest(['-t', 'a', 'test.dart']);
      expect(test.stdout, emitsThrough(contains(': a in')));
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });
  });

  test('respects top-level @Tags annotations', () async {
    await d.file('test.dart', '''
      @Tags(const ['a'])
      import 'package:test/test.dart';

      void main() {
        test("foo", () {});
      }
    ''').create();

    var test = await runTest(['-x', 'a', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('No tests ran')));
    await test.shouldExit(79);
  });

  group('warning formatting', () {
    test('for multiple tags', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("foo", () {}, tags: ["a", "b"]);
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(lines(
              'Warning: Tags were used that weren\'t specified in dart_test.yaml.\n'
              '  a was used in the test "foo"\n'
              '  b was used in the test "foo"')));
      await test.shouldExit(0);
    });

    test('for multiple tests', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("foo", () {}, tags: "a");
          test("bar", () {}, tags: "a");
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(lines(
              'Warning: A tag was used that wasn\'t specified in dart_test.yaml.\n'
              '  a was used in:\n'
              '    the test "foo"\n'
              '    the test "bar"')));
      await test.shouldExit(0);
    });

    test('for groups', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          group("group", () {
            test("foo", () {});
            test("bar", () {});
          }, tags: "a");
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(lines(
              'Warning: A tag was used that wasn\'t specified in dart_test.yaml.\n'
              '  a was used in the group "group"')));
      await test.shouldExit(0);
    });

    test('for suites', () async {
      await d.file('test.dart', '''
        @Tags(const ["a"])
        import 'package:test/test.dart';

        void main() {
          test("foo", () {});
          test("bar", () {});
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(lines(
              'Warning: A tag was used that wasn\'t specified in dart_test.yaml.\n'
              '  a was used in the suite itself')));
      await test.shouldExit(0);
    });

    test("doesn't double-print a tag warning", () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("foo", () {}, tags: "a");
        }
      ''').create();

      var test = await runTest(['-p', 'vm,chrome', 'test.dart']);
      expect(
          test.stdout,
          emitsThrough(lines(
              'Warning: A tag was used that wasn\'t specified in dart_test.yaml.\n'
              '  a was used in the test "foo"')));
      expect(test.stdout, neverEmits(startsWith('Warning:')));
      await test.shouldExit(0);
    }, tags: 'chrome');
  });

  group('invalid tags', () {
    test('are disallowed by test()', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("foo", () {}, tags: "a b");
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(
              '  Failed to load "test.dart": Invalid argument(s): Invalid tag "a '
              'b". Tags must be (optionally hyphenated) Dart identifiers.'));
      await test.shouldExit(1);
    });

    test('are disallowed by group()', () async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          group("group", () {
            test("foo", () {});
          }, tags: "a b");
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(
              '  Failed to load "test.dart": Invalid argument(s): Invalid tag "a '
              'b". Tags must be (optionally hyphenated) Dart identifiers.'));
      await test.shouldExit(1);
    });

    test('are disallowed by @Tags()', () async {
      await d.file('test.dart', '''
        @Tags(const ["a b"])

        import 'package:test/test.dart';

        void main() {
          test("foo", () {});
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout,
          emitsThrough(lines('  Failed to load "test.dart":\n'
              '  Error on line 1, column 22: Invalid tag name. Tags must be '
              '(optionally hyphenated) Dart identifiers.')));
      await test.shouldExit(1);
    });
  });
}

/// Returns a [StreamMatcher] that asserts that a test emits warnings for [tags]
/// in order.
StreamMatcher tagWarnings(List<String> tags) => emitsInOrder([
      emitsThrough(
          "Warning: ${tags.length == 1 ? 'A tag was' : 'Tags were'} used that "
          "${tags.length == 1 ? "wasn't" : "weren't"} specified in "
          'dart_test.yaml.'),

      for (var tag in tags) emitsThrough(startsWith('  $tag was used in')),

      // Consume until the end of the warning block, and assert that it has no
      // further tags than the ones we specified.
      mayEmitMultiple(isNot(anyOf([contains(' was used in'), isEmpty]))),
      isEmpty,
    ]);

/// Returns a [StreamMatcher] that matches the lines of [string] in order.
StreamMatcher lines(String string) => emitsInOrder(string.split('\n'));
