// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('UpgradeCommandRunner', () {
    FakeUpgradeCommandRunner fakeCommandRunner;
    UpgradeCommandRunner realCommandRunner;
    MockProcessManager processManager;
    final MockFlutterVersion flutterVersion = MockFlutterVersion();
    const GitTagVersion gitTagVersion = GitTagVersion(1, 2, 3, 4, 5, 'asd');
    when(flutterVersion.channel).thenReturn('dev');

    setUp(() {
      fakeCommandRunner = FakeUpgradeCommandRunner();
      realCommandRunner = UpgradeCommandRunner();
      processManager = MockProcessManager();
      when(processManager.start(
        <String>[
          fs.path.join('bin', 'flutter'),
          'upgrade',
          '--continue',
          '--no-version-check',
        ],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) async {
        return Future<Process>.value(createMockProcess());
      });
      fakeCommandRunner.willHaveUncomittedChanges = false;
    });

    test('throws on unknown tag, official branch,  noforce', () async {
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        false,
        false,
        const GitTagVersion.unknown(),
        flutterVersion,
      );
      expect(result, throwsA(isInstanceOf<ToolExit>()));
    });

    testUsingContext('does not throw on unknown tag, official branch, force', () async {
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        true,
        false,
        const GitTagVersion.unknown(),
        flutterVersion,
      );
      expect(await result, null);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    test('throws tool exit with uncommitted changes', () async {
      fakeCommandRunner.willHaveUncomittedChanges = true;
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        false,
        false,
        gitTagVersion,
        flutterVersion,
      );
      expect(result, throwsA(isA<ToolExit>()));
    });

    testUsingContext('does not throw tool exit with uncommitted changes and force', () async {
      fakeCommandRunner.willHaveUncomittedChanges = true;

      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        true,
        false,
        gitTagVersion,
        flutterVersion,
      );
      expect(await result, null);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    testUsingContext('Doesn\'t throw on known tag, dev branch, no force', () async {
      final Future<FlutterCommandResult> result = fakeCommandRunner.runCommand(
        false,
        false,
        gitTagVersion,
        flutterVersion,
      );
      expect(await result, null);
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });

    testUsingContext('verifyUpstreamConfigured', () async {
      when(processManager.run(
        <String>['git', 'rev-parse', '@{u}'],
        environment:anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((Invocation invocation) async {
        return FakeProcessResult()
          ..exitCode = 0;
      });
      await realCommandRunner.verifyUpstreamConfigured();
    }, overrides: <Type, Generator>{
      ProcessManager: () => processManager,
    });
  });

  group('matchesGitLine', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    bool _match(String line) => UpgradeCommandRunner.matchesGitLine(line);

    test('regex match', () {
      expect(_match(' .../flutter_gallery/lib/demo/buttons_demo.dart    | 10 +--'), true);
      expect(_match(' dev/benchmarks/complex_layout/lib/main.dart        |  24 +-'), true);

      expect(_match(' rename {packages/flutter/doc => dev/docs}/styles.html (92%)'), true);
      expect(_match(' delete mode 100644 doc/index.html'), true);
      expect(_match(' create mode 100644 examples/flutter_gallery/lib/gallery/demo.dart'), true);

      expect(_match('Fast-forward'), true);
    });

    test('regex doesn\'t match', () {
      expect(_match('Updating 79cfe1e..5046107'), false);
      expect(_match('229 files changed, 6179 insertions(+), 3065 deletions(-)'), false);
    });

    group('findProjectRoot', () {
      Directory tempDir;

      setUp(() async {
        tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_upgrade_test.');
      });

      tearDown(() {
        tryToDelete(tempDir);
      });

      testUsingContext('in project', () async {
        final String projectPath = await createProject(tempDir);
        expect(findProjectRoot(projectPath), projectPath);
        expect(findProjectRoot(fs.path.join(projectPath, 'lib')), projectPath);

        final String hello = fs.path.join(Cache.flutterRoot, 'examples', 'hello_world');
        expect(findProjectRoot(hello), hello);
        expect(findProjectRoot(fs.path.join(hello, 'lib')), hello);
      });

      testUsingContext('outside project', () async {
        final String projectPath = await createProject(tempDir);
        expect(findProjectRoot(fs.directory(projectPath).parent.path), null);
        expect(findProjectRoot(Cache.flutterRoot), null);
      });
    });
  });
}

class FakeUpgradeCommandRunner extends UpgradeCommandRunner {
  bool willHaveUncomittedChanges = false;

  @override
  Future<void> verifyUpstreamConfigured() async {}

  @override
  Future<bool> hasUncomittedChanges() async => willHaveUncomittedChanges;

  @override
  Future<void> resetChanges(GitTagVersion gitTagVersion) async {}

  @override
  Future<void> upgradeChannel(FlutterVersion flutterVersion) async {}

  @override
  Future<void> attemptFastForward() async {}

  @override
  Future<void> precacheArtifacts() async {}

  @override
  Future<void> updatePackages(FlutterVersion flutterVersion) async {}

  @override
  Future<void> runDoctor() async {}
}

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
class FakeProcessResult implements ProcessResult {
  @override
  int exitCode;

  @override
  int pid = 0;

  @override
  String stderr = '';

  @override
  String stdout = '';
}
