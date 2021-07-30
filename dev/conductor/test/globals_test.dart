// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor/globals.dart';
import 'package:conductor/proto/conductor_state.pb.dart' as pb;

import './common.dart';

void main() {
  group('getNewPrLink', () {
    const String userName = 'flutterer';
    const String releaseChannel = 'beta';
    const String releaseVersion = '1.2.0-3.4.pre';
    const String candidateBranch = 'flutter-1.2-candidate.3';
    const String workingBranch = 'cherrypicks-$candidateBranch';
    const String engineCherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
    const String engineCherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
    const String frameworkCherrypick = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';

    final RegExp titlePattern = RegExp(r'&title=(.*)&');
    final RegExp bodyPattern = RegExp(r'&body=(.*)$');

    final pb.ConductorState state = pb.ConductorState(
      engine: pb.Repository(
        candidateBranch: candidateBranch,
        cherrypicks: <pb.Cherrypick>[
          pb.Cherrypick(trunkRevision: engineCherrypick1),
          pb.Cherrypick(trunkRevision: engineCherrypick2),
        ],
        workingBranch: workingBranch,
      ),
      framework: pb.Repository(
        candidateBranch: candidateBranch,
        cherrypicks: <pb.Cherrypick>[
          pb.Cherrypick(trunkRevision: frameworkCherrypick),
        ],
        workingBranch: workingBranch,
      ),
      releaseChannel: releaseChannel,
      releaseVersion: releaseVersion,
    );

    test('throws on an invalid repoName', () {
      expect(
        () => getNewPrLink(
          repoName: 'flooter',
          userName: userName,
          state: state,
        ),
        throwsExceptionWith('Expected repoName to be one of flutter or engine but got flooter.'),
      );
    });

    test('returns a valid URL for engine', () {
      final String link = getNewPrLink(
        repoName: 'engine',
        userName: userName,
        state: state,
      );
      expect(
        link,
        contains('https://github.com/flutter/engine/compare/'),
      );
      expect(
        link,
        contains('$candidateBranch...$userName:$workingBranch?expand=1'),
      );
      expect(
        Uri.decodeQueryComponent(titlePattern.firstMatch(link)?.group(1) ?? ''),
        '[flutter_releases] Flutter $releaseChannel $releaseVersion Engine Cherrypicks'
      );
      const String expectedBody = '''
# Flutter $releaseChannel $releaseVersion Engine

## Scheduled Cherrypicks

- commit: $engineCherrypick1
- commit: $engineCherrypick2''';
      expect(
        Uri.decodeQueryComponent(bodyPattern.firstMatch(link)?.group(1) ?? ''),
        expectedBody,
      );
    });

    test('returns a valid URL for framework', () {
      final String link = getNewPrLink(
        repoName: 'flutter',
        userName: userName,
        state: state,
      );
      expect(
        link,
        contains('https://github.com/flutter/flutter/compare/'),
      );
      expect(
        link,
        contains('$candidateBranch...$userName:$workingBranch?expand=1'),
      );
      expect(
        Uri.decodeQueryComponent(titlePattern.firstMatch(link)?.group(1) ?? ''),
        '[flutter_releases] Flutter $releaseChannel $releaseVersion Framework Cherrypicks'
      );
      const String expectedBody = '''
# Flutter $releaseChannel $releaseVersion Framework

## Scheduled Cherrypicks

- commit: $frameworkCherrypick''';
      expect(
        Uri.decodeQueryComponent(bodyPattern.firstMatch(link)?.group(1) ?? ''),
        expectedBody,
      );
    });
  });
}
