// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';

import 'package:test/test.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_core/src/util/io.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  group('presets', () {
    test("don't do anything by default", () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'}
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

      await (await runTest(['test.dart'])).shouldExit(0);
    });

    test('can be selected on the command line', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'}
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

      var test = await runTest(['-P', 'foo', 'test.dart']);
      expect(test.stdout,
          containsInOrder(['-1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('multiple presets can be selected', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'},
                  'bar': {
                    'paths': ['test.dart']
                  }
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

      var test = await runTest(['-P', 'foo,bar']);
      expect(test.stdout,
          containsInOrder(['-1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('the latter preset takes precedence', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'},
                  'bar': {'timeout': '30s'}
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

      await (await runTest(['-P', 'foo,bar', 'test.dart'])).shouldExit(0);

      var test = await runTest(['-P', 'bar,foo', 'test.dart']);
      expect(test.stdout,
          containsInOrder(['-1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('a preset takes precedence over the base configuration', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'}
                },
                'timeout': '30s'
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test", () => Future.delayed(Duration.zero));
        }
      ''').create();

      var test = await runTest(['-P', 'foo', 'test.dart']);
      expect(test.stdout,
          containsInOrder(['-1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);

      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '30s'}
                },
                'timeout': '00s'
              }))
          .create();

      await (await runTest(['-P', 'foo', 'test.dart'])).shouldExit(0);
    });

    test('a nested preset is activated', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'tags': {
                  'foo': {
                    'presets': {
                      'bar': {'timeout': '0s'}
                    },
                  },
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test 1", () => Future.delayed(Duration.zero), tags: "foo");
          test("test 2", () => Future.delayed(Duration.zero));
        }
      ''').create();

      var test = await runTest(['-P', 'bar', 'test.dart']);
      expect(test.stdout,
          containsInOrder(['+0 -1: test 1 [E]', '+1 -1: Some tests failed.']));
      await test.shouldExit(1);

      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '30s'}
                },
                'timeout': '00s'
              }))
          .create();

      await (await runTest(['-P', 'foo', 'test.dart'])).shouldExit(0);
    });
  });

  group('add_presets', () {
    test('selects a preset', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'}
                },
                'add_presets': ['foo']
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test", () => Future.delayed(Duration.zero));
        }
      ''').create();

      var test = await runTest(['test.dart']);
      expect(test.stdout,
          containsInOrder(['-1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('applies presets in selection order', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'},
                  'bar': {'timeout': '30s'}
                },
                'add_presets': ['foo', 'bar']
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test", () => Future.delayed(Duration.zero));
        }
      ''').create();

      await (await runTest(['test.dart'])).shouldExit(0);

      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {'timeout': '0s'},
                  'bar': {'timeout': '30s'}
                },
                'add_presets': ['bar', 'foo']
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stdout,
          containsInOrder(['-1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('allows preset inheritance via add_presets', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {
                    'add_presets': ['bar']
                  },
                  'bar': {'timeout': '0s'}
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

      var test = await runTest(['-P', 'foo', 'test.dart']);
      expect(test.stdout,
          containsInOrder(['+0 -1: test [E]', '-1: Some tests failed.']));
      await test.shouldExit(1);
    });

    test('allows circular preset inheritance via add_presets', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'presets': {
                  'foo': {
                    'add_presets': ['bar']
                  },
                  'bar': {
                    'add_presets': ['foo']
                  }
                }
              }))
          .create();

      await d.file('test.dart', '''
        import 'dart:async';

        import 'package:test/test.dart';

        void main() {
          test("test", () {});
        }
      ''').create();

      await (await runTest(['-P', 'foo', 'test.dart'])).shouldExit(0);
    });
  });

  group('errors', () {
    group('presets', () {
      test('rejects an invalid preset type', () async {
        await d.file('dart_test.yaml', '{"presets": {12: null}}').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['presets key must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid preset name', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'presets': {'foo bar': null}
                }))
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder([
              'presets key must be an (optionally hyphenated) Dart identifier.',
              '^^^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid preset map', () async {
        await d.file('dart_test.yaml', jsonEncode({'presets': 12})).create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['presets must be a map', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid preset configuration', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'presets': {
                    'foo': {'timeout': '12p'}
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Invalid timeout: expected unit', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects runner configuration in a non-runner context', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'tags': {
                    'foo': {
                      'presets': {
                        'bar': {'filename': '*_blorp.dart'}
                      }
                    }
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(["filename isn't supported here.", '^^^^^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('fails if an undefined preset is passed', () async {
        var test = await runTest(['-P', 'foo']);
        expect(test.stderr, emitsThrough(contains('Undefined preset "foo".')));
        await test.shouldExit(exit_codes.usage);
      });

      test('fails if an undefined preset is added', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'add_presets': ['foo', 'bar']
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            emitsThrough(contains('Undefined presets "foo" and "bar".')));
        await test.shouldExit(exit_codes.usage);
      });

      test('fails if an undefined preset is added in a nested context',
          () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'on_os': {
                    currentOS.identifier: {
                      'add_presets': ['bar']
                    }
                  }
                }))
            .create();

        var test = await runTest([]);
        expect(test.stderr, emitsThrough(contains('Undefined preset "bar".')));
        await test.shouldExit(exit_codes.usage);
      });
    });

    group('add_presets', () {
      test('rejects an invalid list type', () async {
        await d
            .file('dart_test.yaml', jsonEncode({'add_presets': 'foo'}))
            .create();

        var test = await runTest(['test.dart']);
        expect(test.stderr,
            containsInOrder(['add_presets must be a list', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid preset type', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'add_presets': [12]
                }))
            .create();

        var test = await runTest(['test.dart']);
        expect(test.stderr,
            containsInOrder(['Preset name must be a string', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects an invalid preset name', () async {
        await d
            .file(
                'dart_test.yaml',
                jsonEncode({
                  'add_presets': ['foo bar']
                }))
            .create();

        var test = await runTest(['test.dart']);
        expect(
            test.stderr,
            containsInOrder([
              'Preset name must be an (optionally hyphenated) Dart identifier.',
              '^^^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });
    });
  });
}
