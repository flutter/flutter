// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test clones the framework and downloads pre-built binaries; it sometimes
// times out with the default 5 minutes: https://github.com/flutter/flutter/issues/100937
@Timeout(Duration(minutes: 10))

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:conductor_core/src/codesign.dart' show CodesignCommand;
import 'package:conductor_core/src/globals.dart';
import 'package:conductor_core/src/repository.dart' show Checkouts, FrameworkRepository;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './common.dart';

/// Verify all binaries in the Flutter cache are expected by Conductor.
void main() {
  const Platform platform = LocalPlatform();
  const FileSystem fileSystem = LocalFileSystem();
  const ProcessManager processManager = LocalProcessManager();

  late Directory tempDir;

  /// Whether or not the test is running in the context of a CI release build.
  ///
  /// The LUCI_BRANCH env variable is set in the LUCI recipes repo_util module.
  /// See
  /// https://flutter.googlesource.com/recipes/+/refs/heads/main/recipe_modules/repo_util/api.py.
  bool isRelease() {
    final String? luciBranch = platform.environment['LUCI_BRANCH'];
    if (luciBranch == null) {
      return false;
    }
    return releaseCandidateBranchRegex.hasMatch(luciBranch);
  }

  setUp(() {
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_conductor_integration_test.');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
      'validate the expected binaries from the conductor codesign command are present in the cache',
      () async {
    final TestStdio stdio = TestStdio(verbose: true);
    final Checkouts checkouts = Checkouts(
      fileSystem: fileSystem,
      parentDirectory: tempDir,
      platform: platform,
      processManager: processManager,
      stdio: stdio,
    );

    final Directory flutterRoot = _flutterRootFromDartBinary(
      fileSystem.file(platform.executable),
    );

    final String currentHead = (processManager.runSync(
      <String>['git', 'rev-parse', 'HEAD'],
      workingDirectory: flutterRoot.path,
    ).stdout as String).trim();

    final FrameworkRepository framework = FrameworkRepository.localRepoAsUpstream(
      checkouts,
      upstreamPath: flutterRoot.path,
      initialRef: currentHead,
    );
    final CommandRunner<void> runner = CommandRunner<void>('codesign-test', '');
    runner.addCommand(
      CodesignCommand(
        checkouts: checkouts,
        framework: framework,
        flutterRoot: flutterRoot,
      ),
    );

    try {
      await runner.run(<String>[
        'codesign',
        '--verify',
        // Only verify if the correct binaries are in the cache
        '--no-signatures',
      ]);
    } on ConductorException catch (e) {
      io.stderr.writeln(stdio.error);
      io.stderr.writeln(_fixItInstructions);
      fail(e.message);
    } on Exception {
      io.stderr.writeln('stdout:\n${stdio.stdout}');
      io.stderr.writeln('stderr:\n${stdio.error}');
      rethrow;
    }
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('codesign command is only supported on macos'),
    'linux': const Skip('codesign command is only supported on macos'),
  });

  if (isRelease()) {
    test('Verify all release binaries are codesigned', () async {
      final TestStdio stdio = TestStdio(verbose: true);
      final Checkouts checkouts = Checkouts(
        fileSystem: fileSystem,
        parentDirectory: tempDir,
        platform: platform,
        processManager: processManager,
        stdio: stdio,
      );

      final Directory flutterRoot = _flutterRootFromDartBinary(
        fileSystem.file(platform.executable),
      );

      final String currentHead = (processManager.runSync(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: flutterRoot.path,
      ).stdout as String).trim();

      final FrameworkRepository framework = FrameworkRepository.localRepoAsUpstream(
        checkouts,
        upstreamPath: flutterRoot.path,
        initialRef: currentHead,
      );

      final CommandRunner<void> runner = CommandRunner<void>('codesign-test', '');
      runner.addCommand(
        CodesignCommand(
          checkouts: checkouts,
          framework: framework,
          flutterRoot: flutterRoot,
        ),
      );

      try {
        await runner.run(<String>[
          'codesign',
          '--verify',
          '--signatures',
        ]);
      } on ConductorException catch (e) {
        io.stderr.writeln(stdio.error);
        io.stderr.writeln(e.message);
        fail(_unsignedReleaseBinariesInstructions(await framework.engineVersionFile));
      } on Exception {
        io.stderr.writeln('stdout:\n${stdio.stdout}');
        io.stderr.writeln('stderr:\n${stdio.error}');
        rethrow;
      }
    }, onPlatform: <String, dynamic>{
      'windows': const Skip('codesign command is only supported on macos'),
      'linux': const Skip('codesign command is only supported on macos'),
    });
  }
}

Directory _flutterRootFromDartBinary(File dartBinary) {
  final Directory flutterDartSdkDir = dartBinary.parent.parent;
  final Directory flutterCache = flutterDartSdkDir.parent;
  final Directory flutterSdkDir = flutterCache.parent.parent;
  return flutterSdkDir;
}

const String _fixItInstructions = '''
Codesign integration test failed.

This means that the binary files found in the Flutter cache do not match those
expected by the conductor tool (either an expected file was not found in the
cache or an unexpected file was found in the cache).

This usually happens either during an engine roll or a change to the caching
logic in flutter_tools. If this is a valid change, then the conductor source
code should be updated, specifically either the [binariesWithEntitlements] or
[binariesWithoutEntitlements] lists, depending on if the file should have macOS
entitlements applied during codesigning.
''';

String _unsignedReleaseBinariesInstructions(File engineVersionFile) {
  final String engineVersion = engineVersionFile.readAsStringSync();
  return '''
Codesign integration test failed.

This means that the test ran in the context of a Flutter release but not all of
the engine binaries that the tool downloaded were codesigned with the proper
entitlements.

If the macOS binaries from this release have not already been codesigned, then
codesign them according to the Flutter release process and re-run this test.

If the macOS binaries from this release have been codesigned, verify that the
engine version this test checked, $engineVersion is the correct engine version,
and that it is the same version that was codesigned.

If this is not a release branch, then the definition of the `isRelease()`
function in the `codesign_integration_test.dart` file needs to be updated.
''';
}
