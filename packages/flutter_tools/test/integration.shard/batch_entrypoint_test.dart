// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

final String flutterRootPath = getFlutterRoot();
final Directory flutterRoot = fileSystem.directory(flutterRootPath);

Future<void> main() async {
  // Regression test for https://github.com/flutter/flutter/issues/132592
  test('flutter/bin/dart updates the Dart SDK', () async {
    // Run the Dart entrypoint once to ensure the Dart SDK is downloaded.
    await runDartBatch();

    // Remove the Dart SDK stamp to cause the Dart batch entrypoint to
    // re-download the Dart SDK.
    expect(dartSdkStamp.existsSync(), true);
    dartSdkStamp.deleteSync();

    // Run the Dart batch entrypoint again to trigger the Dart SDK update.
    final stdout = await runDartBatch();

    // Check the Dart SDK was re-downloaded and extracted without overwriting
    // unexpected files.
    // See: https://github.com/flutter/flutter/issues/132592
    expect(stdout, contains('Downloading Dart SDK from Flutter engine ...'));
    expect(stdout, contains('Expanding downloaded archive...'));
    expect(stdout, isNot(contains('Use the -Force parameter')));
  },
  skip: !platform.isWindows); // [intended] Only Windows uses the batch entrypoint
}

Future<String> runDartBatch() async {
  String stdout = '';
  final Process process = await processManager.start(
      <String>[
        dartBatch.path
      ],
  );
  final Future<Object?> stdoutFuture = process.stdout
      .transform<String>(utf8.decoder)
      .forEach((String str) {
        stdout += str;
      });
  // Wait for stdout to complete
  await stdoutFuture;
  // Ensure child exited successfully
  expect(
      await process.exitCode,
      0,
      reason: 'child process exited with code ${await process.exitCode}, and '
      'stdout:\n$stdout',
  );

  // Check the Dart tool prints the expected output.
  expect(stdout, contains('A command-line utility for Dart development.'));
  expect(stdout, contains('Usage: dart <command|dart-file> [arguments]'));

  return stdout;
}

// The executable batch entrypoint for the Dart binary.
File get dartBatch {
  return flutterRoot
      .childDirectory('bin')
      .childFile('dart')
      .absolute;
}

// The Dart SDK's stamp file.
File get dartSdkStamp {
  return flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childFile('engine-dart-sdk.stamp')
      .absolute;
}
