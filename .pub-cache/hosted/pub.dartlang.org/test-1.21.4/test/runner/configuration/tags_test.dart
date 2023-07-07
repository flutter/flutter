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

  test('adds the specified tags', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'add_tags': ['foo', 'bar']
            }))
        .create();

    await d.file('test.dart', '''
      import 'package:test/test.dart';

      void main() {
        test("test", () {});
      }
    ''').create();

    var test = await runTest(['--exclude-tag', 'foo', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('No tests ran.')));
    await test.shouldExit(79);

    test = await runTest(['--exclude-tag', 'bar', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('No tests ran.')));
    await test.shouldExit(79);

    test = await runTest(['test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  group('tags', () {
    test("doesn't warn for tags that exist in the configuration", () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'tags': {'foo': null}
              }))
          .create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout, neverEmits(contains('Warning: Tags were used')));
      await test.shouldExit(0);
    });

    test('applies tag-specific configuration only to matching tests', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'tags': {
                  'foo': {'timeout': '0s'}
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test 1", () => Future.delayed(Duration.zero), tags: ['foo']);
          test("test 2", () => Future.delayed(Duration.zero));
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout,
          containsInOrder(['-1: test 1 [E]', '+1 -1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('supports tag selectors', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'tags': {
                  'foo && bar': {'timeout': '0s'}
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test 1", () => Future.delayed(Duration.zero), tags: ['foo']);
          test("test 2", () => Future.delayed(Duration.zero), tags: ['bar']);
          test("test 3", () => Future.delayed(Duration.zero),
              tags: ['foo', 'bar']);
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout,
          containsInOrder(['+2 -1: test 3 [E]', '+2 -1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('allows tag inheritance via add_tags', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'tags': {
                  'foo': null,
                  'bar': {
                    'add_tags': ['foo']
                  }
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test 1", () {}, tags: ['bar']);
          test("test 2", () {});
        }
      ''').create();

      var test = await runTest(['test.dart', '--tags', 'foo']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
    });

    // Regression test for #503.
    test('skips tests whose tags are marked as skip', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'tags': {
                  'foo': {'skip': 'some reason'}
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test 1", () => throw 'bad', tags: ['foo']);
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout, containsInOrder(['some reason', 'All tests skipped.']));
      await test.shouldExit(0);
    });
  });

  group('include_tags and exclude_tags', () {
    test('only runs tests with the included tags', () async {
      await d
          .file('dart_test.yaml', jsonEncode({'include_tags': 'foo && bar'}))
          .create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("zip", () {}, tags: "foo");
          test("zap", () {}, tags: "bar");
          test("zop", () {}, tags: ["foo", "bar"]);
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(
          test.stdout, containsInOrder(['+0: zop', '+1: All tests passed!']));
      await test.shouldExit(0);
    });

    test("doesn't run tests with the excluded tags", () async {
      await d
          .file('dart_test.yaml', jsonEncode({'exclude_tags': 'foo && bar'}))
          .create();

      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("zip", () {}, tags: "foo");
          test("zap", () {}, tags: "bar");
          test("zop", () {}, tags: ["foo", "bar"]);
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout,
          containsInOrder(['+0: zip', '+1: zap', '+2: All tests passed!']));
      await test.shouldExit(0);
    });
  });

  group('errors', () {
    group('tags', () {
      test('rejects an invalid tag type', () async {
        await d.file('dart_test.yaml', '{"tags": {12: null}}').create();

        var test = await runTest([]);
        expect(
            test.stderr, containsInOrder(['tags key must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid tag selector', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'tags': {'foo bar': null}
                }))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Invalid tags key: Expected end of input.', '^^^^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid tag map', () async {
        await d.file('dart_test.yaml', jsonEncode({'tags': 12})).create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['tags must be a map', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid tag configuration', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'tags': {
                    'foo': {'timeout': '12p'}
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Invalid timeout: expected unit', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects runner configuration', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'tags': {
                    'foo': {'filename': '*_blorp.dart'}
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(["filename isn't supported here.", '^^^^^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });
    });

    group('add_tags', () {
      test('rejects an invalid list type', () async {
        await d
            .file('dart_test.yaml', jsonEncode({'add_tags': 'foo'}))
            .create();

        var test = await runTest(['test.dart']);
        expect(
            test.stderr, containsInOrder(['add_tags must be a list', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid tag type', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'add_tags': [12]
                }))
            .create();

        var test = await runTest(['test.dart']);
        expect(
            test.stderr, containsInOrder(['Tag name must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid tag name', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'add_tags': ['foo bar']
                }))
            .create();

        var test = await runTest(['test.dart']);
        expect(
            test.stderr,
            containsInOrder([
              'Tag name must be an (optionally hyphenated) Dart identifier.',
              '^^^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });
    });

    group('include_tags', () {
      test('rejects an invalid type', () async {
        await d
            .file('dart_test.yaml', jsonEncode({'include_tags': 12}))
            .create();

        var test = await runTest(['test.dart']);
        expect(test.stderr,
            containsInOrder(['include_tags must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid selector', () async {
        await d
            .file('dart_test.yaml', jsonEncode({'include_tags': 'foo bar'}))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Invalid include_tags: Expected end of input.', '^^^^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });
    });

    group('exclude_tags', () {
      test('rejects an invalid type', () async {
        await d
            .file('dart_test.yaml', jsonEncode({'exclude_tags': 12}))
            .create();

        var test = await runTest(['test.dart']);
        expect(test.stderr,
            containsInOrder(['exclude_tags must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid selector', () async {
        await d
            .file('dart_test.yaml', jsonEncode({'exclude_tags': 'foo bar'}))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Invalid exclude_tags: Expected end of input.', '^^^^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });
    });
  });
}
