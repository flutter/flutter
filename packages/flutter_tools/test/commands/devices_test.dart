// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('devices', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('returns 0 when called', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
    });

    testUsingContext('no error when no connected devices', () async {
      final DevicesCommand command = DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
      expect(testLogger.statusText, contains('No devices detected'));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => null,
      DeviceManager: () => DeviceManager(),
      ProcessManager: () => MockProcessManager(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {
  @override
  Future<ProcessResult> run(
      List<dynamic> command, {
        String workingDirectory,
        Map<String, String> environment,
        bool includeParentEnvironment = true,
        bool runInShell = false,
        Encoding stdoutEncoding = systemEncoding,
        Encoding stderrEncoding = systemEncoding,
      }) async {
    return ProcessResult(0, 0, '', '');
  }

  @override
  ProcessResult runSync(
      List<dynamic> command, {
        String workingDirectory,
        Map<String, String> environment,
        bool includeParentEnvironment = true,
        bool runInShell = false,
        Encoding stdoutEncoding = systemEncoding,
        Encoding stderrEncoding = systemEncoding,
      }) {
    return ProcessResult(0, 0, '', '');
  }
}
