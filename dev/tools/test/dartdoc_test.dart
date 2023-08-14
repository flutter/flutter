// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import '../dartdoc.dart' as dartdoc;

void main() {
  const String branchName = 'stable';
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
          stdout: '''
{
  "frameworkVersion": "3.0.0",
  "channel": "$branchName",
  "repositoryUrl": "git@github.com:flutter/flutter.git",
  "frameworkRevision": "0000000000000000000000000000000000000000",
  "frameworkCommitDate": "2023-08-07 16:26:58 -0700",
  "engineRevision": "0000000000000000000000000000000000000001",
  "dartSdkVersion": "3.2.0",
  "devToolsVersion": "2.0.0",
  "flutterVersion": "3.0.1",
  "flutterRoot": "/flutter"
}
''',
        ),
      ],
    );

    expect(
      dartdoc.FlutterInformation(platform: platform, processManager: processManager).getBranchName(),
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
          stdout: '''
{
  "frameworkVersion": "3.0.0",
  "channel": "$branchName",
  "repositoryUrl": "git@github.com:flutter/flutter.git",
  "frameworkRevision": "0000000000000000000000000000000000000000",
  "frameworkCommitDate": "2023-08-07 16:26:58 -0700",
  "engineRevision": "0000000000000000000000000000000000000001",
  "dartSdkVersion": "3.2.0",
  "devToolsVersion": "2.0.0",
  "flutterVersion": "3.0.1",
  "flutterRoot": "/flutter"
}
''',
        ),
        const FakeCommand(
          command: <String>['git', 'status', '-b', '--porcelain'],
          stdout: '## $branchName',
        ),
      ],
    );

    expect(
      dartdoc.FlutterInformation(platform: platform, processManager: processManager).getBranchName(),
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
          stdout: '''
{
  "frameworkVersion": "3.0.0",
  "channel": "$branchName",
  "repositoryUrl": "git@github.com:flutter/flutter.git",
  "frameworkRevision": "0000000000000000000000000000000000000000",
  "frameworkCommitDate": "2023-08-07 16:26:58 -0700",
  "engineRevision": "0000000000000000000000000000000000000001",
  "dartSdkVersion": "3.2.0",
  "devToolsVersion": "2.0.0",
  "flutterVersion": "3.0.1",
  "flutterRoot": "/flutter"
}
''',
        ),
        const FakeCommand(
          command: <String>['git', 'status', '-b', '--porcelain'],
          stdout: '## $branchName',
        ),
      ],
    );

    expect(
      dartdoc.FlutterInformation(platform: platform, processManager: processManager).getBranchName(),
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
    dartdoc.FlutterInformation.instance = dartdoc.FlutterInformation(platform: platform, processManager: processManager);

    dartdoc.runPubProcess(
      arguments: <String>['--one', '--two'],
      processManager: processManager,
    );

    expect(processManager, hasNoRemainingExpectations);
  });
}
