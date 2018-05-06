// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/commands/fuchsia_reload.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('FuchsiaDeviceCommandRunner', () {
    testUsingContext('a test', () async {
      final FuchsiaDeviceCommandRunner commandRunner =
          new FuchsiaDeviceCommandRunner('8.8.9.9',
                                         '~/fuchsia/out/release-x86-64');
      final List<String> ports = await commandRunner.run('ls /tmp');
      expect(ports, hasLength(3));
      expect(ports[0], equals('1234'));
      expect(ports[1], equals('5678'));
      expect(ports[2], equals('5'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => new MockProcessManager(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {
  @override
  Future<ProcessResult> run(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    Encoding stdoutEncoding: SYSTEM_ENCODING, // ignore: deprecated_member_use
    Encoding stderrEncoding: SYSTEM_ENCODING, // ignore: deprecated_member_use
  }) async {
    return new ProcessResult(0, 0, '1234\n5678\n5', '');
  }
}
