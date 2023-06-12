// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_core/src/util/io.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  group('on_platform', () {
    test('applies platform-specific configuration to matching tests', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'on_platform': {
                  'chrome': {'timeout': '0s'}
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test", () => Future.delayed(Duration.zero));
        }
      ''').create();

      var test = await runTest(['-p', 'chrome,vm', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder(
              ['-1: [Chrome] test [E]', '+1 -1: Some tests failed.']));
      await test.shouldExit(1);
    }, tags: ['chrome']);

    test('supports platform selectors', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'on_platform': {
                  'chrome || vm': {'timeout': '0s'}
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test", () => Future.delayed(Duration.zero));
        }
      ''').create();

      var test = await runTest(['-p', 'chrome,vm', 'test.dart']);
      expect(
          test.stdout,
          containsInOrder([
            '-1: [Chrome] test [E]',
            '-2: [VM] test [E]',
            '-2: Some tests failed.'
          ]));
      await test.shouldExit(1);
    }, tags: ['chrome']);

    group('errors', () {
      test('rejects an invalid selector type', () async {
        await d.file('dart_test.yaml', '{"on_platform": {12: null}}').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['on_platform key must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid selector', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_platform': {'foo bar': null}
                }))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder([
              'Invalid on_platform key: Expected end of input.',
              '^^^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a selector with an undefined variable', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_platform': {'foo': null}
                }))
            .create();

        await d.dir('test').create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['Undefined variable.', '^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid map', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_platform': {'linux': 12}
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['on_platform value must be a map.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid configuration', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_platform': {
                    'linux': {'timeout': '12p'}
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Invalid timeout: expected unit.', '^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects runner configuration', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_platform': {
                    'linux': {'filename': '*_blorp'}
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(["filename isn't supported here.", '^^^^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });
    });
  });

  group('on_os', () {
    test('applies OS-specific configuration on a matching OS', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'on_os': {
                  currentOS.identifier: {'filename': 'test_*.dart'}
                }
              }))
          .create();

      await d.file('foo_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("foo_test", () {});
        }
      ''').create();

      await d.file('test_foo.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test_foo", () {});
        }
      ''').create();

      var test = await runTest(['.']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: .${Platform.pathSeparator}test_foo.dart: test_foo',
            '+1: All tests passed!'
          ]));
      await test.shouldExit(0);
    });

    test("doesn't apply OS-specific configuration on a non-matching OS",
        () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'on_os': {
                  otherOS: {'filename': 'test_*.dart'}
                }
              }))
          .create();

      await d.file('foo_test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("foo_test", () {});
        }
      ''').create();

      await d.file('test_foo.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test_foo", () {});
        }
      ''').create();

      var test = await runTest(['.']);
      expect(
          test.stdout,
          containsInOrder([
            '+0: .${Platform.pathSeparator}foo_test.dart: foo_test',
            '+1: All tests passed!'
          ]));
      await test.shouldExit(0);
    });

    group('errors', () {
      test('rejects an invalid OS type', () async {
        await d.file('dart_test.yaml', '{"on_os": {12: null}}').create();

        var test = await runTest([]);
        expect(
            test.stderr, containsInOrder(['on_os key must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an unknown OS name', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_os': {'foo': null}
                }))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Invalid on_os key: No such operating system.', '^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid map', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_os': {'linux': 12}
                }))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr, containsInOrder(['on_os value must be a map.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid configuration', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_os': {
                    'linux': {'timeout': '12p'}
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Invalid timeout: expected unit.', '^^^^^']));
        await test.shouldExit(exit_codes.data);
      });
    });
  });
}
