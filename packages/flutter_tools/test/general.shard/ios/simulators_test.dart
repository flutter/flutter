// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult, Process;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/protocol_discovery.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockFile extends Mock implements File {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockLogger extends Mock implements Logger {}
class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockSimControl extends Mock implements SimControl {}
class MockPlistUtils extends Mock implements PlistParser {}

final Platform macosPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'HOME': '/'
  },
);

void main() {
  FakePlatform osx;
  FileSystemUtils fsUtils;
  MemoryFileSystem fileSystem;

  setUp(() {
    osx = FakePlatform(
      environment: <String, String>{},
      operatingSystem: 'macos',
    );
    fileSystem = MemoryFileSystem.test();
    fsUtils = FileSystemUtils(fileSystem: fileSystem, platform: osx);
  });

  group('_IOSSimulatorDevicePortForwarder', () {
    MockSimControl mockSimControl;
    MockXcode mockXcode;

    setUp(() {
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
    });

    testUsingContext('dispose() does not throw an exception', () async {
      final IOSSimulator simulator = IOSSimulator(
        '123',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      final DevicePortForwarder portForwarder = simulator.portForwarder;
      await portForwarder.forward(123);
      await portForwarder.forward(124);
      expect(portForwarder.forwardedPorts.length, 2);
      try {
        await portForwarder.dispose();
      } on Exception catch (e) {
        fail('Encountered exception: $e');
      }
      expect(portForwarder.forwardedPorts.length, 0);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    }, testOn: 'posix');
  });

  testUsingContext('simulators only support debug mode', () async {
    final IOSSimulator simulator = IOSSimulator(
      '123',
      simControl: MockSimControl(),
      xcode: MockXcode(),
    );

    expect(simulator.supportsRuntimeMode(BuildMode.debug), true);
    expect(simulator.supportsRuntimeMode(BuildMode.profile), false);
    expect(simulator.supportsRuntimeMode(BuildMode.release), false);
    expect(simulator.supportsRuntimeMode(BuildMode.jitRelease), false);
  }, overrides: <Type, Generator>{
    Platform: () => osx,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  group('logFilePath', () {
    MockSimControl mockSimControl;
    MockXcode mockXcode;

    setUp(() {
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
    });

    testUsingContext('defaults to rooted from HOME', () {
      osx.environment['HOME'] = '/foo/bar';
      final IOSSimulator simulator = IOSSimulator(
        '123',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      expect(simulator.logFilePath, '/foo/bar/Library/Logs/CoreSimulator/123/system.log');
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystemUtils: () => fsUtils,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    }, testOn: 'posix');

    testUsingContext('respects IOS_SIMULATOR_LOG_FILE_PATH', () {
      osx.environment['HOME'] = '/foo/bar';
      osx.environment['IOS_SIMULATOR_LOG_FILE_PATH'] = '/baz/qux/%{id}/system.log';
      final IOSSimulator simulator = IOSSimulator(
        '456',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      expect(simulator.logFilePath, '/baz/qux/456/system.log');
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystemUtils: () => fsUtils,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });
  });

  group('compareIosVersions', () {
    testWithoutContext('compares correctly', () {
      // This list must be sorted in ascending preference order
      final List<String> testList = <String>[
        '8', '8.0', '8.1', '8.2',
        '9', '9.0', '9.1', '9.2',
        '10', '10.0', '10.1',
      ];

      for (int i = 0; i < testList.length; i++) {
        expect(compareIosVersions(testList[i], testList[i]), 0);
      }

      for (int i = 0; i < testList.length - 1; i++) {
        for (int j = i + 1; j < testList.length; j++) {
          expect(compareIosVersions(testList[i], testList[j]), lessThan(0));
          expect(compareIosVersions(testList[j], testList[i]), greaterThan(0));
        }
      }
    });
  });

  group('compareIphoneVersions', () {
    testWithoutContext('compares correctly', () {
      // This list must be sorted in ascending preference order
      final List<String> testList = <String>[
        'com.apple.CoreSimulator.SimDeviceType.iPhone-4s',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-5',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-5s',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-6strange',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-6-Plus',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-6',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus',
        'com.apple.CoreSimulator.SimDeviceType.iPhone-6s',
      ];

      for (int i = 0; i < testList.length; i++) {
        expect(compareIphoneVersions(testList[i], testList[i]), 0);
      }

      for (int i = 0; i < testList.length - 1; i++) {
        for (int j = i + 1; j < testList.length; j++) {
          expect(compareIphoneVersions(testList[i], testList[j]), lessThan(0));
          expect(compareIphoneVersions(testList[j], testList[i]), greaterThan(0));
        }
      }
    });
  });

  group('sdkMajorVersion', () {
    MockSimControl mockSimControl;
    MockXcode mockXcode;

    setUp(() {
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
    });

    // This new version string appears in SimulatorApp-850 CoreSimulator-518.16 beta.
    testWithoutContext('can be parsed from iOS-11-3', () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'com.apple.CoreSimulator.SimRuntime.iOS-11-3',
        simControl: mockSimControl,
        xcode: mockXcode,
      );

      expect(await device.sdkMajorVersion, 11);
    });

    testWithoutContext('can be parsed from iOS 11.2', () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'iOS 11.2',
        simControl: mockSimControl,
        xcode: mockXcode,
      );

      expect(await device.sdkMajorVersion, 11);
    });

    testWithoutContext('Has a simulator category', () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'iOS 11.2',
        simControl: mockSimControl,
        xcode: mockXcode,
      );

      expect(device.category, Category.mobile);
    });
  });

  group('IOSSimulator.isSupported', () {
    MockSimControl mockSimControl;
    MockXcode mockXcode;

    setUp(() {
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
    });

    testUsingContext('Apple TV is unsupported', () {
      final IOSSimulator simulator = IOSSimulator(
        'x',
        name: 'Apple TV',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      expect(simulator.isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('Apple Watch is unsupported', () {
      expect(IOSSimulator(
        'x',
        name: 'Apple Watch',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPad 2 is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPad 2',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPad Retina is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPad Retina',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPhone 5 is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPhone 5',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPhone 5s is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPhone 5s',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPhone SE is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPhone SE',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPhone 7 Plus is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPhone 7 Plus',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('iPhone X is supported', () {
      expect(IOSSimulator(
        'x',
        name: 'iPhone X',
        simControl: mockSimControl,
        xcode: mockXcode,
      ).isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });
  });

  group('Simulator screenshot', () {
    MockXcode mockXcode;
    MockLogger mockLogger;
    MockProcessManager mockProcessManager;
    IOSSimulator deviceUnderTest;
    // only used for fs.path.join()
    final FileSystem fs = globals.fs;

    setUp(() {
      mockXcode = MockXcode();
      mockLogger = MockLogger();
      mockProcessManager = MockProcessManager();
      // Let everything else return exit code 0 so process.dart doesn't crash.
      when(
        mockProcessManager.run(any, environment: null, workingDirectory: null)
      ).thenAnswer((Invocation invocation) =>
        Future<ProcessResult>.value(ProcessResult(2, 0, '', ''))
      );
      // Test a real one. Screenshot doesn't require instance states.
      final SimControl simControl = SimControl(
        processManager: mockProcessManager,
        logger: mockLogger,
        xcode: mockXcode,
      );
      // Doesn't matter what the device is.
      deviceUnderTest = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simControl: simControl,
        xcode: mockXcode,
      );
      when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
    });

    testWithoutContext(
      "old Xcode doesn't support screenshot",
      () {
        when(mockXcode.majorVersion).thenReturn(7);
        when(mockXcode.minorVersion).thenReturn(1);
        expect(deviceUnderTest.supportsScreenshot, false);
      },
    );

    testWithoutContext(
      'Xcode 8.2+ supports screenshots',
      () async {
        when(mockXcode.majorVersion).thenReturn(8);
        when(mockXcode.minorVersion).thenReturn(2);
        expect(deviceUnderTest.supportsScreenshot, true);
        final MockFile mockFile = MockFile();
        when(mockFile.path).thenReturn(fs.path.join('some', 'path', 'to', 'screenshot.png'));
        await deviceUnderTest.takeScreenshot(mockFile);
        verify(mockProcessManager.run(
          <String>[
            'xcrun',
            'simctl',
            'io',
            'x',
            'screenshot',
            fs.path.join('some', 'path', 'to', 'screenshot.png'),
          ],
          environment: null,
          workingDirectory: null,
        ));
      },
    );
  });

  group('device log tool', () {
    MockProcessManager mockProcessManager;
    MockXcode mockXcode;
    MockSimControl mockSimControl;

    setUp(() {
      mockProcessManager = MockProcessManager();
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
        .thenAnswer((Invocation invocation) => Future<Process>.value(MockProcess()));
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
      when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
    });

    testUsingContext('syslog uses tail', () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'iOS 9.3',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      await launchDeviceSystemLogTool(device);
      expect(
        verify(mockProcessManager.start(captureAny, environment: null, workingDirectory: null)).captured.single,
        contains('tail'),
      );
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      FileSystem: () => fileSystem,
      Platform: () => macosPlatform,
      FileSystemUtils: () => FileSystemUtils(
        fileSystem: fileSystem,
        platform: macosPlatform,
      ),
      Xcode: () => mockXcode,
    });

    testUsingContext('unified logging with app name', () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'iOS 11.0',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      await launchDeviceUnifiedLogging(device, 'My Super Awesome App');

      const String expectedPredicate = 'eventType = logEvent AND '
        'processImagePath ENDSWITH "My Super Awesome App" AND '
        '(senderImagePath ENDSWITH "/Flutter" OR senderImagePath ENDSWITH "/libswiftCore.dylib" OR processImageUUID == senderImageUUID) AND '
        'NOT(eventMessage CONTAINS ": could not find icon for representation -> com.apple.") AND '
        'NOT(eventMessage BEGINSWITH "assertion failed: ") AND '
        'NOT(eventMessage CONTAINS " libxpc.dylib ")';

      final List<String> command = verify(mockProcessManager.start(captureAny, environment: null, workingDirectory: null)).captured.single as List<String>;
      expect(command, <String>[
        'xcrun',
        'simctl',
        'spawn',
        'x',
        'log',
        'stream',
        '--style',
        'json',
        '--predicate',
        expectedPredicate
      ]);
    },
      overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      FileSystem: () => fileSystem,
      Xcode: () => mockXcode,
    });

    testUsingContext('unified logging without app name', () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'iOS 11.0',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      await launchDeviceUnifiedLogging(device, null);

      const String expectedPredicate = 'eventType = logEvent AND '
        '(senderImagePath ENDSWITH "/Flutter" OR senderImagePath ENDSWITH "/libswiftCore.dylib" OR processImageUUID == senderImageUUID) AND '
        'NOT(eventMessage CONTAINS ": could not find icon for representation -> com.apple.") AND '
        'NOT(eventMessage BEGINSWITH "assertion failed: ") AND '
        'NOT(eventMessage CONTAINS " libxpc.dylib ")';

      final List<String> command = verify(mockProcessManager.start(captureAny, environment: null, workingDirectory: null)).captured.single as List<String>;
      expect(command, <String>[
        'xcrun',
        'simctl',
        'spawn',
        'x',
        'log',
        'stream',
        '--style',
        'json',
        '--predicate',
        expectedPredicate
      ]);
    },
      overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        FileSystem: () => fileSystem,
        Xcode: () => mockXcode,
      });
  });

  group('log reader', () {
    FakeProcessManager fakeProcessManager;
    MockIosProject mockIosProject;
    MockSimControl mockSimControl;
    MockXcode mockXcode;

    setUp(() {
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
      mockIosProject = MockIosProject();
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
      when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
    });

    group('syslog', () {
      setUp(() {
        final File syslog = fileSystem.file('system.log')..createSync();
        osx.environment['IOS_SIMULATOR_LOG_FILE_PATH'] = syslog.path;
      });

      testUsingContext('simulator can parse Xcode 8/iOS 10-style logs', () async {
        fakeProcessManager
          ..addCommand(const FakeCommand(
            command:  <String>['tail', '-n', '0', '-F', 'system.log'],
            stdout: '''
Dec 20 17:04:32 md32-11-vm1 My Super Awesome App[88374]: flutter: Observatory listening on http://127.0.0.1:64213/1Uoeu523990=/
Dec 20 17:04:32 md32-11-vm1 Another App[88374]: Ignore this text'''
          ))
          ..addCommand(const FakeCommand(
            command:  <String>['tail', '-n', '0', '-F', '/private/var/log/system.log']
          ));

        final IOSSimulator device = IOSSimulator(
          '123456',
          simulatorCategory: 'iOS 10.0',
          simControl: mockSimControl,
          xcode: mockXcode,
        );
        final DeviceLogReader logReader = device.getLogReader(
          app: await BuildableIOSApp.fromProject(mockIosProject, null),
        );

        final List<String> lines = await logReader.logLines.toList();
        expect(lines, <String>[
          'flutter: Observatory listening on http://127.0.0.1:64213/1Uoeu523990=/',
        ]);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        ProcessManager: () => fakeProcessManager,
        FileSystem: () => fileSystem,
        Platform: () => osx,
        Xcode: () => mockXcode,
      });

      testUsingContext('simulator can output `)`', () async {
        fakeProcessManager
          ..addCommand(const FakeCommand(
            command:  <String>['tail', '-n', '0', '-F', 'system.log'],
            stdout: '''
2017-09-13 15:26:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) Observatory listening on http://127.0.0.1:57701/
2017-09-13 15:26:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) ))))))))))
2017-09-13 15:26:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) #0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)'''
          ))
          ..addCommand(const FakeCommand(
            command:  <String>['tail', '-n', '0', '-F', '/private/var/log/system.log']
          ));

        final IOSSimulator device = IOSSimulator(
          '123456',
          simulatorCategory: 'iOS 10.3',
          simControl: mockSimControl,
          xcode: mockXcode,
        );
        final DeviceLogReader logReader = device.getLogReader(
          app: await BuildableIOSApp.fromProject(mockIosProject, null),
        );

        final List<String> lines = await logReader.logLines.toList();
        expect(lines, <String>[
          'Observatory listening on http://127.0.0.1:57701/',
          '))))))))))',
          '#0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)',
        ]);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        ProcessManager: () => fakeProcessManager,
        FileSystem: () => fileSystem,
        Platform: () => osx,
        Xcode: () => mockXcode,
      });

      testUsingContext('multiline messages', () async {
        fakeProcessManager
          ..addCommand(const FakeCommand(
            command:  <String>['tail', '-n', '0', '-F', 'system.log'],
            stdout: '''
2017-09-13 15:26:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) Single line message
2017-09-13 15:26:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) Multi line message
  continues...
  continues...
2020-03-11 15:58:28.207175-0700  localhost My Super Awesome App[72166]: (libnetwork.dylib) [com.apple.network:] [28 www.googleapis.com:443 stream, pid: 72166, tls] cancelled
	[28.1 64A98447-EABF-4983-A387-7DB9D0C1785F 10.0.1.200.57912<->172.217.6.74:443]
	Connected Path: satisfied (Path is satisfied), interface: en18
	Duration: 0.271s, DNS @0.000s took 0.001s, TCP @0.002s took 0.019s, TLS took 0.046s
	bytes in/out: 4468/1933, packets in/out: 11/10, rtt: 0.016s, retransmitted packets: 0, out-of-order packets: 0
2017-09-13 15:36:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) Multi line message again
  and it goes...
  and goes...
2017-09-13 15:36:57.228948-0700  localhost My Super Awesome App[37195]: (Flutter) Single line message, not the part of the above
'''
          ))
          ..addCommand(const FakeCommand(
            command:  <String>['tail', '-n', '0', '-F', '/private/var/log/system.log']
          ));

        final IOSSimulator device = IOSSimulator(
          '123456',
          simulatorCategory: 'iOS 10.3',
          simControl: mockSimControl,
          xcode: mockXcode,
        );
        final DeviceLogReader logReader = device.getLogReader(
          app: await BuildableIOSApp.fromProject(mockIosProject, null),
        );

        final List<String> lines = await logReader.logLines.toList();
        expect(lines, <String>[
          'Single line message',
          'Multi line message',
          '  continues...',
          '  continues...',
          'Multi line message again',
          '  and it goes...',
          '  and goes...',
          'Single line message, not the part of the above'
        ]);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        ProcessManager: () => fakeProcessManager,
        FileSystem: () => fileSystem,
        Platform: () => osx,
        Xcode: () => mockXcode,
      });
    });

    group('unified logging', () {
      testUsingContext('log reader handles escaped multiline messages', () async {
        const String logPredicate = 'eventType = logEvent AND processImagePath ENDSWITH "My Super Awesome App" '
          'AND (senderImagePath ENDSWITH "/Flutter" OR senderImagePath ENDSWITH "/libswiftCore.dylib" '
          'OR processImageUUID == senderImageUUID) AND NOT(eventMessage CONTAINS ": could not find icon '
          'for representation -> com.apple.") AND NOT(eventMessage BEGINSWITH "assertion failed: ") '
          'AND NOT(eventMessage CONTAINS " libxpc.dylib ")';
        fakeProcessManager.addCommand(const FakeCommand(
            command:  <String>[
              'xcrun',
              'simctl',
              'spawn',
              '123456',
              'log',
              'stream',
              '--style',
              'json',
              '--predicate',
              logPredicate,
            ],
            stdout: '''
},{
  "traceID" : 37579774151491588,
  "eventMessage" : "Single line message",
  "eventType" : "logEvent"
},{
  "traceID" : 37579774151491588,
  "eventMessage" : "Multi line message\\n  continues...\\n  continues..."
},{
  "traceID" : 37579774151491588,
  "eventMessage" : "Single line message, not the part of the above",
  "eventType" : "logEvent"
},{
'''
          ));

        final IOSSimulator device = IOSSimulator(
          '123456',
          simulatorCategory: 'iOS 11.0',
          simControl: mockSimControl,
          xcode: mockXcode,
        );
        final DeviceLogReader logReader = device.getLogReader(
          app: await BuildableIOSApp.fromProject(mockIosProject, null),
        );

        final List<String> lines = await logReader.logLines.toList();
        expect(lines, <String>[
          'Single line message', 'Multi line message\n  continues...\n  continues...',
          'Single line message, not the part of the above'
        ]);
        expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        ProcessManager: () => fakeProcessManager,
        FileSystem: () => fileSystem,
        Xcode: () => mockXcode,
      });
    });
  });

  group('SimControl', () {
    const int mockPid = 123;
    const String validSimControlOutput = '''
{
  "devices" : {
    "watchOS 4.3" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple Watch - 38mm",
        "udid" : "TEST-WATCH-UDID"
      }
    ],
    "iOS 11.4" : [
      {
        "state" : "Booted",
        "availability" : "(available)",
        "name" : "iPhone 5s",
        "udid" : "TEST-PHONE-UDID"
      }
    ],
    "tvOS 11.4" : [
      {
        "state" : "Shutdown",
        "availability" : "(available)",
        "name" : "Apple TV",
        "udid" : "TEST-TV-UDID"
      }
    ]
  }
}
    ''';

    MockLogger mockLogger;
    MockProcessManager mockProcessManager;
    MockXcode mockXcode;
    SimControl simControl;
    const String deviceId = 'smart-phone';
    const String appId = 'flutterApp';

    setUp(() {
      mockLogger = MockLogger();
      mockProcessManager = MockProcessManager();
      when(mockProcessManager.run(any)).thenAnswer((Invocation _) async {
        return ProcessResult(mockPid, 0, validSimControlOutput, '');
      });

      mockXcode = MockXcode();
      when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
      simControl = SimControl(
        logger: mockLogger,
        processManager: mockProcessManager,
        xcode: mockXcode,
      );
    });

    testWithoutContext('getDevices succeeds', () async {
      final List<SimDevice> devices = await simControl.getDevices();

      final SimDevice watch = devices[0];
      expect(watch.category, 'watchOS 4.3');
      expect(watch.state, 'Shutdown');
      expect(watch.availability, '(available)');
      expect(watch.name, 'Apple Watch - 38mm');
      expect(watch.udid, 'TEST-WATCH-UDID');
      expect(watch.isBooted, isFalse);

      final SimDevice phone = devices[1];
      expect(phone.category, 'iOS 11.4');
      expect(phone.state, 'Booted');
      expect(phone.availability, '(available)');
      expect(phone.name, 'iPhone 5s');
      expect(phone.udid, 'TEST-PHONE-UDID');
      expect(phone.isBooted, isTrue);

      final SimDevice tv = devices[2];
      expect(tv.category, 'tvOS 11.4');
      expect(tv.state, 'Shutdown');
      expect(tv.availability, '(available)');
      expect(tv.name, 'Apple TV');
      expect(tv.udid, 'TEST-TV-UDID');
      expect(tv.isBooted, isFalse);
    });

    testWithoutContext('getDevices handles bad simctl output', () async {
      when(mockProcessManager.run(any))
          .thenAnswer((Invocation _) async => ProcessResult(mockPid, 0, 'Install Started', ''));
      final List<SimDevice> devices = await simControl.getDevices();

      expect(devices, isEmpty);
    });

    testWithoutContext('sdkMajorVersion defaults to 11 when sdkNameAndVersion is junk', () async {
      final IOSSimulator iosSimulatorA = IOSSimulator(
        'x',
        name: 'Testo',
        simulatorCategory: 'NaN',
        simControl: simControl,
        xcode: mockXcode,
      );

      expect(await iosSimulatorA.sdkMajorVersion, 11);
    });

    testWithoutContext('.install() handles exceptions', () async {
      when(mockProcessManager.run(
        <String>['xcrun', 'simctl', 'install', deviceId, appId],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenThrow(const ProcessException('xcrun', <String>[]));
      expect(
        () async => await simControl.install(deviceId, appId),
        throwsToolExit(message: r'Unable to install'),
      );
    });

    testWithoutContext('.uninstall() handles exceptions', () async {
      when(mockProcessManager.run(
        <String>['xcrun', 'simctl', 'uninstall', deviceId, appId],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenThrow(const ProcessException('xcrun', <String>[]));
      expect(
        () async => await simControl.uninstall(deviceId, appId),
        throwsToolExit(message: r'Unable to uninstall'),
      );
    });

    testWithoutContext('.launch() handles exceptions', () async {
      when(mockProcessManager.run(
        <String>['xcrun', 'simctl', 'launch', deviceId, appId],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenThrow(const ProcessException('xcrun', <String>[]));
      expect(
        () async => await simControl.launch(deviceId, appId),
        throwsToolExit(message: r'Unable to launch'),
      );
    });
  });

  group('startApp', () {
    SimControl simControl;
    MockXcode mockXcode;
    MockPrototcolDiscovery mockPrototcolDiscovery;

    setUp(() {
      simControl = MockSimControl();
      mockXcode = MockXcode();
      when(mockXcode.xcrunCommand()).thenReturn(<String>['xcrun']);
      mockPrototcolDiscovery = MockPrototcolDiscovery();
    });

    testUsingContext("startApp uses compiled app's Info.plist to find CFBundleIdentifier", () async {
      final IOSSimulator device = IOSSimulator(
        'x',
        name: 'iPhone SE',
        simulatorCategory: 'iOS 11.2',
        simControl: simControl,
        xcode: mockXcode,
      );
      when(globals.plistParser.getValueFromFile(any, any)).thenReturn('correct');
      when(mockPrototcolDiscovery.uri)
          .thenAnswer((_) async => Uri.parse('http://localhost:5678'));

      final Directory mockDir = globals.fs.currentDirectory;
      final IOSApp package = PrebuiltIOSApp(projectBundleId: 'incorrect', bundleName: 'name', bundleDir: mockDir);

      const BuildInfo mockInfo = BuildInfo(BuildMode.debug, 'flavor', treeShakeIcons: false);
      final DebuggingOptions mockOptions =
          DebuggingOptions.enabled(mockInfo, hostVmServicePort: 8888);
      await device.startApp(package, prebuiltApplication: true, debuggingOptions: mockOptions);

      verify(simControl.launch(any, 'correct', <String>[
        '--enable-dart-profiling',
        '--enable-checked-mode',
        '--verify-entry-points',
        '--observatory-port=8888',
      ]));
    }, overrides: <Type, Generator>{
      PlistParser: () => MockPlistUtils(),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });
  });

  group('IOSDevice.isSupportedForProject', () {
    MockSimControl mockSimControl;
    MockXcode mockXcode;

    setUp(() {
      mockSimControl = MockSimControl();
      mockXcode = MockXcode();
    });

    testUsingContext('is true on module project', () async {
      globals.fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
name: example

flutter:
  module: {}
''');
      globals.fs.file('.packages').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      final IOSSimulator simulator = IOSSimulator(
        'test',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      expect(simulator.isSupportedForProject(flutterProject), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });


    testUsingContext('is true with editable host app', () async {
      globals.fs.file('pubspec.yaml').createSync();
      globals.fs.file('.packages').createSync();
      globals.fs.directory('ios').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      final IOSSimulator simulator = IOSSimulator(
        'test',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      expect(simulator.isSupportedForProject(flutterProject), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });

    testUsingContext('is false with no host app and no module', () async {
      globals.fs.file('pubspec.yaml').createSync();
      globals.fs.file('.packages').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      final IOSSimulator simulator = IOSSimulator(
        'test',
        simControl: mockSimControl,
        xcode: mockXcode,
      );
      expect(simulator.isSupportedForProject(flutterProject), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
    });
  });
}

class MockPrototcolDiscovery extends Mock implements ProtocolDiscovery {}
class MockBuildSystem extends Mock implements BuildSystem {}
