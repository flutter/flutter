// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';

import '../src/common.dart';
import 'test_utils.dart';

const _kInitialVersion = '3.0.0';
const _kUpgradedVersion = '3.1.0-0.0.pre';
const _kBranch = 'beta';

final stdio = Stdio();
final logger = BufferLogger.test(
  terminal: AnsiTerminal(platform: platform, stdio: stdio),
  outputPreferences: OutputPreferences.test(wrapText: true),
);
final processUtils = ProcessUtils(processManager: processManager, logger: logger);

/// A test for flutter upgrade & downgrade that checks out a parallel flutter repo.
void main() {
  late Directory parentDirectory;

  setUp(() {
    parentDirectory = createResolvedTempDirectorySync('upgrade_downgrade.');
  });

  tearDown(() {
    tryToDelete(parentDirectory);
  });

  testWithoutContext('Can upgrade and downgrade a Flutter checkout', () async {
    final Directory remoteDirectory = parentDirectory.childDirectory('remote')
      ..createSync(recursive: true);
    final Directory testDirectory = parentDirectory.childDirectory('flutter');
    final Directory homeDirectory = parentDirectory.childDirectory('home')
      ..createSync(recursive: true);
    final Directory configDirectory = homeDirectory.childDirectory('.config')
      ..createSync(recursive: true);

    void checkExitCode(int code) {
      expect(
        code,
        0,
        reason:
            '''
trace:
${logger.traceText}

status:
${logger.statusText}

error:
${logger.errorText}''',
      );
    }

    Future<void> runGit(List<String> args, {required Directory workingDirectory}) async {
      final int code = await processUtils.stream(
        <String>['git', ...args],
        workingDirectory: workingDirectory.path,
        trace: true,
      );
      checkExitCode(code);
    }

    printOnFailure('Step 0 - create a local upstream Flutter repository');
    for (final args in const <List<String>>[
      <String>['init'],
      <String>['checkout', '-b', _kBranch],
      <String>['config', '--local', 'user.name', 'Flutter Test'],
      <String>['config', '--local', 'user.email', 'flutter-test@example.com'],
      <String>['config', '--local', 'commit.gpgsign', 'false'],
      <String>['config', '--local', 'tag.gpgsign', 'false'],
      <String>['commit', '--allow-empty', '-m', 'Initial commit'],
      <String>['tag', _kInitialVersion],
      <String>['commit', '--allow-empty', '-m', 'Upgrade commit'],
      <String>['tag', _kUpgradedVersion],
    ]) {
      await runGit(args, workingDirectory: remoteDirectory);
    }

    printOnFailure('Step 1 - clone the $_kBranch of flutter into the test directory');
    await runGit(<String>[
      'clone',
      '--branch',
      _kBranch,
      remoteDirectory.path,
      testDirectory.path,
    ], workingDirectory: parentDirectory);

    // Read back the exact remote URL recorded by git (for example, Git for
    // Windows normalizes backslashes to forward slashes) so FLUTTER_GIT_URL
    // matches FlutterVersion.repositoryUrl in VersionUpstreamValidator.
    final RunResult remoteUrlResult = await processUtils.run(<String>[
      'git',
      'ls-remote',
      '--get-url',
      'origin',
    ], workingDirectory: testDirectory.path);
    checkExitCode(remoteUrlResult.exitCode);
    final testEnvironment = <String, String>{
      ...platform.environment,
      'FLUTTER_GIT_URL': remoteUrlResult.stdout.trim(),
      'HOME': homeDirectory.path,
      'XDG_CONFIG_HOME': configDirectory.path,
      'APPDATA': homeDirectory.path,
    };

    printOnFailure('Step 2 - revert back to $_kInitialVersion');
    await runGit(<String>['reset', '--hard', _kInitialVersion], workingDirectory: testDirectory);

    printOnFailure('Step 3 - upgrade to the newest $_kBranch');
    checkExitCode(
      await processUtils.stream(
        <String>[
          flutterBin,
          'upgrade',
          '--verbose',
          '--working-directory=${testDirectory.path}',
          // Intentionally run in a directory outside the test repo to verify
          // the tool overrides the working directory when invoking git.
        ],
        workingDirectory: parentDirectory.path,
        environment: testEnvironment,
        trace: true,
      ),
    );

    printOnFailure('Step 4 - verify that the version is updated to $_kUpgradedVersion');
    final RunResult versionResult = await processUtils.run(<String>[
      'git',
      'describe',
      '--match',
      '*.*.*',
      '--long',
      '--tags',
    ], workingDirectory: testDirectory.path);
    checkExitCode(versionResult.exitCode);
    expect(versionResult.stdout, contains(_kUpgradedVersion));
    printOnFailure(
      'current version is ${versionResult.stdout.trim()}\ninitial was $_kInitialVersion',
    );

    printOnFailure('Step 5 - downgrade back to the initial version');
    checkExitCode(
      await processUtils.stream(
        <String>[
          flutterBin,
          'downgrade',
          '--no-prompt',
          '--working-directory=${testDirectory.path}',
        ],
        workingDirectory: parentDirectory.path,
        environment: testEnvironment,
        trace: true,
      ),
    );

    printOnFailure('Step 6 - verify downgraded version matches original version');
    final RunResult oldVersionResult = await processUtils.run(<String>[
      'git',
      'describe',
      '--match',
      '*.*.*',
      '--long',
      '--tags',
    ], workingDirectory: testDirectory.path);
    checkExitCode(oldVersionResult.exitCode);
    expect(oldVersionResult.stdout, contains(_kInitialVersion));
    printOnFailure(
      'current version is ${oldVersionResult.stdout.trim()}\ninitial was $_kInitialVersion',
    );
  });
}
