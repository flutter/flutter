// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:packages_autoroller/src/git.dart';

import 'common.dart';

void main() {
  group('Git.run', () {
    test('throws GitException if starting git fails', () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'status'],
          exception: ProcessException('git', <String>['status'], 'No such file or directory', 2),
        ),
      ]);
      final git = Git(processManager);

      await expectLater(
        () => git.run(<String>['status'], 'check git status', workingDirectory: '/tmp'),
        throwsA(
          isA<GitException>()
              .having((GitException e) => e.message, 'message', contains('check git status'))
              .having(
                (GitException e) => e.message,
                'message',
                contains('No such file or directory'),
              ),
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
