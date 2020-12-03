// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter_tools/src/base/context.dart';
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
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

final SystemClock _testClock = SystemClock.fixed(DateTime(2015, 1, 1));
final DateTime _stampUpToDate = _testClock.ago(FlutterVersion.checkAgeConsideredUpToDate ~/ 2);
final DateTime _stampOutOfDate = _testClock.ago(FlutterVersion.checkAgeConsideredUpToDate * 2);
const String _upToDateStableVersionString = '4.5.6';
const String _outOfDateStableVersionString = '1.2.3';
const String _upToDateDevVersionString = '4.5.6-7.8.pre';
const String _outOfDateDevVersionString = '1.2.3-4.5.pre';
const String _upToDateRevisionString = '5678dcba';
const String _outOfDateRevisionString = '1234abcd';

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
    DateTime getChannelUpToDateVersionDate() {
      return _testClock.ago(FlutterVersion.versionAgeConsideredUpToDate(channel) ~/ 2);
    }

    DateTime getChannelOutOfDateVersionDate() {
      return _testClock.ago(FlutterVersion.versionAgeConsideredUpToDate(channel) * 2);
    }

    String getChannelUpToDateVersionString() {
      return channel == 'stable' ? _upToDateStableVersionString : _upToDateDevVersionString;
    }

    String getChannelOutOfDateVersionString() {
      return channel == 'stable' ? _outOfDateStableVersionString : _outOfDateDevVersionString;
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
          localCommitDate: getChannelUpToDateVersionDate(),
          localCommitGitRef: _upToDateRevisionString,
          localVersion: getChannelUpToDateVersionString(),
          // Server will be pinged because we haven't pinged within last x days
          expectServerPing: true,
          remoteCommitDate: getChannelOutOfDateVersionDate(),
          expectSetStamp: true,
          channel: channel,
        );

        processManager.addCommand(const FakeCommand(
          command: <String>['git', '-c', 'log.showSignature=false', 'log', '-n', '1', '--pretty=format:%H'],
          stdout: _upToDateRevisionString,
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'tag', '--points-at', _upToDateRevisionString],
        ));

        processManager.addCommand(FakeCommand(
          command: const <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', _upToDateRevisionString],
          stdout: '${getChannelUpToDateVersionString()}-0-g$_upToDateRevisionString',
        ));

        processManager.addCommand(FakeCommand(
          command: const <String>['git', 'rev-parse', '--abbrev-ref', '--symbolic', '@{u}'],
          stdout: channel,
        ));

        processManager.addCommand(FakeCommand(
          command: const <String>['git', '-c', 'log.showSignature=false', 'log', 'HEAD', '-n', '1', '--pretty=format:%ad', '--date=iso'],
          stdout: getChannelUpToDateVersionDate().toString(),
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'fetch', '--tags'],
        ));

        processManager.addCommand(const FakeCommand(
          command: <String>['git', 'rev-parse', '--verify', '@{u}'],
          stdout: _outOfDateRevisionString,
        ));

        processManager.addCommand(FakeCommand(
          command: const <String>['git', '-c', 'log.showSignature=false', 'log', _outOfDateRevisionString, '-n', '1', '--pretty=format:%ad', '--date=iso'],
          stdout: getChannelOutOfDateVersionDate().toString(),
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
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampOutOfDate,
            lastKnownRemoteRevisionDate: getChannelOutOfDateVersionDate(),
            lastKnownRemoteRevision: _outOfDateRevisionString,
          ),
          remoteCommitDate: getChannelOutOfDateVersionDate(),
          remoteCommitGitRef: _outOfDateRevisionString,
          remoteVersion: getChannelOutOfDateVersionString(),
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
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampUpToDate,
            lastKnownRemoteRevisionDate: getChannelUpToDateVersionDate(),
            lastKnownRemoteRevision: _upToDateRevisionString,
          ),
          remoteCommitGitRef: _upToDateRevisionString,
          remoteVersion: getChannelUpToDateVersionString(),
          expectSetStamp: true,
          channel: channel,
        );

        final FlutterVersion version = globals.flutterVersion;
        final FlutterVersion latestVersion = MockFlutterVersion();
        when(latestVersion.frameworkRevision).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkRevisionShort).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkVersion).thenReturn(getChannelUpToDateVersionString());

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage(version, latestVersion));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('does not print warning if printed recently', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampUpToDate,
            lastKnownRemoteRevisionDate: getChannelUpToDateVersionDate(),
            lastKnownRemoteRevision: _upToDateRevisionString,
          ),
          remoteCommitGitRef: _upToDateRevisionString,
          remoteVersion: getChannelUpToDateVersionString(),
          expectSetStamp: true,
          channel: channel,
        );

        final FlutterVersion version = globals.flutterVersion;
        final FlutterVersion latestVersion = MockFlutterVersion();
        when(latestVersion.frameworkRevision).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkRevisionShort).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkVersion).thenReturn(getChannelUpToDateVersionString());

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage(version, latestVersion));
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
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
          remoteCommitDate: getChannelUpToDateVersionDate(),
          remoteCommitGitRef: _upToDateRevisionString,
          remoteVersion: getChannelUpToDateVersionString(),
          expectSetStamp: true,
          expectServerPing: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;
        final FlutterVersion latestVersion = MockFlutterVersion();
        when(latestVersion.frameworkRevision).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkRevisionShort).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkVersion).thenReturn(getChannelUpToDateVersionString());

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage(version, latestVersion));

        // Immediate subsequent check is not expected to ping the server.
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersionDate(),
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
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
          stamp: VersionCheckStamp(
            lastTimeVersionWasChecked: _stampOutOfDate,
            lastKnownRemoteRevisionDate: _testClock.ago(const Duration(days: 2)),
            lastKnownRemoteRevision: _upToDateRevisionString,
          ),
          remoteCommitDate: getChannelUpToDateVersionDate(),
          remoteCommitGitRef: _upToDateRevisionString,
          remoteVersion: getChannelUpToDateVersionString(),
          expectSetStamp: true,
          expectServerPing: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;
        final FlutterVersion latestVersion = MockFlutterVersion();
        when(latestVersion.frameworkRevision).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkRevisionShort).thenReturn(_upToDateRevisionString);
        when(latestVersion.frameworkVersion).thenReturn(getChannelUpToDateVersionString());

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.newVersionAvailableMessage(version, latestVersion));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('does not print warning when unable to connect to server if not out of date', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelUpToDateVersionDate(),
          localCommitGitRef: _upToDateRevisionString,
          localVersion: getChannelUpToDateVersionString(),
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
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
          errorOnFetch: true,
          expectServerPing: true,
          expectSetStamp: true,
          channel: channel,
        );
        final FlutterVersion version = globals.flutterVersion;

        await version.checkFlutterVersionFreshness();
        _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(getChannelOutOfDateVersionDate())));
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });

      testUsingContext('versions comparison', () async {
        fakeData(
          mockProcessManager,
          mockCache,
          localCommitDate: getChannelOutOfDateVersionDate(),
          localCommitGitRef: _outOfDateRevisionString,
          localVersion: getChannelOutOfDateVersionString(),
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
        expect(stamp.lastKnownRemoteRevisionDate, isNull);
        expect(stamp.lastTimeVersionWasChecked, isNull);
        expect(stamp.lastTimeWarningWasPrinted, isNull);
        expect(stamp.lastKnownRemoteRevision, isNull);
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
        "lastKnownRemoteRevisionDate": "${_testClock.ago(const Duration(days: 1))}",
        "lastTimeVersionWasChecked": "${_testClock.ago(const Duration(days: 2))}",
        "lastTimeWarningWasPrinted": "${_testClock.now()}",
        "lastKnownRemoteRevision": "$_upToDateRevisionString"
      }
      ''',
          channel: channel,
        );

        final VersionCheckStamp stamp = await VersionCheckStamp.load();
        expect(stamp.lastKnownRemoteRevisionDate, _testClock.ago(const Duration(days: 1)));
        expect(stamp.lastTimeVersionWasChecked, _testClock.ago(const Duration(days: 2)));
        expect(stamp.lastTimeWarningWasPrinted, _testClock.now());
        expect(stamp.lastKnownRemoteRevision, _upToDateRevisionString);
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
          lastKnownRemoteRevisionDate: _testClock.ago(const Duration(days: 1)),
          lastTimeVersionWasChecked: _testClock.ago(const Duration(days: 2)),
          lastTimeWarningWasPrinted: _testClock.now(),
          lastKnownRemoteRevision: _upToDateRevisionString,
        );
        await stamp.store();

        final VersionCheckStamp storedStamp = await VersionCheckStamp.load();
        expect(storedStamp.lastKnownRemoteRevisionDate, _testClock.ago(const Duration(days: 1)));
        expect(storedStamp.lastTimeVersionWasChecked, _testClock.ago(const Duration(days: 2)));
        expect(storedStamp.lastTimeWarningWasPrinted, _testClock.now());
        expect(storedStamp.lastKnownRemoteRevision, _upToDateRevisionString);
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
          lastKnownRemoteRevisionDate: _testClock.ago(const Duration(days: 10)),
          lastTimeVersionWasChecked: _testClock.ago(const Duration(days: 9)),
          lastTimeWarningWasPrinted: _testClock.ago(const Duration(days: 8)),
          lastKnownRemoteRevision: _outOfDateRevisionString,
        );
        await stamp.store(
          newKnownRemoteRevisionDate: _testClock.ago(const Duration(days: 1)),
          newTimeVersionWasChecked: _testClock.ago(const Duration(days: 2)),
          newTimeWarningWasPrinted: _testClock.now(),
          newKnownRemoteRevision: _upToDateRevisionString,
        );

        final VersionCheckStamp storedStamp = await VersionCheckStamp.load();
        expect(storedStamp.lastKnownRemoteRevisionDate, _testClock.ago(const Duration(days: 1)));
        expect(storedStamp.lastTimeVersionWasChecked, _testClock.ago(const Duration(days: 2)));
        expect(storedStamp.lastTimeWarningWasPrinted, _testClock.now());
        expect(storedStamp.lastKnownRemoteRevision, _upToDateRevisionString);
      }, overrides: <Type, Generator>{
        FlutterVersion: () => FlutterVersion(clock: _testClock),
        ProcessManager: () => mockProcessManager,
        Cache: () => mockCache,
      });
    });
  }

  testUsingContext('newVersionAvailableMessage prints update message correctly', () async {
    const String channel = 'dev';
    final DateTime localCommitDate = _testClock.ago(const Duration(days: 3));
    final DateTime remoteCommitDate = _testClock.ago(const Duration(days: 1));
    const String localVersion = '1.2.3-4.5.pre';
    const String localGitRef = 'abc12345';
    const String remoteVersion = '6.7.8-9.0.pre';
    const String remoteGitRef = 'def67890';
    const String updateMessage = '''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ A new version of Flutter is available on channel dev!                      ║
  ║                                                                            ║
  ║ The latest version: 6.7.8-9.0.pre (revision def67890)                      ║
  ║ Your current version: 1.2.3-4.5.pre (revision abc12345)                    ║
  ║                                                                            ║
  ║ To update to the latest version, run "flutter upgrade".                    ║
  ║ To view this information next time, run "flutter upgrade --verify-only".   ║
  ╚════════════════════════════════════════════════════════════════════════════╝
    ''';

    fakeData(
      mockProcessManager,
      mockCache,
      localCommitDate: localCommitDate,
      localCommitGitRef: localGitRef,
      localVersion: localVersion,
      remoteCommitDate: remoteCommitDate,
      remoteCommitGitRef: remoteGitRef,
      remoteVersion: remoteVersion,
      expectServerPing: true,
      expectSetStamp: true,
      channel: channel,
    );
    final FlutterVersion version = globals.flutterVersion;

    await version.checkFlutterVersionFreshness();
    _expectVersionMessage(updateMessage);
  }, overrides: <Type, Generator>{
    FlutterVersion: () => FlutterVersion(clock: _testClock),
    ProcessManager: () => mockProcessManager,
    Cache: () => mockCache,
  });

  testUsingContext('versionOutOfDateMessage prints message correctly', () async {
    const String channel = 'dev';
    final DateTime localCommitDate = _testClock.ago(const Duration(days: 42));
    const String localVersion = '1.2.3-4.5.pre';
    const String localGitRef = 'abc12345';
    const String warningMessage = '''
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║ WARNING: your installation of Flutter is 42 days old.                      ║
  ║                                                                            ║
  ║ To update to the latest version, run "flutter upgrade".                    ║
  ║ To only check for updates, run "flutter upgrade --verify-only".            ║
  ╚════════════════════════════════════════════════════════════════════════════╝
    ''';

    fakeData(
      mockProcessManager,
      mockCache,
      localCommitDate: localCommitDate,
      localCommitGitRef: localGitRef,
      localVersion: localVersion,
      errorOnFetch: true,
      expectServerPing: true,
      expectSetStamp: true,
      channel: channel,
    );
    final FlutterVersion version = globals.flutterVersion;

    await version.checkFlutterVersionFreshness();
    _expectVersionMessage(warningMessage);
  }, overrides: <Type, Generator>{
    FlutterVersion: () => FlutterVersion(clock: _testClock),
    ProcessManager: () => mockProcessManager,
    Cache: () => mockCache,
  });

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

  testUsingContext('determine favors stable tag over dev tag if both idenitfy HEAD', () {
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
    final MockProcessUtils processUtils = MockProcessUtils();
    when(processUtils.runSync(
      <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(105, 0, '', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(106, 0, 'v0.1.2-3-1234abcd', ''), <String>['git', 'describe']));
    when(processUtils.runSync(
      <String>['git', 'tag', '--points-at', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(
      RunResult(ProcessResult(110, 0, '', ''),
      <String>['git', 'tag', '--points-at', 'HEAD'],
    ));

    GitTagVersion.determine(processUtils, workingDirectory: '.');

    verifyNever(processUtils.runSync(
      <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    ));
    verifyNever(processUtils.runSync(
      <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    ));
    verify(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
  });

  testUsingContext('determine does not fetch tags on dev/stable/beta', () {
    final MockProcessUtils processUtils = MockProcessUtils();
    when(processUtils.runSync(
      <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(105, 0, 'dev', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(106, 0, '', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(107, 0, 'v0.1.2-3-1234abcd', ''), <String>['git', 'describe']));
    when(processUtils.runSync(
      <String>['git', 'tag', '--points-at', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(
      RunResult(ProcessResult(108, 0, '', ''),
      <String>['git', 'tag', '--points-at', 'HEAD'],
    ));

    GitTagVersion.determine(processUtils, workingDirectory: '.', fetchTags: true);

    verify(processUtils.runSync(
      <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
    verifyNever(processUtils.runSync(
      <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    ));
    verify(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
  });

  testUsingContext('determine calls fetch --tags on master', () {
    final MockProcessUtils processUtils = MockProcessUtils();
    when(processUtils.runSync(
      <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(108, 0, 'master', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags', '-f'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(109, 0, '', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'tag', '--points-at', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(
      RunResult(ProcessResult(110, 0, '', ''),
      <String>['git', 'tag', '--points-at', 'HEAD'],
    ));
    when(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(111, 0, 'v0.1.2-3-1234abcd', ''), <String>['git', 'describe']));

    GitTagVersion.determine(processUtils, workingDirectory: '.', fetchTags: true);

    verify(processUtils.runSync(
      <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
    verify(processUtils.runSync(
      <String>['git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags', '-f'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
    verify(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
  });

  testUsingContext('determine uses overridden git url', () {
    final MockProcessUtils processUtils = MockProcessUtils();
    when(processUtils.runSync(
      <String>['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(108, 0, 'master', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'fetch', 'https://githubmirror.com/flutter.git', '--tags', '-f'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(109, 0, '', ''), <String>['git', 'fetch']));
    when(processUtils.runSync(
      <String>['git', 'tag', '--points-at', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(
      RunResult(ProcessResult(110, 0, '', ''),
      <String>['git', 'tag', '--points-at', 'HEAD'],
    ));
    when(processUtils.runSync(
      <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', 'HEAD'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenReturn(RunResult(ProcessResult(111, 0, 'v0.1.2-3-1234abcd', ''), <String>['git', 'describe']));

    GitTagVersion.determine(processUtils, workingDirectory: '.', fetchTags: true);

    verify(processUtils.runSync(
      <String>['git', 'fetch', 'https://githubmirror.com/flutter.git', '--tags', '-f'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).called(1);
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
  String localVersion,
  String remoteVersion,
  String localCommitGitRef,
  String remoteCommitGitRef,
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

  final Answering<ProcessResult> syncAnswer = (Invocation invocation) {
    bool argsAre(String a1, [ String a2, String a3, String a4, String a5, String a6, String a7, String a8, String a9 ]) {
      const ListEquality<String> equality = ListEquality<String>();
      final List<String> args = invocation.positionalArguments.single as List<String>;
      final List<String> expectedArgs = <String>[a1, a2, a3, a4, a5, a6, a7, a8, a9].where((String arg) => arg != null).toList();
      return equality.equals(args, expectedArgs);
    }

    bool listArgsAre(List<String> a) {
      return Function.apply(argsAre, a) as bool;
    }

    if (listArgsAre(FlutterVersion.gitLog(<String>['HEAD', '-n', '1', '--pretty=format:%ad', '--date=iso']))) {
      return success(localCommitDate.toString());
    } else if (argsAre('git', 'rev-parse', '--verify', '@{u}')) {
      return success(remoteCommitGitRef);
    } else if (argsAre('git', 'fetch', '--tags')) {
      if (!expectServerPing) {
        fail('Did not expect server ping');
      }
      return errorOnFetch ? failure(128) : success('');
    // Careful here!  argsAre accepts 9 arguments and FlutterVersion.gitLog adds 4.
    } else if (remoteCommitDate != null && listArgsAre(FlutterVersion.gitLog(<String>[remoteCommitGitRef, '-n', '1', '--pretty=format:%ad', '--date=iso']))) {
      return success(remoteCommitDate.toString());
    } else if (argsAre('git', 'fetch', 'https://github.com/flutter/flutter.git', '--tags')) {
      return success('');
    }

    throw StateError('Unexpected call to ProcessManager.run(${invocation.positionalArguments}, ${invocation.namedArguments})');
  };

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
  )).thenReturn(ProcessResult(103, 0, localCommitGitRef, ''));
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
    <String>['git', 'tag', '--points-at', localCommitGitRef],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(106, 0, '', ''));
  when(pm.runSync(
    <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', localCommitGitRef],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(107, 0, '$localVersion-0-g$localCommitGitRef', ''));
  when(pm.runSync(
    <String>['git', 'tag', '--points-at', remoteCommitGitRef],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(108, 0, '', ''));
  when(pm.runSync(
    <String>['git', 'describe', '--match', '*.*.*', '--long', '--tags', remoteCommitGitRef],
    workingDirectory: anyNamed('workingDirectory'),
    environment: anyNamed('environment'),
  )).thenReturn(ProcessResult(109, 0, '$remoteVersion-0-g$remoteCommitGitRef', ''));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcessUtils extends Mock implements ProcessUtils {}
class MockCache extends Mock implements Cache {}
