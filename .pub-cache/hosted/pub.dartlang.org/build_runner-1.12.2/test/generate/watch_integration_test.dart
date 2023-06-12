// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

Process process;
Stream<String> stdOutLines;

final String originalBuildContent = '''
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main() async {
  await run(['watch', '--delete-conflicting-outputs', '-o', 'output_dir'], [
    applyToRoot(new TestBuilder(
        buildExtensions: appendExtension('.copy', from: '.txt')))
  ]);
}
''';

void main() {
  group('watch integration tests', () {
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
          'glob'
        ]),
        d.dir('tool', [d.file('build.dart', originalBuildContent)]),
        d.dir('web', [d.file('a.txt', 'a'), d.file('a.no_output', 'a')]),
      ]).create();

      await pubGet('a');

      // Run a build and validate the output.
      process = await startDart('a', 'tool/build.dart');

      stdOutLines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      await nextSuccessfulBuild;
      await d.dir('a', [
        d.dir('web', [d.file('a.txt.copy', 'a')])
      ]).validate();
    });

    group('build script', () {
      test('updates the process to quit', () async {
        // Append a newline to the build script!
        await d.dir('a', [
          d.dir('tool', [d.file('build.dart', '$originalBuildContent\n')])
        ]).create();

        await nextStdOutLine('Terminating builds due to build script update');
        expect(await process.exitCode, equals(0));
      });
    });

    group('outputDir', () {
      test('updates on changed source file', () async {
        await d.dir('a', [
          d.dir('output_dir', [
            d.dir('web', [d.file('a.no_output', 'a')])
          ])
        ]).validate();

        await d.dir('a', [
          d.dir('web', [d.file('a.no_output', 'changed')])
        ]).create();
        await nextSuccessfulBuild;

        await d.dir('a', [
          d.dir('output_dir', [
            d.dir('web', [d.file('a.no_output', 'changed')])
          ])
        ]).validate();

        process.kill();
        await process.exitCode;
      });
    });
  });
}

Future get nextSuccessfulBuild =>
    stdOutLines.firstWhere((line) => line.contains('Succeeded after'));

Future nextStdOutLine(String message) =>
    stdOutLines.firstWhere((line) => line.contains(message));
