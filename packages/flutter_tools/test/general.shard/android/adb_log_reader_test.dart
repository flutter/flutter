// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const int kLollipopVersionCode = 21;
const String kLastLogcatTimestamp = '11-27 15:39:04.506';

/// By default the android log reader accepts lines that match no patterns
/// if the previous line was a match. Include an intentionally non-matching
/// line as the first input to disable this behavior.
const String kDummyLine = 'Contents are not important\n';

void main() {
  testWithoutContext('AdbLogReader calls adb logcat with expected flags apiVersion 21', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          '-x',
          'logcat',
          '-v',
          'time',
          '-T',
          '\'$kLastLogcatTimestamp\'',
        ],
      )
    ]);
    await AdbLogReader.createLogReader(
      createMockDevice(kLollipopVersionCode),
      processManager,
    );

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('AdbLogReader calls adb logcat with expected flags apiVersion < 21', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          '-x',
          'logcat',
          '-v',
          'time',
        ],
      )
    ]);
    await AdbLogReader.createLogReader(
      createMockDevice(kLollipopVersionCode - 1),
      processManager,
    );

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('AdbLogReader calls adb logcat with expected flags null apiVersion', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          '-x',
          'logcat',
          '-v',
          'time',
        ],
      )
    ]);
    await AdbLogReader.createLogReader(
      createMockDevice(null),
      processManager,
    );

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('AdbLogReader calls adb logcat with expected flags when requesting past logs', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          '-x',
          'logcat',
          '-v',
          'time',
          '-s',
          'flutter',
        ],
      )
    ]);
    await AdbLogReader.createLogReader(
      createMockDevice(null),
      processManager,
      includePastLogs: true,
    );

    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('AdbLogReader handles process early exit', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          '-x',
          'logcat',
          '-v',
          'time',
        ],
        completer: Completer<void>.sync(),
        stdout: 'Hello There\n',
      )
    ]);
    final AdbLogReader logReader = await AdbLogReader.createLogReader(
      createMockDevice(null),
      processManager,
    );
    final Completer<void> onDone = Completer<void>.sync();
    logReader.logLines.listen((String _) { }, onDone: onDone.complete);

    logReader.dispose();
    await onDone.future;
  });

  testWithoutContext('AdbLogReader does not filter output from AndroidRuntime crashes', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'adb',
          '-s',
          '1234',
          'shell',
          '-x',
          'logcat',
          '-v',
          'time',
        ],
        completer: Completer<void>.sync(),
        // Example stack trace from an incorrectly named application:name in the AndroidManfiest.xml
        stdout:
          kDummyLine +
          '05-11 12:54:46.665 E/AndroidRuntime(11787): FATAL EXCEPTION: main\n'
          '05-11 12:54:46.665 E/AndroidRuntime(11787): Process: com.example.foobar, PID: 11787\n'
          '05-11 12:54:46.665 java.lang.RuntimeException: Unable to instantiate application '
          'io.flutter.app.FlutterApplication2: java.lang.ClassNotFoundException:\n',
      )
    ]);
    final AdbLogReader logReader = await AdbLogReader.createLogReader(
      createMockDevice(null),
      processManager,
    );
    await expectLater(logReader.logLines, emitsInOrder(<String>[
      'E/AndroidRuntime(11787): FATAL EXCEPTION: main',
      'E/AndroidRuntime(11787): Process: com.example.foobar, PID: 11787',
      'java.lang.RuntimeException: Unable to instantiate application io.flutter.app.FlutterApplication2: java.lang.ClassNotFoundException:',
    ]));

    logReader.dispose();
  });
}

MockAndroidDevice createMockDevice(int sdkLevel) {
  final MockAndroidDevice mockAndroidDevice = MockAndroidDevice();
  when(mockAndroidDevice.apiVersion)
    .thenAnswer((Invocation invocation) async => sdkLevel.toString());
  when(mockAndroidDevice.lastLogcatTimestamp).thenReturn(kLastLogcatTimestamp);
  when(mockAndroidDevice.adbCommandForDevice(any))
    .thenAnswer((Invocation invocation) => <String>[
      'adb', '-s', '1234', ...invocation.positionalArguments.first as List<String>
    ]);
  return mockAndroidDevice;
}

class MockAndroidDevice extends Mock implements AndroidDevice {}
