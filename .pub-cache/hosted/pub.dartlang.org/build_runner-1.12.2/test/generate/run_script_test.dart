// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:convert';

import 'package:io/io.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

void main() {
  group('run_script validation tests', () {
    // The TestBuilder() will create a `*.copy` of
    // whatever it is given, so we'll use it to create a
    // copy of an executable Dart file (bin/main.dart).
    //
    // The expected output of running the generated file
    // will be "it works!".
    setUp(() async {
      var executableFileContent = '''
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print("it works!");
  } else if (args[0] == "throw") {
    throw StateError('oh no!');
  } else if (args[0] == "print_uri") {
    print(Platform.script);
  } else {
    print(args.join(';'));
  }
}
      ''';
      var originalBuildContent = '''
import 'dart:io';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  exitCode = await run(
      args, [applyToRoot(new TestBuilder(
        buildExtensions: {
          '.dart': ['.copy.dart'],
          '.txt': ['.txt.copy']
        }
      ))]);
}
''';

      // Create the sandbox directory, including a build script,
      // and the actual executable file.
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
          'glob',
        ]),
        d.dir('bin', [
          d.file('main.dart', executableFileContent),
          d.file('main.txt', 'cannot run this'),
        ]),
        d.dir('tool', [d.file('build.dart', originalBuildContent)]),
      ]).create();

      // Get the dependencies.
      await pubGet('a');

      // We don't need to run a build in the setUp() closure, because
      // that's not the functionality we're testing.
    });

    test('at least one argument must be provided', () async {
      // Should throw error 64.
      var result = await runDart('a', 'tool/build.dart',
          args: ['run', '--output', 'build']);
      expect(result.exitCode, ExitCode.usage.code,
          reason: result.stderr as String);
      expect(result.stdout, contains('Must specify an executable to run.'));
      expect(result.stdout, contains('Usage: build_runner run'));
    });

    test('extension must be .dart', () async {
      // Should throw error 64.
      var result = await runDart('a', 'tool/build.dart',
          args: ['run', 'bin/main.txt.copy', '--output', 'build']);
      expect(result.exitCode, ExitCode.usage.code,
          reason: result.stderr as String);
      expect(result.stdout,
          contains('is not a valid Dart file and cannot be run in the VM.'));
    });

    test('target file must actually exist', () async {
      // Should throw error 64.
      var result = await runDart('a', 'tool/build.dart',
          args: ['run', 'bin/nonexistent.dart', '--output', 'build']);
      expect(result.exitCode, ExitCode.ioError.code,
          reason: result.stderr as String);
      expect(
          result.stdout,
          contains(
              'Could not spawn isolate. Ensure that your file is in a valid directory'));
    });

    test('runs the built version of the desired script', () async {
      // Run the generated script, and examine its output.
      var result = await runDart('a', 'tool/build.dart',
          args: ['run', 'bin/main.copy.dart', '--output', 'build']);
      var lastLine =
          LineSplitter().convert(result.stdout as String).last.trim();
      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(lastLine, 'it works!', reason: result.stderr as String);
    });

    test('runs even if no output directory is given', () async {
      // Verify that the script runs (it'll be generated into a temp dir)
      var result = await runDart('a', 'tool/build.dart',
          args: ['run', 'bin/main.copy.dart']);
      var lastLine =
          LineSplitter().convert(result.stdout as String).last.trim();
      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(lastLine, 'it works!', reason: result.stderr as String);
    });

    test('passes input args', () async {
      // Run the generated script, and examine its output.
      var result = await runDart('a', 'tool/build.dart', args: [
        'run',
        'bin/main.copy.dart',
        '--output',
        'build',
        '--',
        'a',
        'b',
        'c'
      ]);
      var lastLine =
          LineSplitter().convert(result.stdout as String).last.trim();
      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(lastLine, 'a;b;c', reason: result.stderr as String);
    });

    test('errors thrown in script result in non-zero exit', () async {
      // Run the generated script, and examine its output.
      var result = await runDart('a', 'tool/build.dart', args: [
        'run',
        'bin/main.copy.dart',
        '--output',
        'build',
        '--',
        'throw'
      ]);
      expect(result.exitCode, 1, reason: result.stderr as String);
      expect(result.stdout, contains('Unhandled error from script:'));
      expect(result.stdout, contains('Bad state: oh no!'));
    });

    // TODO (thosakwe): Test for stack trace
    test('stack trace from errors is displayed in verbose mode', () async {
      // Run the generated script, and examine its output.
      var result = await runDart('a', 'tool/build.dart', args: [
        'run',
        'bin/main.copy.dart',
        '--verbose',
        '--output',
        'build',
        '--',
        'throw'
      ]);
      expect(result.exitCode, 1, reason: result.stderr as String);
      expect(result.stdout, contains('Unhandled error from script:'));
      expect(result.stdout, contains('Bad state: oh no!'));
      // bin/main.copy.dart 5:5  main
      expect(result.stdout, contains('bin/main.copy.dart'));
      expect(result.stdout, contains('7:5'));
      expect(result.stdout, contains('main'));
    });
  });
}
