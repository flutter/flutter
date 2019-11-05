// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
    Cache.flutterRoot = '';
  });

  final Testbed testbed = Testbed(setup: () {
    when(doctor.canLaunchAnything).thenReturn(true);

    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fs.directory('android').createSync();
    fs.directory('ios').createSync();
  }, overrides: <Type, Generator>{
    Doctor: () => MockFlutterDoctor(),
  });

  // This test forces flutter to check for all possible devices to catch issues
  // like https://github.com/flutter/flutter/issues/21418 which were skipped
  // over because other integration tests run using flutter-tester which short-cuts
  // some of the checks for devices.
  test('flutter run handles invalid device id', () => testbed.run(() async {
    final BufferLogger bufferLogger = logger;
    final RunCommand command = RunCommand();
    applyMocksToCommand(command);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await expectLater(commandRunner.run(<String>['run', '-d', 'invalid-device-id', '--no-pub']), throwsToolExit());
    expect(bufferLogger.statusText, contains('No devices found with name or id matching'));
  }));
}

class MockFlutterDoctor extends Mock implements Doctor {}
