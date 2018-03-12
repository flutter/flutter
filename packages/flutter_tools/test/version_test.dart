// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart' show ListEquality;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/version.dart';

import 'src/context.dart';

final Clock _testClock = new Clock.fixed(new DateTime(2015, 1, 1));
final DateTime _upToDateVersion = _testClock.agoBy(FlutterVersion.kVersionAgeConsideredUpToDate ~/ 2);
final DateTime _outOfDateVersion = _testClock.agoBy(FlutterVersion.kVersionAgeConsideredUpToDate * 2);
final DateTime _stampUpToDate = _testClock.agoBy(FlutterVersion.kCheckAgeConsideredUpToDate ~/ 2);
final DateTime _stampOutOfDate = _testClock.agoBy(FlutterVersion.kCheckAgeConsideredUpToDate * 2);

void main() {
  group('$FlutterVersion', () {
    ProcessManager mockProcessManager;

    setUpAll(() {
      Cache.disableLocking();
      FlutterVersion.kPauseToLetUserReadTheMessage = Duration.zero;
    });

    setUp(() {
      mockProcessManager = new MockProcessManager();
    });

    testFlutterVersion('prints nothing when Flutter installation looks fresh', () async {
      fakeData(localCommitDate: _upToDateVersion);
      await FlutterVersion.instance.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });

    testFlutterVersion('prints nothing when Flutter installation looks out-of-date by is actually up-to-date', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
        localCommitDate: _outOfDateVersion,
        stamp: new VersionCheckStamp(
          lastTimeVersionWasChecked: _stampOutOfDate,
          lastKnownRemoteVersion: _outOfDateVersion,
        ),
        remoteCommitDate: _outOfDateVersion,
        expectSetStamp: true,
        expectServerPing: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });

    testFlutterVersion('does not ping server when version stamp is up-to-date', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
        localCommitDate: _outOfDateVersion,
        stamp: new VersionCheckStamp(
          lastTimeVersionWasChecked: _stampUpToDate,
          lastKnownRemoteVersion: _upToDateVersion,
        ),
        expectSetStamp: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));
    });

    testFlutterVersion('does not print warning if printed recently', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          stamp: new VersionCheckStamp(
              lastTimeVersionWasChecked: _stampUpToDate,
              lastKnownRemoteVersion: _upToDateVersion,
          ),
          expectSetStamp: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));
      expect((await VersionCheckStamp.load()).lastTimeWarningWasPrinted, _testClock.now());

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });

    testFlutterVersion('pings server when version stamp is missing then does not', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          remoteCommitDate: _upToDateVersion,
          expectSetStamp: true,
          expectServerPing: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));

      // Immediate subsequent check is not expected to ping the server.
      fakeData(
        localCommitDate: _outOfDateVersion,
        stamp: await VersionCheckStamp.load(),
      );
      await version.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });

    testFlutterVersion('pings server when version stamp is out-of-date', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          stamp: new VersionCheckStamp(
              lastTimeVersionWasChecked: _stampOutOfDate,
              lastKnownRemoteVersion: _testClock.ago(days: 2),
          ),
          remoteCommitDate: _upToDateVersion,
          expectSetStamp: true,
          expectServerPing: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));
    });

    testFlutterVersion('ignores network issues', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          errorOnFetch: true,
          expectServerPing: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });

    testUsingContext('versions comparison', () async {
      when(mockProcessManager.runSync(
        <String>['git', 'merge-base', '--is-ancestor', 'abcdef', '123456'],
        workingDirectory: any,
      )).thenReturn(new ProcessResult(1, 0, '', ''));

      expect(
        FlutterVersion.instance.checkRevisionAncestry(
          tentativeDescendantRevision: '123456',
          tentativeAncestorRevision: 'abcdef',
        ),
        true
      );

      verify(mockProcessManager.runSync(
        <String>['git', 'merge-base', '--is-ancestor', 'abcdef', '123456'],
        workingDirectory: any,
      ));
    },
    overrides: <Type, Generator>{
      FlutterVersion: () => new FlutterVersion(_testClock),
      ProcessManager: () => mockProcessManager,
    });
  });

  group('$VersionCheckStamp', () {
    void _expectDefault(VersionCheckStamp stamp) {
      expect(stamp.lastKnownRemoteVersion, isNull);
      expect(stamp.lastTimeVersionWasChecked, isNull);
      expect(stamp.lastTimeWarningWasPrinted, isNull);
    }

    testFlutterVersion('loads blank when stamp file missing', () async {
      fakeData();
      _expectDefault(await VersionCheckStamp.load());
    });

    testFlutterVersion('loads blank when stamp file is malformed JSON', () async {
      fakeData(stampJson: '<');
      _expectDefault(await VersionCheckStamp.load());
    });

    testFlutterVersion('loads blank when stamp file is well-formed but invalid JSON', () async {
      fakeData(stampJson: '[]');
      _expectDefault(await VersionCheckStamp.load());
    });

    testFlutterVersion('loads valid JSON', () async {
      fakeData(stampJson: '''
      {
        "lastKnownRemoteVersion": "${_testClock.ago(days: 1)}",
        "lastTimeVersionWasChecked": "${_testClock.ago(days: 2)}",
        "lastTimeWarningWasPrinted": "${_testClock.now()}"
      }
      ''');

      final VersionCheckStamp stamp = await VersionCheckStamp.load();
      expect(stamp.lastKnownRemoteVersion, _testClock.ago(days: 1));
      expect(stamp.lastTimeVersionWasChecked, _testClock.ago(days: 2));
      expect(stamp.lastTimeWarningWasPrinted, _testClock.now());
    });

    testFlutterVersion('stores version stamp', () async {
      fakeData(expectSetStamp: true);

      _expectDefault(await VersionCheckStamp.load());

      final VersionCheckStamp stamp = new VersionCheckStamp(
        lastKnownRemoteVersion: _testClock.ago(days: 1),
        lastTimeVersionWasChecked: _testClock.ago(days: 2),
        lastTimeWarningWasPrinted: _testClock.now(),
      );
      await stamp.store();

      final VersionCheckStamp storedStamp = await VersionCheckStamp.load();
      expect(storedStamp.lastKnownRemoteVersion, _testClock.ago(days: 1));
      expect(storedStamp.lastTimeVersionWasChecked, _testClock.ago(days: 2));
      expect(storedStamp.lastTimeWarningWasPrinted, _testClock.now());
    });

    testFlutterVersion('overwrites individual fields', () async {
      fakeData(expectSetStamp: true);

      _expectDefault(await VersionCheckStamp.load());

      final VersionCheckStamp stamp = new VersionCheckStamp(
        lastKnownRemoteVersion: _testClock.ago(days: 10),
        lastTimeVersionWasChecked: _testClock.ago(days: 9),
        lastTimeWarningWasPrinted: _testClock.ago(days: 8),
      );
      await stamp.store(
        newKnownRemoteVersion: _testClock.ago(days: 1),
        newTimeVersionWasChecked: _testClock.ago(days: 2),
        newTimeWarningWasPrinted: _testClock.now(),
      );

      final VersionCheckStamp storedStamp = await VersionCheckStamp.load();
      expect(storedStamp.lastKnownRemoteVersion, _testClock.ago(days: 1));
      expect(storedStamp.lastTimeVersionWasChecked, _testClock.ago(days: 2));
      expect(storedStamp.lastTimeWarningWasPrinted, _testClock.now());
    });
  });
}

