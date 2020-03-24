// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  FakeProcessManager processManager;
  MockArtifacts artifacts;
  FakeCache fakeCache;
  BufferLogger logger;

  setUp(() {
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    fakeCache = FakeCache();
    artifacts = MockArtifacts();
    logger = BufferLogger.test();
    when(artifacts.getArtifactPath(Artifact.idevicesyslog, platform: TargetPlatform.ios))
      .thenReturn('idevice-syslog');
  });

  testWithoutContext('decodeSyslog decodes a syslog-encoded line', () {
    final String decoded = decodeSyslog(
      r'I \M-b\M^]\M-$\M-o\M-8\M^O syslog \M-B\M-/\'
      r'134_(\M-c\M^C\M^D)_/\M-B\M-/ \M-l\M^F\240!');

    expect(decoded, r'I ❤️ syslog ¯\_(ツ)_/¯ 솠!');
  });

  testWithoutContext('decodeSyslog passes through un-decodeable lines as-is', () {
    final String decoded = decodeSyslog(r'I \M-b\M^O syslog!');

    expect(decoded, r'I \M-b\M^O syslog!');
  });

  testWithoutContext('IOSDeviceLogReader suppresses non-Flutter lines from output with syslog', () async {
    processManager.addCommand(
      const FakeCommand(
        command: <String>[
          'idevice-syslog', '-u', '1234',
        ],
        stdout: '''
Runner(Flutter)[297] <Notice>: A is for ari
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
Runner(Flutter)[297] <Notice>: I is for ichigo
Runner(UIKit)[297] <Notice>: E is for enpitsu"
'''
      ),
    );
    final DeviceLogReader logReader = IOSDeviceLogReader.test(
      iMobileDevice: IMobileDevice(
        artifacts: artifacts,
        processManager: processManager,
        cache: fakeCache,
        logger: logger,
      ),
    );
    final List<String> lines = await logReader.logLines.toList();

    expect(lines, <String>['A is for ari', 'I is for ichigo']);
  });

  testWithoutContext('IOSDeviceLogReader includes multi-line Flutter logs in the output with syslog', () async {
    processManager.addCommand(
      const FakeCommand(
        command: <String>[
          'idevice-syslog', '-u', '1234',
        ],
        stdout: '''
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
'''
      ),
    );
    final DeviceLogReader logReader = IOSDeviceLogReader.test(
      iMobileDevice: IMobileDevice(
        artifacts: artifacts,
        processManager: processManager,
        cache: fakeCache,
        logger: logger,
      ),
    );
    final List<String> lines = await logReader.logLines.toList();

    expect(lines, <String>[
      'This is a multi-line message,',
      '  with another Flutter message following it.',
      'This is a multi-line message,',
      '  with a non-Flutter log message following it.',
    ]);
  });

  testWithoutContext('includes multi-line Flutter logs in the output', () async {
    processManager.addCommand(
      const FakeCommand(
        command: <String>[
          'idevice-syslog', '-u', '1234',
        ],
        stdout: '''
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
''',
      ),
    );

    final DeviceLogReader logReader = IOSDeviceLogReader.test(
      iMobileDevice: IMobileDevice(
        artifacts: artifacts,
        processManager: processManager,
        cache: fakeCache,
        logger: logger,
      ),
    );
    final List<String> lines = await logReader.logLines.toList();

    expect(lines, <String>[
      'This is a multi-line message,',
      '  with another Flutter message following it.',
      'This is a multi-line message,',
      '  with a non-Flutter log message following it.',
    ]);
  });
}

class MockArtifacts extends Mock implements Artifacts {}
