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

    test('redacts URL credentials when starting git fails', () async {
      const remoteWithToken = 'https://super-secret-token@github.com/flutter/flutter.git';
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'push', remoteWithToken, 'HEAD:master'],
          exception: ProcessException(
            'git',
            <String>['push', remoteWithToken, 'HEAD:master'],
            'authentication failed for https://super-secret-token@github.com/flutter/flutter.git',
            128,
          ),
        ),
      ]);
      final git = Git(processManager);

      await expectLater(
        () => git.run(
          <String>['push', remoteWithToken, 'HEAD:master'],
          'push to upstream',
          workingDirectory: '/tmp',
        ),
        throwsA(
          isA<GitException>()
              .having(
                (GitException e) => e.message,
                'message contains redacted URL',
                contains('https://[REDACTED]@github.com/flutter/flutter.git'),
              )
              .having(
                (GitException e) => e.message,
                'message does not contain raw token',
                isNot(contains('super-secret-token@github.com')),
              ),
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

    test('redacts URL credentials on non-zero git exit', () async {
      const remoteWithToken = 'https://super-secret-token@github.com/flutter/flutter.git';
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'push', remoteWithToken, 'HEAD:master'],
          exitCode: 1,
          stderr:
              'fatal: could not read Password for "https://super-secret-token@github.com": No such device or address',
        ),
      ]);
      final git = Git(processManager);

      await expectLater(
        () => git.run(
          <String>['push', remoteWithToken, 'HEAD:master'],
          'push to upstream',
          workingDirectory: '/tmp',
        ),
        throwsA(
          isA<GitException>()
              .having(
                (GitException e) => e.message,
                'message contains redacted URL',
                contains('https://[REDACTED]@github.com/flutter/flutter.git'),
              )
              .having(
                (GitException e) => e.message,
                'message does not contain raw token',
                isNot(contains('super-secret-token@github.com')),
              ),
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });
  });
}
