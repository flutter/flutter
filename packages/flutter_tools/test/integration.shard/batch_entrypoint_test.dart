// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('windows')
library;

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/tools_entrypoint_env.dart';
import 'test_utils.dart';

final String flutterRootPath = getFlutterRoot();
final Directory flutterRoot = fileSystem.directory(flutterRootPath);

Future<void> main() async {
  // Regression test for https://github.com/flutter/flutter/issues/132592
  test('flutter/bin/dart updates the Dart SDK without hanging', () async {
    // Run the Dart entrypoint once to ensure the Dart SDK is downloaded.
    await runDartBatch();

    expect(dartSdkStamp.existsSync(), true);

    // Remove the Dart SDK stamp and run the Dart entrypoint again to trigger
    // the Dart SDK update.
    dartSdkStamp.deleteSync();
    final Future<String> runFuture = runDartBatch();
    final timer = Timer(const Duration(minutes: 5), () {
      // This print is useful for people debugging this test. Normally we would
      // avoid printing in a test but this is an exception because it's useful
      // ambient information.
      // ignore: avoid_print
      print(
        'The Dart batch entrypoint did not complete after 5 minutes. '
        'Historically this is a sign that 7-Zip zip extraction is waiting for '
        'the user to confirm they would like to overwrite files. '
        "This likely means the test isn't a flake and will fail. "
        'See: https://github.com/flutter/flutter/issues/132592',
      );
    });

    final String output = await runFuture;
    timer.cancel();

    // Check the Dart SDK was re-downloaded and extracted.
    // If 7-Zip is installed, unexpected overwrites causes this to hang.
    // If 7-Zip is not installed, unexpected overwrites results in error messages.
    // See: https://github.com/flutter/flutter/issues/132592
    expect(dartSdkStamp.existsSync(), true);
    expect(output, contains('Downloading Dart SDK from Flutter engine ...'));
    // Do not assert on the exact unzipping method, as this could change on CI
    expect(output, contains(RegExp(r'Expanding downloaded archive with (.*)...')));
    expect(output, isNot(contains('Use the -Force parameter' /* Luke */)));
  });

  // Regresion test for https://github.com/flutter/flutter/issues/171024.
  test('shared.bat does not rebuild the flutter tool on a no-op pub upgrade', () async {
    setupToolsEntrypointNewerPubpsec();

    // Run flutter --version, observe we rebuild the tool.
    ProcessResult result = await processManager.run(<String>[flutterBatch.path, '--version']);
    expect(result.stderr, contains('Building flutter tool'));

    // Now do it again.
    result = await processManager.run(<String>[flutterBatch.path, '--version']);
    expect(result.stderr, isNot(contains('Building flutter tool...')));
  });

  // Regression test for https://github.com/flutter/flutter/issues/197389.
  test('dart.bat adds bundled mingit to PATH and checks for git', () async {
    final Directory tempDir = createResolvedTempDirectorySync('batch_entrypoint_test.');
    addTearDown(() => tryToDelete(tempDir));

    // Copy the real dart.bat into a temp directory acting as FLUTTER_ROOT so we
    // can test with and without bin\mingit and without modifying the real
    // Flutter repo checkout.
    final String tempDartBatchPath = fileSystem.path.join(tempDir.path, 'bin', 'dart.bat');
    writeFile(tempDartBatchPath, dartBatch.readAsStringSync());

    // Stub shared.bat to verify git is on PATH.
    writeFile(
      fileSystem.path.join(tempDir.path, 'bin', 'internal', 'shared.bat'),
      '@ECHO off\r\nWHERE git\r\nEXIT %ERRORLEVEL%\r\n',
    );

    // Strip PATH down to System32 and WindowsPowerShell so any git installed
    // on the local system doesn't affect the results (but WHERE and
    // powershell.exe are still available).
    final String systemRoot = platform.environment['SystemRoot'] ?? r'C:\Windows';
    final environment = <String, String>{
      for (final MapEntry<String, String> entry in platform.environment.entries)
        if (entry.key.toUpperCase() != 'PATH') entry.key: entry.value,
      'PATH': <String>[
        fileSystem.path.join(systemRoot, 'System32'),
        fileSystem.path.join(systemRoot, 'System32', 'WindowsPowerShell', 'v1.0'),
      ].join(';'),
    };

    /// A helper to run bin/dart.bat with the reduced PATH.
    Future<ProcessResult> runDartWithReducedPath() {
      return processManager.run(
        <String>[tempDartBatchPath],
        workingDirectory: tempDir.path,
        environment: environment,
        includeParentEnvironment: false,
      );
    }

    // Without bundled mingit, dart.bat fails with a clear error (this verifies
    // the test isn't false-passing due to a system git).
    expect(
      await runDartWithReducedPath(),
      const ProcessResultMatcher(
        exitCode: 1,
        stdoutPattern: 'Error: Unable to find git in your PATH.',
      ),
    );

    // Create a stub mingit.
    final String mingitPath = fileSystem.path.join(tempDir.path, 'bin', 'mingit', 'cmd', 'git.bat');
    writeFile(mingitPath, '@ECHO off\r\n');

    // With mingit, dart.bat should run without any error and including the path
    // to the bundled mingit.
    expect(await runDartWithReducedPath(), ProcessResultMatcher(stdoutPattern: mingitPath));
  });
}

Future<String> runDartBatch() async {
  var output = '';
  final Process process = await processManager.start(<String>[dartBatch.path]);
  final Future<Object?> stdoutFuture = process.stdout.transform<String>(utf8.decoder).forEach((
    String str,
  ) {
    output += str;
  });
  final Future<Object?> stderrFuture = process.stderr.transform<String>(utf8.decoder).forEach((
    String str,
  ) {
    output += str;
  });

  // Wait for the output to complete
  await Future.wait(<Future<Object?>>[stdoutFuture, stderrFuture]);
  // Ensure child exited successfully
  expect(
    await process.exitCode,
    0,
    reason:
        'child process exited with code ${await process.exitCode}, and '
        'output:\n$output',
  );

  // Check the Dart tool prints the expected output.
  expect(output, contains('A command-line utility for Dart development.'));
  expect(output, contains('Usage: dart <command|dart-file> [arguments]'));

  return output;
}

// The executable batch entrypoint for the Dart binary.
File get dartBatch {
  return flutterRoot.childDirectory('bin').childFile('dart.bat').absolute;
}

// The executable batch entrypoint for the Flutter binary.
File get flutterBatch {
  return flutterRoot.childDirectory('bin').childFile('flutter.bat').absolute;
}

// The Dart SDK's stamp file.
File get dartSdkStamp {
  return flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childFile('engine-dart-sdk.stamp')
      .absolute;
}
