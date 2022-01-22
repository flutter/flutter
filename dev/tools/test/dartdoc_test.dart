// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../../../packages/flutter_tools/test/src/fake_process_manager.dart';
import '../dartdoc.dart' show getBranchName;

void main() {
  const String branchName = 'stable';
  test('getBranchName does not call git if env LUCI_BRANCH provided', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'LUCI_BRANCH': branchName,
      },
    );

    final ProcessManager processManager = FakeProcessManager.empty();

    expect(
      getBranchName(
        platform: platform,
        processManager: processManager,
      ),
      branchName,
    );
  });

  test('getBranchName calls git if env LUCI_BRANCH not provided', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{},
    );

    final ProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'status', '-b', '--porcelain'],
          stdout: '## $branchName',
        ),
      ],
    );

    expect(
      getBranchName(
        platform: platform,
        processManager: processManager,
      ),
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
          command: <String>['git', 'status', '-b', '--porcelain'],
          stdout: '## $branchName',
        ),
      ],
    );

    expect(
      getBranchName(
        platform: platform,
        processManager: processManager,
      ),
      branchName,
    );
    expect(processManager, hasNoRemainingExpectations);
  });
}
