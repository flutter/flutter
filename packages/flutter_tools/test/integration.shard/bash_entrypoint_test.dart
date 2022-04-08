// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';

import '../src/common.dart';
import 'test_utils.dart';

final String flutterRootPath = getFlutterRoot();
final Directory flutterRoot = fileSystem.directory(flutterRootPath);

Future<void> main() async {
  test('verify terminating flutter/bin/dart terminates the underlying dart process', () async {
    final Completer<void> childReadyCompleter = Completer<void>();
    String stdout = '';
    final Process process = await processManager.start(
        <String>[
          dartBash.path,
          listenForSigtermScript.path,
        ],
    );
    final Future<Object?> stdoutFuture = process.stdout
        .transform<String>(utf8.decoder)
        .forEach((String str) {
          stdout += str;
          if (stdout.contains('Ready to receive signals') && !childReadyCompleter.isCompleted) {
            childReadyCompleter.complete();
          }
        });
    // Ensure that the child app has registered its signal handler
    await childReadyCompleter.future;
    final bool killSuccess = process.kill();
    expect(killSuccess, true);
    // Wait for stdout to complete
    await stdoutFuture;
    // Ensure child exited successfully
    expect(
        await process.exitCode,
        0,
        reason: 'child process exited with code ${await process.exitCode}, and '
        'stdout:\n$stdout',
    );
    expect(stdout, contains('Successfully received SIGTERM!'));
  },
  skip: platform.isWindows); // [intended] Windows does not use the bash entrypoint

  test('verify the dart binary arch matches the host arch', () async {
    final HostPlatform dartArch = _identifyBinaryArch(dartBinary.path);
    final OperatingSystemUtils os = OperatingSystemUtils(
      processManager: processManager,
      fileSystem: fileSystem,
      platform: platform,
      logger: BufferLogger.test(),
    );
    expect(dartArch, os.hostPlatform);
  }, skip: !platform.isMacOS); // [intended] Calls macOS-specific commands
}

// Call `file` on the path and parse the output.
// This is macOS-specific.
HostPlatform _identifyBinaryArch(String path) {
  // Expect STDOUT like:
  //   bin/cache/dart-sdk/bin/dart: Mach-O 64-bit executable x86_64
  final RegExp pattern = RegExp(r'Mach-O 64-bit executable (\w+)');
  final ProcessResult result = processManager.runSync(
    <String>['file', dartBinary.path],
  );
  final RegExpMatch? match = pattern.firstMatch(result.stdout as String);
  if (match == null) {
    fail('Unrecognized STDOUT from `file`: "${result.stdout}"');
  }
  switch (match.group(1)) {
    case 'x86_64':
      return HostPlatform.darwin_x64;
    case 'arm64':
      return HostPlatform.darwin_arm;
    default:
      fail('Unexpected architecture ${match.group(1)}');
  }
}

// A test Dart app that will run until it receives SIGTERM
File get listenForSigtermScript {
  return flutterRoot
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('test')
      .childDirectory('integration.shard')
      .childDirectory('test_data')
      .childFile('listen_for_sigterm.dart')
      .absolute;
}

// The executable bash entrypoint for the Dart binary.
File get dartBash {
  return flutterRoot
      .childDirectory('bin')
      .childFile('dart')
      .absolute;
}

// The executable bash entrypoint for the Dart binary.
File get dartBinary {
  return flutterRoot
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('dart-sdk')
      .childDirectory('bin')
      .childFile('dart')
      .absolute;
}
