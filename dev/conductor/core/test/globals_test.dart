// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:conductor_core/src/enums.dart';
import 'package:conductor_core/src/globals.dart';

import './common.dart';

void main() {
  test('assertsEnabled returns true in test suite', () {
    expect(assertsEnabled(), true);
  });

  group('getNewPrLink', () {
    const String userName = 'flutterer';
    const String releaseChannel = 'beta';
    const String releaseVersion = '1.2.0-3.4.pre';
    const String candidateBranch = 'flutter-1.2-candidate.3';
    const String workingBranch = 'cherrypicks-$candidateBranch';
    const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';

    final RegExp titlePattern = RegExp(r'&title=(.*)&');
    final RegExp bodyPattern = RegExp(r'&body=(.*)$');

    late ConductorState state;

    setUp(() {
      state = ConductorState(
        engine: RepositoryState(
          candidateBranch: candidateBranch,
          startingGitHead: '',
          currentGitHead: '',
          checkoutPath: '',
          upstream: const RemoteState(name: 'upstream', url: ''),
          mirror: const RemoteState(name: 'mirror', url: ''),
          dartRevision: dartRevision,
          workingBranch: workingBranch,
        ),
        framework: RepositoryState(
          candidateBranch: candidateBranch,
          startingGitHead: '',
          currentGitHead: '',
          checkoutPath: '',
          upstream: const RemoteState(name: 'upstream', url: ''),
          mirror: const RemoteState(name: 'mirror', url: ''),
          workingBranch: workingBranch,
        ),
        releaseChannel: releaseChannel,
        releaseVersion: releaseVersion,
        createdDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
        logs: <String>[],
        currentPhase: ReleasePhase.VERIFY_ENGINE_CI,
        conductorVersion: 'someConductorVersion',
        releaseType: ReleaseType.STABLE_INITIAL,
  );

   });

    test('throws on an invalid repoName', () {
      expect(
        () => getNewPrLink(
          repoName: 'flooter',
          userName: userName,
          state: state,
        ),
        throwsExceptionWith(
          'Expected repoName to be one of flutter or engine but got flooter.',
        ),
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
          Uri.decodeQueryComponent(
              titlePattern.firstMatch(link)?.group(1) ?? ''),
          '[flutter_releases] Flutter $releaseChannel $releaseVersion Engine Cherrypicks');
      final String expectedBody = '''
# Flutter $releaseChannel $releaseVersion Engine

''';
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
          Uri.decodeQueryComponent(
              titlePattern.firstMatch(link)?.group(1) ?? ''),
          '[flutter_releases] Flutter $releaseChannel $releaseVersion Framework Cherrypicks');
      final String expectedBody = '''
# Flutter $releaseChannel $releaseVersion Framework

''';
      expect(
        Uri.decodeQueryComponent(bodyPattern.firstMatch(link)?.group(1) ?? ''),
        expectedBody,
      );
    });
  });

  group('getBoolFromEnvOrArgs', () {
    const String flagName = 'a-cli-flag';

    test('prefers env over argResults', () {
      final ArgResults argResults = FakeArgs(results: <String, Object>{
        flagName: false,
      });
      final Map<String, String> env = <String, String>{'A_CLI_FLAG': 'TRUE'};
      final bool result = getBoolFromEnvOrArgs(
        flagName,
        argResults,
        env,
      );
      expect(result, true);
    });

    test('falls back to argResults if env is empty', () {
      final ArgResults argResults = FakeArgs(results: <String, Object>{
        flagName: false,
      });
      final Map<String, String> env = <String, String>{};
      final bool result = getBoolFromEnvOrArgs(
        flagName,
        argResults,
        env,
      );
      expect(result, false);
    });
  });
}

class FakeArgs extends Fake implements ArgResults {
  FakeArgs({
    this.arguments = const <String>[],
    this.name = 'fake-command',
    this.results = const <String, Object>{},
  });

  final Map<String, Object> results;

  @override
  final List<String> arguments;

  @override
  final String name;

  @override
  bool wasParsed(String name) {
    return results[name] != null;
  }

  @override
  Object? operator[](String name) {
    return results[name];
  }
}
