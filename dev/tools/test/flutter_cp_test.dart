// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../../.agents/skills/flutter-cherry-pick/scripts/flutter_cp.dart';

void main() {
  group('CherryPickHelper.initialPrBody', () {
    late Directory tempRepo;

    setUp(() {
      tempRepo = Directory.systemTemp.createTempSync('flutter_cp_test.');
    });

    tearDown(() {
      if (tempRepo.existsSync()) {
        tempRepo.deleteSync(recursive: true);
      }
    });

    test('includes summary and cherry-pick template when present', () {
      final templateFile = File(
        path.join(tempRepo.path, '.github', 'PR_TEMPLATE', 'PULL_REQUEST_CP_TEMPLATE.md'),
      )..createSync(recursive: true);
      templateFile.writeAsStringSync('### Issue Link:\n<fill me>\n');

      final errors = <String>[];
      final helper = CherryPickHelper(
        pr: 190001,
        channel: 'stable',
        repoPath: tempRepo.path,
        onError: (Object? m) => errors.add('$m'),
      );

      expect(
        helper.initialPrBody(),
        'Cherry-pick of #190001 to stable.\n\n### Issue Link:\n<fill me>\n',
      );
      expect(errors, isEmpty);
    });

    test('falls back to summary and warns when template is missing', () {
      final errors = <String>[];
      final helper = CherryPickHelper(
        pr: 190001,
        channel: 'beta',
        repoPath: tempRepo.path,
        onError: (Object? m) => errors.add('$m'),
      );

      expect(helper.initialPrBody(), 'Cherry-pick of #190001 to beta.');
      expect(errors, <Matcher>[contains('Cherry-pick template not found')]);
    });
  });

  group('CherryPickHelper.requestReviewers', () {
    test(
      'requests author and APPROVED reviewers while skipping self, CP author, and bots',
      () async {
        final recorded = <List<String>>[];
        final infos = <String>[];
        final errors = <String>[];

        final helper = CherryPickHelper(
          pr: 190001,
          channel: 'stable',
          repoPath: '.',
          onInfo: (Object? m) => infos.add('$m'),
          onError: (Object? m) => errors.add('$m'),
          processRunner: (List<String> cmd, {String? workingDirectory}) async {
            recorded.add(cmd);
            if (cmd case ['gh', 'api', 'user', '--jq', '.login']) {
              return ProcessResult(0, 0, 'CurrentDev\n', '');
            }
            if (cmd case ['gh', 'pr', 'view', '196500', ...]) {
              return ProcessResult(0, 0, 'CpCreator\n', '');
            }
            if (cmd case ['gh', 'api', '-X', 'POST', ...]) {
              return ProcessResult(0, 0, '{}', '');
            }
            fail('Unexpected command: $cmd');
          },
        );

        helper.originalPrData = <String, Object?>{
          'author': <String, Object?>{'login': 'OrigAuthor', 'is_bot': false},
          'reviews': <Object?>[
            <String, Object?>{
              'state': 'COMMENTED',
              'author': <String, Object?>{'login': 'commenter'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'currentdev'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'cpcreator'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'fluttergithubbot'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'engine-flutter-autoroll'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'dependabot[bot]'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'helper-agent'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'TeamReviewer'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'teamreviewer'},
            },
          ],
        };

        await helper.requestReviewers(196500);

        final List<List<String>> postCalls = recorded
            .where((List<String> c) => c.contains('POST'))
            .toList();
        expect(postCalls, hasLength(1));
        expect(postCalls.single, <String>[
          'gh',
          'api',
          '-X',
          'POST',
          'repos/flutter/flutter/pulls/196500/requested_reviewers',
          '-f',
          'reviewers[]=OrigAuthor',
          '-f',
          'reviewers[]=TeamReviewer',
        ]);
        expect(errors, isEmpty);
      },
    );

    test('skips bot-authored PRs and makes no POST when no human reviewers remain', () async {
      final recorded = <List<String>>[];
      final infos = <String>[];

      final helper = CherryPickHelper(
        pr: 196296,
        channel: 'stable',
        repoPath: '.',
        onInfo: (Object? m) => infos.add('$m'),
        processRunner: (List<String> cmd, {String? workingDirectory}) async {
          recorded.add(cmd);
          return ProcessResult(0, 0, 'devuser\n', '');
        },
      );

      helper.originalPrData = <String, Object?>{
        'author': <String, Object?>{'login': 'engine-flutter-autoroll', 'is_bot': false},
        'reviews': <Object?>[
          <String, Object?>{
            'state': 'APPROVED',
            'author': <String, Object?>{'login': 'fluttergithubbot'},
          },
        ],
      };

      await helper.requestReviewers(196501);

      expect(recorded.where((List<String> c) => c.contains('POST')), isEmpty);
      expect(infos, contains('No reviewers to request on PR #196501.'));
    });

    test(
      'retries individually when batch fails so collaborator approvers still get added',
      () async {
        final postCalls = <List<String>>[];
        final errors = <String>[];

        final helper = CherryPickHelper(
          pr: 190002,
          channel: 'stable',
          repoPath: '.',
          onInfo: (_) {},
          onError: (Object? m) => errors.add('$m'),
          processRunner: (List<String> cmd, {String? workingDirectory}) async {
            if (cmd case ['gh', 'api', 'user', ...]) {
              return ProcessResult(0, 0, 'releaseeng\n', '');
            }
            if (cmd case ['gh', 'pr', 'view', ...]) {
              return ProcessResult(0, 0, 'flutteractionsbot\n', '');
            }
            if (cmd case ['gh', 'api', '-X', 'POST', ...]) {
              postCalls.add(cmd);
              if (cmd.contains('reviewers[]=ExternalAuthor')) {
                return ProcessResult(
                  0,
                  1,
                  '',
                  'HTTP 422: Reviews may only be requested from collaborators.',
                );
              }
              return ProcessResult(0, 0, '{}', '');
            }
            fail('Unexpected command: $cmd');
          },
        );

        helper.originalPrData = <String, Object?>{
          'author': <String, Object?>{'login': 'ExternalAuthor', 'is_bot': false},
          'reviews': <Object?>[
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'TeamApprover1'},
            },
            <String, Object?>{
              'state': 'APPROVED',
              'author': <String, Object?>{'login': 'TeamApprover2'},
            },
          ],
        };

        await helper.requestReviewers(196502);

        // 1 batch attempt + 3 individual retries.
        expect(postCalls, hasLength(4));
        expect(postCalls[1], contains('reviewers[]=ExternalAuthor'));
        expect(postCalls[2], contains('reviewers[]=TeamApprover1'));
        expect(postCalls[3], contains('reviewers[]=TeamApprover2'));
        expect(errors, hasLength(1));
        expect(
          errors.single,
          contains('Could not request reviews from ExternalAuthor on PR #196502'),
        );
        expect(errors.single, isNot(contains('TeamApprover1')));
      },
    );
  });
}
