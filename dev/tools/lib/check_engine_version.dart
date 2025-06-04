// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:process_runner/process_runner.dart';

/// Checks if the contents of [versionPath] are the same as the output of [scriptPath].
///
/// ```dart
/// final bool success = await checkEngineVersion(
///   versionPath: 'bin/internal/engine.version',
///   scriptPath: 'bin/internal/last_engine_commit.sh',
/// );
/// ```
///
/// If the file described at [versionPath] does not exist, this check returns `true`.
///
/// If [onlyIfVersionChanged] is `true` (default), and the file described by [versionPath]
/// has not changed at the current commit SHA compared to HEAD, `true` is immediately
/// returned without any additional checks.
@useResult
Future<bool> checkEngineVersion({
  required String versionPath,
  required String scriptPath,
  bool onlyIfVersionChanged = true,
  @visibleForTesting FileSystem? fileSystem,
  @visibleForTesting ProcessRunner? runner,
  @visibleForTesting StringSink? stderr,
}) async {
  fileSystem ??= const LocalFileSystem();
  runner ??= ProcessRunner();
  stderr ??= io.stderr;

  // If the file does not exist, immediately return true.
  final File versionFile = fileSystem.file(versionPath);
  if (!versionFile.existsSync()) {
    stderr.writeln('$versionPath does not exist, skipping engine.version check');
    return true;
  }

  // The file exists. Do we need to verify it was updated?
  if (onlyIfVersionChanged && !await _wasUpdated(versionPath, runner, stderr)) {
    stderr.writeln('$versionPath has not changed, skipping engine.version check');
    return true;
  }

  // Get the expected value.
  final ProcessRunnerResult expectedShaResult = await runner.runProcess(<String>[
    scriptPath,
  ], failOk: true);
  if (expectedShaResult.exitCode != 0) {
    stderr.writeln('$scriptPath failed: ${expectedShaResult.stdout}');
    return false;
  }
  final String expectedSha = expectedShaResult.stdout.trim();

  // Get the actual value.
  final String actualSha = versionFile.readAsStringSync().trim();

  // Compare
  if (expectedSha != actualSha) {
    stderr.writeln('$scriptPath output $expectedSha, but $versionPath is $actualSha');
    return false;
  }

  return true;
}

Future<bool> _wasUpdated(String path, ProcessRunner runner, StringSink stderr) async {
  final ProcessRunnerResult diffResult = await runner.runProcess(<String>[
    'git',
    'diff',
    '--name-only',
    '--relative',
    'master...HEAD',
    '--',
    path,
  ], failOk: true);
  if (diffResult.exitCode != 0) {
    stderr.writeln('git diff failed: ${diffResult.stdout}');
    return false;
  }

  final String diffOutput = diffResult.stdout.trim();
  return diffOutput.split('\n').contains(path);
}
