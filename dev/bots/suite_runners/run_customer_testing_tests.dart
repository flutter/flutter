// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';

// The DevTools tests build DevTools from source and take longer than the rest
// of the registry combined, so they get their own shard.
const String _devtoolsTestsGlob = 'flutter_devtools*.test';

// Flame only runs its full test suites on Linux, where they take as long as the
// rest of the registry, so they get their own Linux shard.
const String _flameTestsGlob = 'flame.test';

Future<void> customerTestingRunner() => _runCustomerTesting(<String>[
  '--exclude=$_devtoolsTestsGlob',
  if (Platform.isLinux) '--exclude=$_flameTestsGlob',
]);

Future<void> customerTestingDevtoolsRunner() =>
    _runCustomerTesting(<String>['--include=$_devtoolsTestsGlob']);

Future<void> customerTestingFlameRunner() =>
    _runCustomerTesting(<String>['--include=$_flameTestsGlob']);

Future<void> _runCustomerTesting(List<String> ciArguments) async {
  printProgress('${green}Running customer testing$reset');
  await runCommand('git', const <String>[
    'fetch',
    'origin',
    'master',
  ], workingDirectory: flutterRoot);
  await runCommand('git', const <String>[
    'branch',
    '-f',
    'master',
    'origin/master',
  ], workingDirectory: flutterRoot);
  final Map<String, String> env = Platform.environment;
  final String? revision = env['REVISION'];
  if (revision != null) {
    await runCommand('git', <String>['checkout', revision], workingDirectory: flutterRoot);
  }
  await runCommand(
    path.join(flutterRoot, 'dev', 'customer_testing', Platform.isWindows ? 'ci.bat' : 'ci.sh'),
    ciArguments,
    workingDirectory: path.join(flutterRoot, 'dev', 'customer_testing'),
  );
}
