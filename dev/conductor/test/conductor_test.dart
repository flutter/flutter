// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_conductor/main.dart';
import 'package:flutter_conductor/globals.dart';
import 'package:flutter_conductor/git.dart';

import './common.dart';

void main() {
  group('run()', () {
    const String usage = 'usage info...';
    const String level = 'm';
    const String commit = 'abcde012345';
    const String origin = 'upstream';
    const String lastVersion = '1.2.0-0.0.pre';
    const String nextVersion = '1.2.0-1.0.pre';
    FakeArgResults fakeArgResults;
    MockGit mockGit;

    setUp(() {
      mockGit = MockGit();
    });

    test('returns false if help requested', () {
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        help: true,
      );
      expect(
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        false,
      );
    });

    test('returns false if level not provided', () {
      fakeArgResults = FakeArgResults(
        level: null,
        commit: commit,
        origin: origin,
      );
      expect(
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        false,
      );
    });

    test('returns false if commit not provided', () {
      fakeArgResults = FakeArgResults(
        level: level,
        commit: null,
        origin: origin,
      );
      expect(
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        false,
      );
    });

    test('throws exception if upstream remote wrong', () {
      const String remote = 'wrong-remote';
      when(mockGit.getOutput('remote get-url $origin', any)).thenReturn(remote);
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
      );
      const String errorMessage = 'The remote named $origin is set to $remote, when $kUpstreamRemote was expected.';
      expect(
        () => run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        throwsExceptionWith(errorMessage),
      );
    });

    test('throws exception if git checkout not clean', () {
      when(mockGit.getOutput('remote get-url $origin', any)).thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any)).thenReturn(
        ' M dev/tools/test/roll_dev_test.dart',
      );
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
      );
      Exception exception;
      try {
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        );
      } on Exception catch (e) {
        exception = e;
      }
      const String pattern = r'Your git repository is not clean. Try running '
        '"git clean -fd". Warning, this will delete files! Run with -n to find '
        'out which ones.';
      expect(exception?.toString(), contains(pattern));
    });

    test('does not reset or tag if --just-print is specified', () {
      when(mockGit.getOutput('remote get-url $origin', any)).thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any)).thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn('zxy321');
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        justPrint: true,
      );
      expect(run(
        usage: usage,
        argResults: fakeArgResults,
        git: mockGit,
      ), false);
      verify(mockGit.run('fetch $origin', any));
      verifyNever(mockGit.run('reset $commit --hard', any));
      verifyNever(mockGit.getOutput('rev-parse HEAD', any));
    });

    test('exits with exception if --skip-tagging is provided but commit isn\'t '
         'already tagged', () {
      when(mockGit.getOutput('remote get-url $origin', any)).thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any)).thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn('zxy321');
      const String exceptionMessage = 'Failed to verify $commit is already '
        'tagged. You can only use the flag `$kSkipTagging` if the commit has '
        'already been tagged.';
      when(mockGit.run(
        'describe --exact-match --tags $commit',
        any,
      )).thenThrow(Exception(exceptionMessage));

      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        skipTagging: true,
      );
      expect(
        () => run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        throwsExceptionWith(exceptionMessage),
      );
      verify(mockGit.run('fetch $origin', any));
      verifyNever(mockGit.run('reset $commit --hard', any));
      verifyNever(mockGit.getOutput('rev-parse HEAD', any));
    });

    test('throws exception if desired commit is already tip of dev branch', () {
      when(mockGit.getOutput('remote get-url $origin', any)).thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any)).thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn(commit);
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        justPrint: true,
      );
      expect(
        () => run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        throwsExceptionWith('is already on the dev branch as'),
      );
      verify(mockGit.run('fetch $origin', any));
      verifyNever(mockGit.run('reset $commit --hard', any));
      verifyNever(mockGit.getOutput('rev-parse HEAD', any));
    });

    test('does not tag if last release is not direct ancestor of desired '
        'commit and --force not supplied', () {
      when(mockGit.getOutput('remote get-url $origin', any))
        .thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any))
        .thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn('zxy321');
      when(mockGit.run('merge-base --is-ancestor $lastVersion $commit', any))
        .thenThrow(Exception(
          'Failed to verify $lastVersion is a direct ancestor of $commit. The '
          'flag `--force` is required to force push a new release past a '
          'cherry-pick',
        ));
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
      );
      const String errorMessage = 'Failed to verify $lastVersion is a direct '
        'ancestor of $commit. The flag `--force` is required to force push a '
        'new release past a cherry-pick';
      expect(
        () => run(
          argResults: fakeArgResults,
          git: mockGit,
          usage: usage,
        ),
        throwsExceptionWith(errorMessage),
      );

      verify(mockGit.run('fetch $origin', any));
      verifyNever(mockGit.run('reset $commit --hard', any));
      verifyNever(mockGit.run('push $origin HEAD:dev', any));
      verifyNever(mockGit.run('tag $nextVersion', any));
    });

    test('does not tag but updates branch if --skip-tagging provided', () {
      when(mockGit.getOutput('remote get-url $origin', any))
        .thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any))
        .thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn('zxy321');
      when(mockGit.getOutput('rev-parse HEAD', any)).thenReturn(commit);
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        skipTagging: true,
      );
      expect(run(
        usage: usage,
        argResults: fakeArgResults,
        git: mockGit,
      ), true);
      verify(mockGit.run('fetch $origin', any));
      verify(mockGit.run('reset $commit --hard', any));
      verifyNever(mockGit.run('tag $nextVersion', any));
      verifyNever(mockGit.run('push $origin $nextVersion', any));
      verify(mockGit.run('push $origin HEAD:dev', any));
    });

    test('successfully tags and publishes release', () {
      when(mockGit.getOutput('remote get-url $origin', any))
        .thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any))
        .thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn('zxy321');
      when(mockGit.getOutput('rev-parse HEAD', any)).thenReturn(commit);
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
      );
      expect(run(
        usage: usage,
        argResults: fakeArgResults,
        git: mockGit,
      ), true);
      verify(mockGit.run('fetch $origin', any));
      verify(mockGit.run('reset $commit --hard', any));
      verify(mockGit.run('tag $nextVersion', any));
      verify(mockGit.run('push $origin $nextVersion', any));
      verify(mockGit.run('push $origin HEAD:dev', any));
    });

    test('successfully publishes release with --force', () {
      when(mockGit.getOutput('remote get-url $origin', any)).thenReturn(kUpstreamRemote);
      when(mockGit.getOutput('status --porcelain', any)).thenReturn('');
      when(mockGit.getFullTag(origin)).thenReturn(lastVersion);
      when(mockGit.getOutput(
        'rev-parse $lastVersion',
        any,
      )).thenReturn('zxy321');
      when(mockGit.getOutput('rev-parse HEAD', any)).thenReturn(commit);
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        force: true,
      );
      expect(run(
        usage: usage,
        argResults: fakeArgResults,
        git: mockGit,
      ), true);
      verify(mockGit.run('fetch $origin', any));
      verify(mockGit.run('reset $commit --hard', any));
      verify(mockGit.run('tag $nextVersion', any));
      verify(mockGit.run('push --force $origin HEAD:dev', any));
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}

class FakeArgResults implements ArgResults {
  FakeArgResults({
    String level,
    String commit,
    String origin,
    bool justPrint = false,
    bool autoApprove = true, // so we don't have to mock stdin
    bool help = false,
    bool force = false,
    bool skipTagging = false,
  }) : _parsedArgs = <String, dynamic>{
    'increment': level,
    'commit': commit,
    'origin': origin,
    'just-print': justPrint,
    'yes': autoApprove,
    'help': help,
    'force': force,
    'skip-tagging': skipTagging,
  };

  @override
  String name;

  @override
  ArgResults command;

  @override
  final List<String> rest = <String>[];

  @override
  List<String> arguments;

  final Map<String, dynamic> _parsedArgs;

  @override
  Iterable<String> get options {
    return null;
  }

  @override
  dynamic operator [](String name) {
    return _parsedArgs[name];
  }

  @override
  bool wasParsed(String name) {
    return null;
  }
}

class MockGit extends Mock implements Git {}
