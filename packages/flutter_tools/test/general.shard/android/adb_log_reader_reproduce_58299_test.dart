// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

const kLastLogcatTimestamp = '11-27 15:39:04.506';
const kDummyLine = 'Contents are not important\n';

void main() {
  testWithoutContext('AdbLogReader completes stream on AndroidRuntime crash of the app', () async {
    final FakeApplicationPackage app = FakeApplicationPackage('com.example.foobar');
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>['adb', '-s', '1234', 'shell', '-x', 'logcat', '-v', 'time'],
        completer: Completer<void>.sync(),
        stdout:
            '$kDummyLine'
            // 1. Crash of a different application package (should not close the stream)
            '05-11 12:54:46.665 E/AndroidRuntime(11787): FATAL EXCEPTION: main\n'
            '05-11 12:54:46.665 E/AndroidRuntime(11787): Process: com.example.other, PID: 11787\n'
            '05-11 12:54:46.665 java.lang.RuntimeException: Unable to instantiate application '
            'io.flutter.app.FlutterApplicationOther: java.lang.ClassNotFoundException:\n'
            // 2. Crash of our application package (should trigger the stream to close)
            '05-11 12:54:47.665 E/AndroidRuntime(11788): FATAL EXCEPTION: main\n'
            '05-11 12:54:47.665 E/AndroidRuntime(11788): Process: com.example.foobar, PID: 11788\n'
            '05-11 12:54:47.665 java.lang.RuntimeException: Unable to instantiate application '
            'io.flutter.app.FlutterApplication2: java.lang.ClassNotFoundException:\n',
      ),
    ]);

    final AdbLogReader logReader = await AdbLogReader.createLogReader(
      createFakeDevice(null),
      processManager,
      BufferLogger.test(),
      app: app,
    );
    addTearDown(logReader.dispose);

    final List<String> lines = <String>[];
    final Completer<void> streamCompleted = Completer<void>();
    
    logReader.logLines.listen(
      lines.add,
      onDone: streamCompleted.complete,
    );

    // Wait for the stream to complete with a short timeout.
    // If it does not complete (the bug), it will throw a StateError, which makes the test fail.
    await streamCompleted.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw StateError('Stream did not complete (hung waiting for VM Service/log Lines).');
      },
    );

    // Assert that we did not filter out logs from the other app crash.
    expect(lines, contains('E/AndroidRuntime(11787): Process: com.example.other, PID: 11787'));
    expect(lines, contains('java.lang.RuntimeException: Unable to instantiate application io.flutter.app.FlutterApplicationOther: java.lang.ClassNotFoundException:'));

    // Assert that we did not filter out our app crash logs.
    expect(lines, contains('E/AndroidRuntime(11788): Process: com.example.foobar, PID: 11788'));
    expect(lines, contains('java.lang.RuntimeException: Unable to instantiate application io.flutter.app.FlutterApplication2: java.lang.ClassNotFoundException:'));

    expect(processManager, hasNoRemainingExpectations);
  });
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {
  FakeApplicationPackage(this.id);

  @override
  final String id;

  @override
  String get name => 'FakeApp';
}

AndroidDevice createFakeDevice(int? sdkLevel) {
  return FakeAndroidDevice(sdkLevel.toString(), kLastLogcatTimestamp);
}

class FakeAndroidDevice extends Fake implements AndroidDevice {
  FakeAndroidDevice(this._apiVersion, this._lastLogcatTimestamp);

  final String _lastLogcatTimestamp;
  final String _apiVersion;

  @override
  String get name => 'test-device';

  @override
  String get displayName => name;

  @override
  Future<String> get apiVersion => Future<String>.value(_apiVersion);

  @override
  Future<String> lastLogcatTimestamp() async => _lastLogcatTimestamp;

  @override
  List<String> adbCommandForDevice(List<String> command) {
    return <String>['adb', '-s', '1234', ...command];
  }
}
