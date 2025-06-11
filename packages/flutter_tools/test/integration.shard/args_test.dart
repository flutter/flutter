// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

final Future<Directory> tempDir = fileSystem.systemTempDirectory.createTemp('flutter_args_test');

void main() {
  tearDownAll(() async {
    tryToDelete(await tempDir);
  });

  testWithoutContext('accepts top-level commands in a trailing @file', () async {
    final File argsFile = await createArgsFile(<String>['help']);
    await verifyFlutterOutput(
      <String>['@${argsFile.path}'],
      exitCode: 0,
      stdout: startsWith('Manage your Flutter app development.'),
    );
  });

  testWithoutContext('accepts top-level args in a trailing @file', () async {
    final File argsFile = await createArgsFile(<String>['--help']);
    await verifyFlutterOutput(
      <String>['@${argsFile.path}'],
      exitCode: 0,
      stdout: startsWith('Manage your Flutter app development.'),
    );
  });

  testWithoutContext('accepts command-level args in a trailing @file', () async {
    final File argsFile = await createArgsFile(<String>['--no-pub', '--help']);
    await verifyFlutterOutput(
      <String>['test', '@${argsFile.path}'],
      exitCode: 0,
      stdout: startsWith('Run Flutter unit tests for the current project.'),
    );
  });

  testWithoutContext('accepts command and args in a trailing @file', () async {
    final File argsFile = await createArgsFile(<String>['test', '--no-pub', '--help']);
    await verifyFlutterOutput(
      <String>['@${argsFile.path}'],
      exitCode: 0,
      stdout: startsWith('Run Flutter unit tests for the current project.'),
    );
  });
}

/// Create an `args.txt` file in a temporary subdirectory of [tempDir] with
/// [args] written as lines.
Future<File> createArgsFile(List<String> args) async {
  final Directory argsDir = (await tempDir).createTempSync('args');
  final File file = fileSystem.file(fileSystem.path.join(argsDir.path, 'args.txt'));
  file.writeAsStringSync(args.join(platform.isWindows ? '\r\n' : '\n'));
  return file;
}

/// Runs 'flutter' with [args] and verifies the [exitCode], [stdout] and
/// [stderr].
Future<void> verifyFlutterOutput(
  List<String> args, {
  int? exitCode,
  Matcher? stdout,
  Matcher? stderr,
}) async {
  final ProcessResult exec = await _runFlutter(args);

  if (exitCode != null) {
    expect(
      exec.exitCode,
      exitCode,
      reason:
          '"flutter $args" returned code ${exec.exitCode}\n\nstdout:\n'
          '${exec.stdout}\nstderr:\n${exec.stderr}',
    );
  }

  if (stdout != null) {
    expect(
      exec.stdout.toString(),
      stdout,
      reason:
          '"flutter $args" returned code ${exec.exitCode}\n\nstdout:\n'
          '${exec.stdout}\nstderr:\n${exec.stderr}',
    );
  }

  if (stderr != null) {
    expect(
      exec.stderr.toString(),
      stderr,
      reason:
          '"flutter $args" returned code ${exec.exitCode}\n\nstdout:\n'
          '${exec.stdout}\nstderr:\n${exec.stderr}',
    );
  }
}

Future<ProcessResult> _runFlutter(List<String> args) async {
  args = <String>['--no-color', '--no-version-check', ...args];

  return Process.run(
    flutterBin, // Uses the precompiled flutter tool for faster tests,
    args,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}
