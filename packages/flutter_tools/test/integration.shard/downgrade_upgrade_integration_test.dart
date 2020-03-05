// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../src/common.dart';

const String _kInitialVersion = 'v1.9.1+hotfix.6';
const String _kBranch = 'stable';
const FileSystem fileSystem = LocalFileSystem();
const ProcessManager processManager = LocalProcessManager();
final Stdio stdio = Stdio();
final ProcessUtils processUtils = ProcessUtils(processManager: processManager, logger: StdoutLogger(
  terminal: AnsiTerminal(
    platform: const LocalPlatform(),
    stdio: stdio,
  ),
  stdio: stdio,
  outputPreferences: OutputPreferences.test(wrapText: true),
  timeoutConfiguration: const TimeoutConfiguration(),
));
final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

/// A test for flutter upgrade & downgrade that checks out a parallel flutter repo.
void main() {
  Directory parentDirectory;

  setUp(() {
    parentDirectory = fileSystem.systemTempDirectory
      .createTempSync('flutter_tools.');
    parentDirectory.createSync(recursive: true);
  });

  tearDown(() {
    try {
      parentDirectory.deleteSync(recursive: true);
    } on FileSystemException {
      print('Failed to delete test directory');
    }
  });

  test('Can upgrade and downgrade a Flutter checkout', () async {
    final Directory testDirectory = parentDirectory.childDirectory('flutter');
    testDirectory.createSync(recursive: true);

    // Enable longpaths for windows integration test.
    await processManager.run(<String>[
      'git', 'config', '--system', 'core.longpaths', 'true',
    ]);

    // Step 1. Clone the dev branch of flutter into the test directory.
    await processUtils.stream(<String>[
      'git',
      'clone',
      'https://github.com/flutter/flutter.git',
    ], workingDirectory: parentDirectory.path, trace: true);

    // Step 2. Switch to the dev branch.
    await processUtils.stream(<String>[
      'git',
      'checkout',
      '--track',
      '-b',
      _kBranch,
      'origin/$_kBranch',
    ], workingDirectory: testDirectory.path, trace: true);

    // Step 3. Revert to a prior version.
    await processUtils.stream(<String>[
      'git',
      'reset',
      '--hard',
      _kInitialVersion,
    ], workingDirectory: testDirectory.path, trace: true);

    // Step 4. Upgrade to the newest dev. This should update the persistent
    // tool state with the sha for v1.14.3
    await processUtils.stream(<String>[
      flutterBin,
      'upgrade',
      '--working-directory=${testDirectory.path}'
    ], workingDirectory: testDirectory.path, trace: true);

    // Step 5. Verify that the version is different.
    final RunResult versionResult = await processUtils.run(<String>[
      'git',
      'describe',
      '--match',
      'v*.*.*',
      '--first-parent',
      '--long',
      '--tags',
    ], workingDirectory: testDirectory.path);
    expect(versionResult.stdout, isNot(contains(_kInitialVersion)));

    // Step 6. Downgrade back to initial version.
    await processUtils.stream(<String>[
       flutterBin,
      'downgrade',
      '--no-prompt',
      '--working-directory=${testDirectory.path}'
    ], workingDirectory: testDirectory.path, trace: true);

    // Step 7. Verify downgraded version matches original version.
    final RunResult oldVersionResult = await processUtils.run(<String>[
      'git',
      'describe',
      '--match',
      'v*.*.*',
      '--first-parent',
      '--long',
      '--tags',
    ], workingDirectory: testDirectory.path);
    expect(oldVersionResult.stdout, contains(_kInitialVersion));
  });
}
