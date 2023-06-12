// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

void main() {
  group('serve integration tests', () {
    Process pubProcess;
    Stream<String> pubStdOutLines;

    setUp(() async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
        ]),
        d.dir('lib', [
          d.file('example.dart', "String hello = 'hello'"),
        ]),
      ]).create();

      await pubGet('a');
      pubProcess = await startPub('a', 'run', args: ['build_runner', 'serve']);
      pubStdOutLines = pubProcess.stdout
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .asBroadcastStream();
    });

    tearDown(() async {
      pubProcess.kill();
      await pubProcess.exitCode;
    });

    test('warns if it didnt find a directory to serve', () async {
      expect(pubStdOutLines,
          emitsThrough(contains('Found no known web directories to serve')),
          reason: 'never saw the warning');
    });
  });
}
