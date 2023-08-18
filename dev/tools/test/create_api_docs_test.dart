// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import '../create_api_docs.dart' as apidocs;
import '../examples_smoke_test.dart';

void main() {
  test('getBranchName does not call git if env LUCI_BRANCH provided', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'LUCI_BRANCH': branchName,
      },
    );

    final ProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['flutter', '--version', '--machine'],
          stdout: testVersionInfo,
        ),
      ],
    );

    expect(
      apidocs.FlutterInformation(platform: platform, processManager: processManager).getBranchName(),
      branchName,
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  test('getBranchName calls git if env LUCI_BRANCH not provided', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{},
    );

    final ProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['flutter', '--version', '--machine'],
          stdout: testVersionInfo,
        ),
        const FakeCommand(
          command: <String>['git', 'status', '-b', '--porcelain'],
          stdout: '## $branchName',
        ),
      ],
    );

    expect(
      apidocs.FlutterInformation(platform: platform, processManager: processManager).getBranchName(),
      branchName,
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  test('getBranchName calls git if env LUCI_BRANCH is empty', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'LUCI_BRANCH': '',
      },
    );

    final ProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['flutter', '--version', '--machine'],
          stdout: testVersionInfo,
        ),
        const FakeCommand(
          command: <String>['git', 'status', '-b', '--porcelain'],
          stdout: '## $branchName',
        ),
      ],
    );

    expect(
      apidocs.FlutterInformation(platform: platform, processManager: processManager).getBranchName(),
      branchName,
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  test("runPubProcess doesn't use the pub binary", () {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': '/flutter',
      },
    );
    final ProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['/flutter/bin/dart', 'pub', '--one', '--two'],
        ),
      ],
    );
    apidocs.FlutterInformation.instance =
        apidocs.FlutterInformation(platform: platform, processManager: processManager);

    apidocs.runPubProcess(
      arguments: <String>['--one', '--two'],
      processManager: processManager,
      filesystem: filesystem,
    );

    expect(processManager, hasNoRemainingExpectations);
  });

  group('FlutterInformation', () {
    late FakeProcessManager fakeProcessManager;
    late FakePlatform fakePlatform;
    late MemoryFileSystem memoryFileSystem;
    late apidocs.FlutterInformation flutterInformation;

    void setUpWithEnvironment(Map<String, String> environment) {
      fakePlatform = FakePlatform(environment: environment);
      flutterInformation = apidocs.FlutterInformation(
        filesystem: memoryFileSystem,
        processManager: fakeProcessManager,
        platform: fakePlatform,
      );
      apidocs.FlutterInformation.instance = flutterInformation;
    }

    setUp(() {
      fakeProcessManager = FakeProcessManager.empty();
      memoryFileSystem = MemoryFileSystem();
      setUpWithEnvironment(<String, String>{});
    });

    test('calls out to flutter if FLUTTER_VERSION is not set', () async {
      fakeProcessManager.addCommand(
          const FakeCommand(command: <Pattern>['flutter', '--version', '--machine'], stdout: testVersionInfo));
      fakeProcessManager.addCommand(
          const FakeCommand(command: <Pattern>['git', 'status', '-b', '--porcelain'], stdout: testVersionInfo));
      final Map<String, dynamic> info = flutterInformation.getFlutterInformation();
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(info['frameworkVersion'], equals(Version.parse('2.5.0')));
    });
    test("doesn't call out to flutter if FLUTTER_VERSION is set", () async {
      setUpWithEnvironment(<String, String>{
        'FLUTTER_VERSION': testVersionInfo,
      });
      fakeProcessManager.addCommand(
          const FakeCommand(command: <Pattern>['git', 'status', '-b', '--porcelain'], stdout: testVersionInfo));
      final Map<String, dynamic> info = flutterInformation.getFlutterInformation();
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(info['frameworkVersion'], equals(Version.parse('2.5.0')));
    });
    test('getFlutterRoot calls out to flutter if FLUTTER_ROOT is not set', () async {
      fakeProcessManager.addCommand(
          const FakeCommand(command: <Pattern>['flutter', '--version', '--machine'], stdout: testVersionInfo));
      fakeProcessManager.addCommand(
          const FakeCommand(command: <Pattern>['git', 'status', '-b', '--porcelain'], stdout: testVersionInfo));
      final Directory root = flutterInformation.getFlutterRoot();
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(root.path, equals('/home/user/flutter'));
    });
    test("getFlutterRoot doesn't call out to flutter if FLUTTER_ROOT is set", () async {
      setUpWithEnvironment(<String, String>{'FLUTTER_ROOT': '/home/user/flutter'});
      final Directory root = flutterInformation.getFlutterRoot();
      expect(fakeProcessManager, hasNoRemainingExpectations);
      expect(root.path, equals('/home/user/flutter'));
    });
    test('parses version properly', () async {
      fakePlatform.environment['FLUTTER_VERSION'] = testVersionInfo;
      fakeProcessManager.addCommand(
          const FakeCommand(command: <Pattern>['git', 'status', '-b', '--porcelain'], stdout: testVersionInfo));
      final Map<String, dynamic> info = flutterInformation.getFlutterInformation();
      expect(info['frameworkVersion'], isNotNull);
      expect(info['frameworkVersion'], equals(Version.parse('2.5.0')));
      expect(info['dartSdkVersion'], isNotNull);
      expect(info['dartSdkVersion'], equals(Version.parse('2.14.0-360.0.dev')));
    });
    test('the engine realm is read from the engine.realm file', () async {
      const String flutterRoot = '/home/user/flutter';
      final File realmFile = memoryFileSystem.file(
        path.join(flutterRoot, 'bin', 'internal', 'engine.realm',
      ));
      realmFile.writeAsStringSync('realm');
      setUpWithEnvironment(<String, String>{'FLUTTER_ROOT': flutterRoot});
      expect(fakeProcessManager, hasNoRemainingExpectations);
      final Map<String, dynamic> info = flutterInformation.getFlutterInformation();
      expect(info['engineRealm'], equals('realm'));
    });
  });
}

const String branchName = 'stable';
const String testVersionInfo = '''
{
  "frameworkVersion": "2.5.0",
  "channel": "$branchName",
  "repositoryUrl": "git@github.com:flutter/flutter.git",
  "frameworkRevision": "0000000000000000000000000000000000000000",
  "frameworkCommitDate": "2021-07-28 13:03:40 -0700",
  "engineRevision": "0000000000000000000000000000000000000001",
  "dartSdkVersion": "2.14.0 (build 2.14.0-360.0.dev)",
  "flutterRoot": "/home/user/flutter"
}
''';
