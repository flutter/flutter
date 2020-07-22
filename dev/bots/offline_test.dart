// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'run_command.dart';

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', 'flutter');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');

Future<void> main() async {
  await _runAndroidPackagingTests();
}

/// An integration test that verifies than an APK can be built offline after
/// downloading the prebuilt zip and running the appropriate precache command.
///
/// This uses cgroups to block internet access, and will only work on Linux
/// machines, though similar techniques could be used for macOS and Windows.
Future<void> _runAndroidPackagingTests() async {
  final String zipLocation = path.join(flutterRoot, 'flutter_zip');
  const String commit = '895b7ef6faf4e9c6ad641ad556855ff38fbd04bb';

  // Step 1: Prepare zip packaging.
  await runCommand(dart, <String>[
    path.join(flutterRoot, 'dev/bots/prepare_package.dart'),
    '--branch=master',
    '--output=$zipLocation',
    '--revision=$commit',
  ]);
  await runCommand('unzip', <String>[
    '*.tar.xz'
  ], workingDirectory: zipLocation);

  // Step 2: Invoke precache using zip packaged flutter
  await runCommand(path.join(zipLocation, 'flutter/bin/flutter'), <String>[
    'precache',
    '--android',
  ]);

  // Step 3: Create offline cgroup.
  await runCommand('groupadd', <String>['no-internet']);

  // Step 4: add rule for dropping network activity for this cgroup.
  await runCommand('iptables', <String>[
    '-I',
    'OUTPUT',
    '1',
    '-m',
    'owner',
    '--gid-owner',
    'no-internet',
    '-j',
    'DROP',
  ]);

  // Step 4: flutter build apk without internet.
  await runCommand('sg', <String>[
    'no-internet',
    path.join(zipLocation, 'flutter/bin/flutter'),
    'build',
    'apk'
  ], workingDirectory: path.join(zipLocation, 'flutter/examples/hello_world'));
}
