// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';

Future<void> customerTestingRunner() async {
  printProgress('${green}Running customer testing$reset');
  await runCommand(
    'git',
    const <String>[
      'fetch',
      'origin',
      'master',
    ],
    workingDirectory: flutterRoot,
  );
  await runCommand(
    'git',
    const <String>[
      'branch',
      '-f',
      'master',
      'origin/master',
    ],
    workingDirectory: flutterRoot,
  );
  if (Platform.environment case {'REVISION': final String revision}) {
    await runCommand(
      'git',
      <String>[
        'checkout',
        revision,
      ],
      workingDirectory: flutterRoot,
    );
  }
  final String winScript = path.join(flutterRoot, 'dev', 'customer_testing', 'ci.bat');
  await runCommand(
    Platform.isWindows? winScript: './ci.sh',
    <String>[],
    workingDirectory: path.join(flutterRoot, 'dev', 'customer_testing'),
  );
}