void _expectVersionMessage(String message) {
  final BufferLogger logger = context[Logger];
  expect(logger.statusText.trim(), message.trim());
  logger.clear();
}

void testFlutterVersion(String description, dynamic testMethod()) {
  testUsingContext(
    description,
    testMethod,
    overrides: <Type, Generator>{
      FlutterVersion: () => new FlutterVersion(_testClock),
    },
  );
}

void fakeData({
  DateTime localCommitDate,
  DateTime remoteCommitDate,
  VersionCheckStamp stamp,
  String stampJson,
  bool errorOnFetch: false,
  bool expectSetStamp: false,
  bool expectServerPing: false,
}) {
  final MockProcessManager pm = new MockProcessManager();
  context.setVariable(ProcessManager, pm);

  final MockCache cache = new MockCache();
  context.setVariable(Cache, cache);

  ProcessResult success(String standardOutput) {
    return new ProcessResult(1, 0, standardOutput, '');
  }

  ProcessResult failure(int exitCode) {
    return new ProcessResult(1, exitCode, '', 'error');
  }

  when(cache.getStampFor(any)).thenAnswer((Invocation invocation) {
    expect(invocation.positionalArguments.single, VersionCheckStamp.kFlutterVersionCheckStampFile);

    if (stampJson != null)
      return stampJson;

    if (stamp != null)
      return json.encode(stamp.toJson());

    return null;
  });

  when(cache.setStampFor(any, any)).thenAnswer((Invocation invocation) {
    expect(invocation.positionalArguments.first, VersionCheckStamp.kFlutterVersionCheckStampFile);

    if (expectSetStamp) {
      stamp = VersionCheckStamp.fromJson(json.decode(invocation.positionalArguments[1]));
      return null;
    }

    throw new StateError('Unexpected call to Cache.setStampFor(${invocation.positionalArguments}, ${invocation.namedArguments})');
  });

  final Answering syncAnswer = (Invocation invocation) {
    bool argsAre(String a1, [String a2, String a3, String a4, String a5, String a6, String a7, String a8]) {
      const ListEquality<String> equality = const ListEquality<String>();
      final List<String> args = invocation.positionalArguments.single;
      final List<String> expectedArgs =
      <String>[a1, a2, a3, a4, a5, a6, a7, a8]
          .where((String arg) => arg != null)
          .toList();
      return equality.equals(args, expectedArgs);
    }

    if (argsAre('git', 'log', '-n', '1', '--pretty=format:%ad', '--date=iso')) {
      return success(localCommitDate.toString());
    } else if (argsAre('git', 'remote')) {
      return success('');
    } else if (argsAre('git', 'remote', 'add', '__flutter_version_check__', 'https://github.com/flutter/flutter.git')) {
      return success('');
    } else if (argsAre('git', 'fetch', '__flutter_version_check__', 'master')) {
      if (!expectServerPing)
        fail('Did not expect server ping');
      return errorOnFetch ? failure(128) : success('');
    } else if (remoteCommitDate != null && argsAre('git', 'log', '__flutter_version_check__/master', '-n', '1', '--pretty=format:%ad', '--date=iso')) {
      return success(remoteCommitDate.toString());
    }

    throw new StateError('Unexpected call to ProcessManager.run(${invocation.positionalArguments}, ${invocation.namedArguments})');
  };

  when(pm.runSync(any, workingDirectory: any)).thenAnswer(syncAnswer);
  when(pm.run(any, workingDirectory: any)).thenAnswer((Invocation invocation) async {
    return syncAnswer(invocation);
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockCache extends Mock implements Cache {}
