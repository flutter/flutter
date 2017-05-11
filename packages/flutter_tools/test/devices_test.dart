// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('devices', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('returns 0 when called', () async {
      final DevicesCommand command = new DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
    });

    testUsingContext('no error when no connected devices', () async {
      final DevicesCommand command = new DevicesCommand();
      await createTestCommandRunner(command).run(<String>['devices']);
      expect(testLogger.statusText, contains('No devices detected'));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => null,
      DeviceManager: () => new DeviceManager(),
      ProcessManager: () => new MockProcessManager(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {
  @override
  ProcessResult runSync(
      List<dynamic> command, {
        String workingDirectory,
        Map<String, String> environment,
        bool includeParentEnvironment: true,
        bool runInShell: false,
        Encoding stdoutEncoding: SYSTEM_ENCODING,
        Encoding stderrEncoding: SYSTEM_ENCODING,
      }) {
    return new ProcessResult(0, 0, '', '');
  }
}
