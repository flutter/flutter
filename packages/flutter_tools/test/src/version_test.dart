// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/version.dart';

import 'context.dart';

const JsonEncoder _kPrettyJsonEncoder = const JsonEncoder.withIndent('  ');
final Clock _testClock = new Clock.fixed(new DateTime(2015, 1, 1));
final DateTime _upToDateVersion = _testClock.agoBy(FlutterVersion.kVersionAgeConsideredUpToDate ~/ 2);
final DateTime _outOfDateVersion = _testClock.agoBy(FlutterVersion.kVersionAgeConsideredUpToDate * 2);
final DateTime _stampUpToDate = _testClock.agoBy(FlutterVersion.kCheckAgeConsideredUpToDate ~/ 2);
final DateTime _stampOutOfDate = _testClock.agoBy(FlutterVersion.kCheckAgeConsideredUpToDate * 2);
const String _stampMissing = '____stamp_missing____';

void main() {
  group('FlutterVersion', () {
    setUpAll(() {
      Cache.disableLocking();
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
        versionCheckStamp: _testStamp(
          lastTimeVersionWasChecked: _stampOutOfDate,
          lastKnownRemoteVersion: _outOfDateVersion,
        ),
        remoteCommitDate: _outOfDateVersion,
        expectSetStamp: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });

    testFlutterVersion('does not ping server when version stamp is up-to-date', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
        localCommitDate: _outOfDateVersion,
        versionCheckStamp: _testStamp(
          lastTimeVersionWasChecked: _stampUpToDate,
          lastKnownRemoteVersion: _upToDateVersion,
        ),
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));
    });

    testFlutterVersion('pings server when version stamp is missing', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          versionCheckStamp: _stampMissing,
          remoteCommitDate: _upToDateVersion,
          expectSetStamp: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));
    });

    testFlutterVersion('pings server when version stamp is out-of-date', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          versionCheckStamp: _testStamp(
              lastTimeVersionWasChecked: _stampOutOfDate,
              lastKnownRemoteVersion: _testClock.ago(days: 2),
          ),
          remoteCommitDate: _upToDateVersion,
          expectSetStamp: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage(FlutterVersion.versionOutOfDateMessage(_testClock.now().difference(_outOfDateVersion)));
    });

    testFlutterVersion('ignores network issues', () async {
      final FlutterVersion version = FlutterVersion.instance;

      fakeData(
          localCommitDate: _outOfDateVersion,
          versionCheckStamp: _stampMissing,
          errorOnFetch: true,
      );

      await version.checkFlutterVersionFreshness();
      _expectVersionMessage('');
    });
  });
}

void _expectVersionMessage(String message) {
  final BufferLogger logger = context[Logger];
  expect(logger.statusText.trim(), message.trim());
}

String _testStamp({@required DateTime lastTimeVersionWasChecked, @required DateTime lastKnownRemoteVersion}) {
  return _kPrettyJsonEncoder.convert(<String, String>{
    'lastTimeVersionWasChecked': '$lastTimeVersionWasChecked',
    'lastKnownRemoteVersion': '$lastKnownRemoteVersion',
  });
}

void testFlutterVersion(String description, dynamic testMethod()) {
  testUsingContext(
    description,
    testMethod,
    overrides: <Type, Generator>{
      FlutterVersion: () => new FlutterVersion(_testClock),
      ProcessManager: () => new MockProcessManager(),
      Cache: () => new MockCache(),
    },
  );
}

void fakeData({
  @required DateTime localCommitDate,
  DateTime remoteCommitDate,
  String versionCheckStamp,
  bool expectSetStamp: false,
  bool errorOnFetch: false,
}) {
  final MockProcessManager pm = context[ProcessManager];
  final MockCache cache = context[Cache];

  ProcessResult success(String standardOutput) {
    return new ProcessResult(1, 0, standardOutput, '');
  }

  ProcessResult failure(int exitCode) {
    return new ProcessResult(1, exitCode, '', 'error');
  }

  when(cache.getStampFor(any)).thenAnswer((Invocation invocation) {
    expect(invocation.positionalArguments.single, FlutterVersion.kFlutterVersionCheckStampFile);

    if (versionCheckStamp == _stampMissing) {
      return null;
    }

    if (versionCheckStamp != null) {
      return versionCheckStamp;
    }

    throw new StateError('Unexpected call to Cache.getStampFor(${invocation.positionalArguments}, ${invocation.namedArguments})');
  });

  when(cache.setStampFor(any, any)).thenAnswer((Invocation invocation) {
    expect(invocation.positionalArguments.first, FlutterVersion.kFlutterVersionCheckStampFile);

    if (expectSetStamp) {
      expect(invocation.positionalArguments[1], _testStamp(
        lastKnownRemoteVersion: remoteCommitDate,
        lastTimeVersionWasChecked: _testClock.now(),
      ));
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
