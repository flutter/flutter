// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_process_manager.dart';

final SystemClock _testClock = SystemClock.fixed(DateTime(2015, 1, 1));
final DateTime _stampUpToDate = _testClock.ago(FlutterVersion.checkAgeConsideredUpToDate ~/ 2);
final DateTime _stampOutOfDate = _testClock.ago(FlutterVersion.checkAgeConsideredUpToDate * 2);

void main() {
  MockProcessManager mockProcessManager;
  MockCache mockCache;
  FakeProcessManager processManager;

  setUp(() {
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    mockProcessManager = MockProcessManager();
    mockCache = MockCache();
  });

  testUsingContext('Channel enum and string transform to each other', () {
    for (final Channel channel in Channel.values) {
      expect(getNameForChannel(channel), kOfficialChannels.toList()[channel.index]);
    }
    expect(kOfficialChannels.toList().map((String str) => getChannelForName(str)).toList(),
      Channel.values);
  });

  for (final String channel in kOfficialChannels) {
    DateTime getChannelUpToDateVersion() {
      return _testClock.ago(FlutterVersion.versionAgeConsideredUpToDate(channel) ~/ 2);
    }

    DateTime getChannelOutOfDateVersion() {
      return _testClock.ago(FlutterVersion.versionAgeConsideredUpToDate(channel) * 2);
    }

    group('$FlutterVersion for $channel', () {
      setUpAll(() {
        Cache.disableLocking();
        FlutterVersion.timeToPauseToLetUserReadTheMessage = Duration.zero;
      });

      testUsingContext('prints nothing when Flutter installation looks fresh', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelUpToDateVersion(),
          // Server will be pinged because we haven't pinged within last x days
          expectServerPing: true,
          remoteCommitDate: getChannelOutOfDateVersion(),
          expectSetStamp: true,
          channel: channel,
        );

        processManager.addCommand(const FakeCommand(
          command: <String>['git', '-c', 'log.showSignature=false', 'log', '-n', '1', '--pretty=format:%H'],
          stdout: '1234abcd',
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'tag', '--points-at', '1234abcd'],
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', '1234abcd'],
          stdout: '0.1.2-3-1234abcd',
        ));

        processManager.addCommand(FakeCommand(
          command: const <String>['git', 'rev-parse', '--abbrev-ref', '--symbolic', '@{u}'],
          stdout: channel,
        ));

        processManager.addCommand(FakeCommand(
          command: const <String>['git', '-c', 'log.showSignature=false', 'log', '-n', '1', '--pretty=format:%ad', '--date=iso'],
          stdout: getChannelUpToDateVersion().toString(),
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'remote'],
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'remote', 'add', '__flutter_version_check__', 'https://github.com/flutter/flutter.git'],
        ));

        processManager.addCommand(FakeCommand(
          command: <String>['git', 'fetch', '__flutter_version_check__', channel],
        ));

        processManager.addCommand(FakeCommand(
          command: <String>['git', '-c', 'log.showSignature=false', 'log', '__flutter_version_check__/$channel', '-n', '1', '--pretty=format:%ad', '--date=iso'],
          stdout: getChannelOutOfDateVersion().toString(),
        ));
        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'remote'],
        ));

        await globals.flutterVersion.checkFlutterVersionFreshness();
        _expectVersionMessage('');
        expect(processManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => processManager,
        Cache: () => mockCache,
      });

      testUsingContext('prints nothing when Flutter installation looks out-of-date but is actually up-to-date', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampOutOfDate,
            lastKnownRemoteVersion: getChannelOutOfDateVersion(),
          ),
          remoteCommitDate: getChannelOutOfDateVersion(),
          expectSetStamp: true,
          expectServerPing: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage('');
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('does not ping server when version stamp is up-to-date', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampUpToDate,
            lastKnownRemoteVersion: getChannelUpToDateVersion(),
          ),
          expectSetStamp: true,
          channel: channel,
        );

        final FlutterVersion version = globals.flutterVersion;
        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('does not print warning if printed recently', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampUpToDate,
            lastKnownRemoteVersion: getChannelUpToDateVersion(),
          ),
          expectSetStamp: true,
          channel: channel,
        );

        final FlutterVersion version = globals.flutterVersion;
        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage());
        expect((await VersionCheckStamp.load()).lastTimeWarningWasPrinted, _testClock.now());

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage('');
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('pings server when version stamp is missing then does not', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          remoteCommitDate: getChannelUpToDateVersion(),
          expectSetStamp: true,
          expectServerPing: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage());

        // Immediate subsequent check is not expected to ping the server.
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          stamp: await VersionCheckStamp.load(),
          channel: channel,
        );
        await version.checkFlutterVersionFreshness();
        _expectVersionMessage('');
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('pings server when version stamp is out-of-date', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampOutOfDate,
            lastKnownRemoteVersion: _testClock.ago(const Duration(days: 2)),
          ),
          remoteCommitDate: getChannelUpToDateVersion(),
          expectSetStamp: true,
          expectServerPing: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('does not print warning when unable to connect to server if not out of date', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelUpToDateVersion(),
          errorOnFetch: true,
          expectServerPing: true,
          expectSetStamp: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage('');
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('prints warning when unable to connect to server if really out of date', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          errorOnFetch: true,
          expectServerPing: true,
          expectSetStamp: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(getChannelOutOfDateVersion())));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('versions comparison', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersion(),
          errorOnFetch: true,
          expectServerPing: true,
          expectSetStamp: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        when(mockProcessManager.runSync(
          <String>['git', 'merge-base', '--is-ancestor', 'abcdef', '123456'],
          workingDirectory: anyNamed('workingDirectory'),
        )).thenReturn(ProcessResult(1, 0, '', ''));

        expect(
            version.checkRevisionAncestry(
              tentativeDescendantRevision: '123456',
              tentativeAncestorRevision: 'abcdef',
            ),
            true);

        verify(mockProcessManager.runSync(
          <String>['git', 'merge-base', '--is-ancestor', 'abcdef', '123456'],
          workingDirectory: anyNamed('workingDirectory'),
        ));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
      });
    });

    group('$VersionCheckStamp for $channel', () {
      void _expectDefault(VersionCheckStamp stamp) {
        expect(stamp.lastKnownRemoteVersion, isNull);
        expect(stamp.lastTimeVersionWasChecked, isNull);
        expect(stamp.lastTimeWarningWasPrinted, isNull);
      }

      testUsingContext('loads blank when stamp file missing', () async {
        fakeData(mockProcessManager, mockCache, channel: channel);
        _expectDefault(await VersionCheckStamp.load());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('loads blank when stamp file is malformed JSON', () async {
        fakeData(mockProcessManager, mockCache, stampJson: '<', channel: channel);
        _expectDefault(await VersionCheckStamp.load());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('loads blank when stamp file is well-formed but invalid JSON', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          stampJson: '[]',
          channel: channel,
        );
        _expectDefault(await VersionCheckStamp.load());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('loads valid JSON', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          stampJson: '''
      {
        "lastKnownRemoteVersion": "${_testClock.ago(const Duration(days: 1))}",
        "lastTimeVersionWasChecked": "${_testClock.ago(const Duration(days: 2))}",
        "lastTimeWarningWasPrinted": "${_testClock.now()}"
      }
      ''',
          channel: channel,
        );

        final VersionCheckStamp stamp = await VersionCheckStamp.load();
        expect(stamp.lastKnownRemoteVersion, _testClock.ago(const Duration(days: 1)));
        expect(stamp.lastTimeVersionWasChecked, _testClock.ago(const Duration(days: 2)));
        expect(stamp.lastTimeWarningWasPrinted, _testClock.now());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('stores version stamp', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          expectSetStamp: true,
          channel: channel,
        );

        _expectDefault(await VersionCheckStamp.load());

        final VersionCheckStamp stamp = VersionCheckStamp(
          lastKnownRemoteVersion: _testClock.ago(const Duration(days: 1)),
          lastTimeVersionWasChecked: _testClock.ago(const Duration(days: 2)),
          lastTimeWarningWasPrinted: _testClock.now(),
        );
        await stamp.store();

        final VersionCheckStamp storedStamp = await VersionCheckStamp.load();
        expect(storedStamp.lastKnownRemoteVersion, _testClock.ago(const Duration(days: 1)));
        expect(storedStamp.lastTimeVersionWasChecked, _testClock.ago(const Duration(days: 2)));
        expect(storedStamp.lastTimeWarningWasPrinted, _testClock.now());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('overwrites individual fields', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          expectSetStamp: true,
          channel: channel,
        );

        _expectDefault(await VersionCheckStamp.load());

        final VersionCheckStamp stamp = VersionCheckStamp(
          lastKnownRemoteVersion: _testClock.ago(const Duration(days: 10)),
          lastTimeVersionWasChecked: _testClock.ago(const Duration(days: 9)),
          lastTimeWarningWasPrinted: _testClock.ago(const Duration(days: 8)),
        );
        await stamp.store(
          newKnownRemoteVersion: _testClock.ago(const Duration(days: 1)),
          newTimeVersionWasChecked: _testClock.ago(const Duration(days: 2)),
          newTimeWarningWasPrinted: _testClock.now(),
        );

        final VersionCheckStamp storedStamp = await VersionCheckStamp.load();
        expect(storedStamp.lastKnownRemoteVersion, _testClock.ago(const Duration(days: 1)));
        expect(storedStamp.lastTimeVersionWasChecked, _testClock.ago(const Duration(days: 2)));
        expect(storedStamp.lastTimeWarningWasPrinted, _testClock.now());
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });
    });
  }

  testUsingContext('GitTagVersion', () {
    const String hash = 'abcdef';
    GitTagVersion gitTagVersion;

    // Master channel
    gitTagVersion = GitTagVersion.parse('1.2.3-4.5.pre-13-g$hash');
    expect(gitTagVersion.frameworkVersionFor(hash), '1.2.3-5.0.pre.13');
    expect(gitTagVersion.gitTag, '1.2.3-4.5.pre');
    expect(gitTagVersion.devVersion, 4);
    expect(gitTagVersion.devPatch, 5);

    // Stable channel
    gitTagVersion = GitTagVersion.parse('1.2.3');
    expect(gitTagVersion.frameworkVersionFor(hash), '1.2.3');
    expect(gitTagVersion.x, 1);
    expect(gitTagVersion.y, 2);
    expect(gitTagVersion.z, 3);
    expect(gitTagVersion.devVersion, null);
    expect(gitTagVersion.devPatch, null);

    // Dev channel
    gitTagVersion = GitTagVersion.parse('1.2.3-4.5.pre');
    expect(gitTagVersion.frameworkVersionFor(hash), '1.2.3-4.5.pre');
    expect(gitTagVersion.gitTag, '1.2.3-4.5.pre');
    expect(gitTagVersion.devVersion, 4);
    expect(gitTagVersion.devPatch, 5);

    gitTagVersion = GitTagVersion.parse('1.2.3-13-g$hash');
    expect(gitTagVersion.frameworkVersionFor(hash), '1.2.4-0.0.pre.13');
    expect(gitTagVersion.gitTag, '1.2.3');
    expect(gitTagVersion.devVersion, null);
    expect(gitTagVersion.devPatch, null);

    // new tag release format, dev channel
    gitTagVersion = GitTagVersion.parse('1.2.3-4.5.pre-0-g$hash');
    expect(gitTagVersion.frameworkVersionFor(hash), '1.2.3-4.5.pre');
    expect(gitTagVersion.gitTag, '1.2.3-4.5.pre');
    expect(gitTagVersion.devVersion, 4);
    expect(gitTagVersion.devPatch, 5);

    // new tag release format, stable channel
    gitTagVersion = GitTagVersion.parse('1.2.3-13-g$hash');
    expect(gitTagVersion.frameworkVersionFor(hash), '1.2.4-0.0.pre.13');
    expect(gitTagVersion.gitTag, '1.2.3');
    expect(gitTagVersion.devVersion, null);
    expect(gitTagVersion.devPatch, null);

    expect(GitTagVersion.parse('98.76.54-32-g$hash').frameworkVersionFor(hash), '98.76.55-0.0.pre.32');
    expect(GitTagVersion.parse('10.20.30-0-g$hash').frameworkVersionFor(hash), '10.20.30');
    expect(testLogger.traceText, '');
    expect(GitTagVersion.parse('v1.2.3+hotfix.1-4-g$hash').frameworkVersionFor(hash), '0.0.0-unknown');
    expect(GitTagVersion.parse('x1.2.3-4-g$hash').frameworkVersionFor(hash), '0.0.0-unknown');
    expect(GitTagVersion.parse('1.0.0-unknown-0-g$hash').frameworkVersionFor(hash), '0.0.0-unknown');
    expect(GitTagVersion.parse('beta-1-g$hash').frameworkVersionFor(hash), '0.0.0-unknown');
    expect(GitTagVersion.parse('1.2.3-4-gx$hash').frameworkVersionFor(hash), '0.0.0-unknown');
    expect(testLogger.statusText, '');
    expect(testLogger.errorText, '');
    expect(
      testLogger.traceText,
      'Could not interpret results of "git describe": v1.2.3+hotfix.1-4-gabcdef\n'
      'Could not interpret results of "git describe": x1.2.3-4-gabcdef\n'
      'Could not interpret results of "git describe": 1.0.0-unknown-0-gabcdef\n'
      'Could not interpret results of "git describe": beta-1-gabcdef\n'
      'Could not interpret results of "git describe": 1.2.3-4-gxabcdef\n',
    );
  });

  testUsingContext('determine reports correct stable version if HEAD is at a tag', () {
    const String stableTag = '1.2.3';
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: stableTag,
        ),
      ],
    );
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );
    final GitTagVersion gitTagVersion = GitTagVersion.determine(processUtils, workingDirectory: '.');
    expect(gitTagVersion.frameworkVersionFor('abcd1234'), stableTag);
  });

  testUsingContext('determine favors stable tag over dev tag if both identify HEAD', () {
    const String stableTag = '1.2.3';
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          // This tests the unlikely edge case where a dev release made it to stable without any cherry picks
          stdout: '1.2.3-6.0.pre\n$stableTag',
        ),
      ],
    );
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );
    final GitTagVersion gitTagVersion = GitTagVersion.determine(processUtils, workingDirectory: '.');
    expect(gitTagVersion.frameworkVersionFor('abcd1234'), stableTag);
  });

  testUsingContext('determine reports correct git describe version if HEAD is not at a tag', () {
    const String devTag = '1.2.3-2.0.pre';
    const String headRevision = 'abcd1234';
    const String commitsAhead = '12';
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'tag', '--points-at', 'HEAD'],
          stdout: '', // no tag
        ),
        const FakeCommand(
          command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
          stdout: '$devTag-$commitsAhead-g$headRevision',
        ),
      ],
    );
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );
    final GitTagVersion gitTagVersion = GitTagVersion.determine(processUtils, workingDirectory: '.');
    // reported version should increment the number after the dash
    expect(gitTagVersion.frameworkVersionFor(headRevision), '1.2.3-3.0.pre.12');
  });

  testUsingContext('determine does not call fetch --tags', () {
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', 'HEAD'],
      ),
      const FakeCommand(
        command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
        stdout: 'v0.1.2-3-1234abcd',
      ),
    ]);
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );

    GitTagVersion.determine(processUtils, workingDirectory: '.');
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testUsingContext('determine does not fetch tags on dev/stable/beta', () {
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        stdout: 'dev',
      ),
      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', 'HEAD'],
      ),
      const FakeCommand(
        command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
        stdout: 'v0.1.2-3-1234abcd',
      ),
    ]);
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );

    GitTagVersion.determine(processUtils, workingDirectory: '.', fetchTags: true);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testUsingContext('determine calls fetch --tags on master', () {
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        stdout: 'master',
      ),
      const FakeCommand(
        command: <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags', '-f'],
      ),
      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', 'HEAD'],
      ),
      const FakeCommand(
        command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
        stdout: 'v0.1.2-3-1234abcd',
      ),
    ]);
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );

    GitTagVersion.determine(processUtils, workingDirectory: '.', fetchTags: true);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  });

  testUsingContext('determine uses overridden git url', () {
    final FakeProcessManager fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        stdout: 'master',
      ),
      const FakeCommand(
        command: <String>['git', 'fetch', 'https://githubmirror.com/flutter.git', '--tags', '-f'],
      ),
      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', 'HEAD'],
      ),
      const FakeCommand(
        command: <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
        stdout: 'v0.1.2-3-1234abcd',
      ),
    ]);
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );

    GitTagVersion.determine(processUtils, workingDirectory: '.', fetchTags: true);
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    Platform: () => FakePlatform(environment: <String, String>{
      'FLUTTER_GIT_URL': 'https://githubmirror.com/flutter.git',
    }),
  });
}

