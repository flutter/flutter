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

  test('rejects an invalid fold_stack_frames', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'fold_stack_frames': 'flup'}))
        .create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['fold_stack_frames must be a map', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects multiple fold_stack_frames keys', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'fold_stack_frames': {
                'except': ['blah'],
                'only': ['blah']
              }
            }))
        .create();

    var test = await runTest(['test.dart']);
    expect(
        test.stderr,
        containsInOrder(
            ['Can only contain one of "only" or "except".', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects invalid fold_stack_frames keys', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'fold_stack_frames': {'invalid': 'blah'}
            }))
        .create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['Must be "only" or "except".', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects invalid fold_stack_frames values', () async {
    await d
        .file(
            'dart_test.yaml',
            jsonEncode({
              'fold_stack_frames': {'only': 'blah'}
            }))
        .create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['Folded packages must be strings', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an invalid pause_after_load', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'pause_after_load': 'flup'}))
        .create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['pause_after_load must be a boolean', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an invalid verbose_trace', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'verbose_trace': 'flup'}))
        .create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['verbose_trace must be a boolean', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an invalid chain_stack_traces', () async {
    await d
        .file('dart_test.yaml', jsonEncode({'chain_stack_traces': 'flup'}))
        .create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['chain_stack_traces must be a boolean', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an invalid retry', () async {
    await d.file('dart_test.yaml', jsonEncode({'retry': 'flup'})).create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['retry must be a non-negative int', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an negative retry values', () async {
    await d.file('dart_test.yaml', jsonEncode({'retry': -1})).create();

    var test = await runTest(['test.dart']);
    expect(test.stderr,
        containsInOrder(['retry must be a non-negative int', '^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an invalid js_trace', () async {
    await d.file('dart_test.yaml', jsonEncode({'js_trace': 'flup'})).create();

    var test = await runTest(['test.dart']);
    expect(
        test.stderr, containsInOrder(['js_trace must be a boolean', '^^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  group('reporter', () {
    test('rejects an invalid type', () async {
      await d.file('dart_test.yaml', jsonEncode({'reporter': 12})).create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['reporter must be a string', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid name', () async {
      await d
          .file('dart_test.yaml', jsonEncode({'reporter': 'non-existent'}))
          .create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr,
          containsInOrder(
              ['Unknown reporter "non-existent"', '^^^^^^^^^^^^^^']));
      await test.shouldExit(exit_codes.data);
    });
  });

  group('file_reporters', () {
    test('rejects an invalid type', () async {
      await d
          .file('dart_test.yaml', jsonEncode({'file_reporters': 12}))
          .create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr, containsInOrder(['file_reporters must be a map', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid value type', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'file_reporters': {'json': 12}
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr,
          containsInOrder(['file_reporters value must be a string', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid name', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'file_reporters': {'non-existent': 'out'}
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr,
          containsInOrder(
              ['Unknown reporter "non-existent"', '^^^^^^^^^^^^^^']));
      await test.shouldExit(exit_codes.data);
    });
  });

  test('rejects an invalid pub serve port', () async {
    await d.file('dart_test.yaml', jsonEncode({'pub_serve': 'foo'})).create();

    var test = await runTest(['test.dart']);
    expect(test.stderr, containsInOrder(['pub_serve must be an int', '^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  test('rejects an invalid concurrency', () async {
    await d.file('dart_test.yaml', jsonEncode({'concurrency': 'foo'})).create();

    var test = await runTest(['test.dart']);
    expect(
        test.stderr, containsInOrder(['concurrency must be an int', '^^^^^']));
    await test.shouldExit(exit_codes.data);
  });

  group('timeout', () {
    test('rejects an invalid type', () async {
      await d.file('dart_test.yaml', jsonEncode({'timeout': 12})).create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['timeout must be a string', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid format', () async {
      await d.file('dart_test.yaml', jsonEncode({'timeout': '12p'})).create();

      var test = await runTest(['test.dart']);
      expect(test.stderr,
          containsInOrder(['Invalid timeout: expected unit', '^^^^^']));
      await test.shouldExit(exit_codes.data);
    });
  });

  group('names', () {
    test('rejects an invalid list type', () async {
      await d.file('dart_test.yaml', jsonEncode({'names': 'vm'})).create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['names must be a list', '^^^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid member type', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'names': [12]
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['Names must be strings', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid RegExp', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'names': ['(foo']
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr,
          containsInOrder(['Invalid name: Unterminated group(foo', '^^^^^^']));
      await test.shouldExit(exit_codes.data);
    });
  });

  group('plain_names', () {
    test('rejects an invalid list type', () async {
      await d
          .file('dart_test.yaml', jsonEncode({'plain_names': 'vm'}))
          .create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr, containsInOrder(['plain_names must be a list', '^^^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid member type', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'plain_names': [12]
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['Names must be strings', '^^']));
      await test.shouldExit(exit_codes.data);
    });
  });

  group('platforms', () {
    test('rejects an invalid list type', () async {
      await d.file('dart_test.yaml', jsonEncode({'platforms': 'vm'})).create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr, containsInOrder(['platforms must be a list', '^^^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid member type', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'platforms': [12]
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr,
          containsInOrder(['Platform name must be a string', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid member name', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'platforms': ['foo']
              }))
          .create();

      await d.dir('test').create();

      var test = await runTest([]);
      expect(test.stderr, containsInOrder(['Unknown platform "foo"', '^^^^^']));
      await test.shouldExit(exit_codes.data);
    });
  });

  group('paths', () {
    test('rejects an invalid list type', () async {
      await d.file('dart_test.yaml', jsonEncode({'paths': 'test'})).create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['paths must be a list', '^^^^^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid member type', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'paths': [12]
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr, containsInOrder(['Paths must be strings', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an absolute path', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'paths': ['/foo']
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr, containsInOrder(['Paths must be relative.', '^^^^^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid URI', () async {
      await d
          .file(
              'dart_test.yaml',
              jsonEncode({
                'paths': ['[invalid]']
              }))
          .create();

      var test = await runTest(['test.dart']);
      expect(test.stderr,
          containsInOrder(['Invalid path: Invalid character', '^^^^^^^^^']));
      await test.shouldExit(exit_codes.data);
    }, skip: 'Broken by sdk#34988');
  });

  group('filename', () {
    test('rejects an invalid type', () async {
      await d.file('dart_test.yaml', jsonEncode({'filename': 12})).create();

      var test = await runTest(['test.dart']);
      expect(
          test.stderr, containsInOrder(['filename must be a string.', '^^']));
      await test.shouldExit(exit_codes.data);
    });

    test('rejects an invalid format', () async {
      await d.file('dart_test.yaml', jsonEncode({'filename': '{foo'})).create();

      var test = await runTest(['test.dart']);
      expect(test.stderr,
          containsInOrder(['Invalid filename: expected ",".', '^^^^^^']));
      await test.shouldExit(exit_codes.data);
    });
  });
}
