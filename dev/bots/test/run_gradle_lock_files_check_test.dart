// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../run_command.dart';
import '../suite_runners/run_gradle_lock_files_check.dart';
import '../utils.dart';
import 'analyze_test.dart';
import 'common.dart';
import 'mock_run_command.dart';

const String _dartCommand = 'dart';
const String _scriptFilePath = 'tools/bin/generate_gradle_lockfiles.dart';

void main() {
  const String fakeFlutterRoot = '/fake/flutter_root';
  final MockProcessRunner mockProcessRunner = MockProcessRunner();

  setUp(() {
    resetErrorStatus();
  });

  group('runGradleLockFilesCheck', () {
    test('succeeds when no lockfile changes are detected', () async {
      mockProcessRunner.addMockResults(<CommandResult>[
        FakeCommandResult(),
        FakeCommandResult(flattenedStdout: ' M cache\n?? ignored.txt\n'),
      ]);

      final String consoleOutput = await capture(() async {
        await runGradleLockFilesCheck(
          runCommand: mockProcessRunner.mockRunCommand,
          flutterRootOverride: fakeFlutterRoot,
        );
      });

      expect(
        consoleOutput,
        contains('${green}Gradle lock files are up to date and correctly staged.$reset'),
      );
      expect(hasError, isFalse);
    });

    test('throws an exception when lockfile changes are detected', () async {
      mockProcessRunner.addMockResults(<CommandResult>[
        FakeCommandResult(),
        FakeCommandResult(flattenedStdout: ' M path/to/file.lockfile\n?? another.lockfile\n'),
      ]);

      expect(
        () => runGradleLockFilesCheck(
          runCommand: mockProcessRunner.mockRunCommand,
          flutterRootOverride: fakeFlutterRoot,
        ),
        throwsExceptionWith(
          'Gradle lockfiles are not up to date, or new/modified lockfiles are not staged.',
        ),
      );
    });

    test('throws an exception when lockfile changes are detected', () async {
      mockProcessRunner.addMockResults(<CommandResult>[
        FakeCommandResult(),
        FakeCommandResult(flattenedStdout: ' M path/to/file.lockfile\n?? another.lockfile\n'),
      ]);

      try {
        await runGradleLockFilesCheck(
          runCommand: mockProcessRunner.mockRunCommand,
          flutterRootOverride: fakeFlutterRoot,
        );
      } catch (e) {
        final String errorMessage = e.toString();
        expect(errorMessage, contains('  M path/to/file.lockfile'));
        expect(errorMessage, contains('  ?? another.lockfile'));
        expect(errorMessage, contains('Please run `$_dartCommand $_scriptFilePath` locally'));
      }
    });

    test('sets error status if the dart command fails', () async {
      mockProcessRunner.addMockResults(<CommandResult>[
        FakeCommandResult(exitCode: 1, flattenedStderr: 'Dart script failed!'),
        FakeCommandResult(),
      ]);

      final String consoleOutput = await capture(() async {
        await runGradleLockFilesCheck(
          runCommand: mockProcessRunner.mockRunCommand,
          flutterRootOverride: fakeFlutterRoot,
        );
      }, shouldHaveErrors: true);

      expect(consoleOutput, contains('ERROR #1'));
      expect(
        consoleOutput,
        contains(
          'Mock for "dart tools/bin/generate_gradle_lockfiles.dart --no-gradle-generation" failed.',
        ),
      );
      expect(consoleOutput, contains('stderr: Dart script failed!'));
    });

    test('throws if git status command provides null stdout', () async {
      mockProcessRunner.addMockResults(<CommandResult>[
        FakeCommandResult(),
        FakeCommandResult(flattenedStdout: null),
      ]);

      expect(
        () => runGradleLockFilesCheck(
          runCommand: mockProcessRunner.mockRunCommand,
          flutterRootOverride: fakeFlutterRoot,
        ),
        throwsExceptionWith('Could not get git status output.'),
      );
    });
  });
}