void _expectVersionMessage(String message) {
  expect(testLogger.statusText.trim(), message.trim());
  testLogger.clear();
}

void fakeData(
  ProcessManager pm,
  Cache cache, {
  DateTime localCommitDate,
  DateTime remoteCommitDate,
  VersionCheckStamp stamp,
  String stampJson,
  bool errorOnFetch = false,
  bool expectSetStamp = false,
  bool expectServerPing = false,
  String channel = 'master',
}) {
  ProcessResult success(String standardOutput) {
    return ProcessResult(1, 0, standardOutput, '');
  }

  ProcessResult failure(int exitCode) {
    return ProcessResult(1, exitCode, '', 'error');
  }

  when(cache.getStampFor(any)).thenAnswer((Invocation invocation) {
    expect(invocation.positionalArguments.single, VersionCheckStamp.flutterVersionCheckStampFile);

    if (stampJson != null) {
      return stampJson;
    }

    if (stamp != null) {
      return json.encode(stamp.toJson());
    }

    return null;
  });

  when(cache.setStampFor(any, any)).thenAnswer((Invocation invocation) {
    expect(invocation.positionalArguments.first, VersionCheckStamp.flutterVersionCheckStampFile);

    if (expectSetStamp) {
      stamp = VersionCheckStamp.fromJson(castStringKeyedMap(json.decode(invocation.positionalArguments[1] as String)));
      return;
    }

    throw StateError('Unexpected call to Cache.setStampFor(${invocation.positionalArguments}, ${invocation.namedArguments})');
  });

  ProcessResult syncAnswer(Invocation invocation) {
    bool argsAre(String a1, [ String a2, String a3, String a4, String a5, String a6, String a7, String a8, String a9 ]) {
      const ListEquality<String> equality = ListEquality<String>();
      final List<String> args = invocation.positionalArguments.single as List<String>;
      final List<String> expectedArgs = <String>[a1, a2, a3, a4, a5, a6, a7, a8, a9].where((String arg) => arg != null).toList();
      return equality.equals(args, expectedArgs);
    }

    bool listArgsAre(List<String> a) {
      return Function.apply(argsAre, a) as bool;
    }

    if (listArgsAre(FlutterVersion.gitLog(<String>['-n', '1', '--pretty=format:%ad', '--date=iso']))) {
      return success(localCommitDate.toString());
    } else if (argsAre('git', 'remote')) {
      return success('');
    } else if (argsAre('git', 'remote', 'add', '__flutter_version_check__', 'https://github.com/flutter/flutter.git')) {
      return success('');
    } else if (argsAre('git', 'fetch', '__flutter_version_check__', channel)) {
      if (!expectServerPing) {
        fail('Did not expect server ping');
      }
      return errorOnFetch ? failure(128) : success('');
    // Careful here!  argsAre accepts 9 arguments and FlutterVersion.gitLog adds 4.
    } else if (remoteCommitDate != null && listArgsAre(FlutterVersion.gitLog(<String>['__flutter_version_check__/$channel', '-n', '1', '--pretty=format:%ad', '--date=iso']))) {
      return success(remoteCommitDate.toString());
    } else if (argsAre('git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags')) {
      return success('');
    }

    throw StateError('Unexpected call to ProcessManager.run(${invocation.positionalArguments}, ${invocation.namedArguments})');
  }

  when(pm.runSync(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer(syncAnswer);
  when(pm.run(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((Invocation invocation) async {
    return syncAnswer(invocation);
  });

  when(pm.runSync(
    <String>['git', 'rev-parse', '--abbrev-ref', '--symbolic', '@{u}'],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(101, 0, channel, ''));
  when(pm.runSync(
    <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(102, 0, 'branch', ''));
  when(pm.runSync(
    FlutterVersion.gitLog(<String>['-n', '1', '--pretty=format:%H']),
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(103, 0, '1234abcd', ''));
  when(pm.runSync(
    FlutterVersion.gitLog(<String>['-n', '1', '--pretty=format:%ar']),
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(104, 0, '1 second ago', ''));
  when(pm.runSync(
    <String>['git', 'fetch', 'https://github.com/flutter/flutter', '--tags'],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(105, 0, '', ''));
  when(pm.runSync(
    <String>['git', 'tag', '--points-at', '1234abcd'],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(106, 0, '', ''));
  when(pm.runSync(
    <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', '1234abcd'],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(107, 0, 'v0.1.2-3-1234abcd', ''));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockCache extends Mock implements Cache {}
