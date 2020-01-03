// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult, Process;

import 'package:file/file.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

class MockFile extends Mock implements File {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}
class MockSimControl extends Mock implements SimControl {}
class MockPlistUtils extends Mock implements PlistParser {}

void main() {
  FakePlatform osx;

  setUp(() {
    osx = FakePlatform.fromPlatform(const LocalPlatform());
    osx.operatingSystem = 'macos';
  });

  group('logFilePath', () {
    testUsingContext('defaults to rooted from HOME', () {
      osx.environment['HOME'] = '/foo/bar';
      expect(IOSSimulator('123').logFilePath, '/foo/bar/Library/Logs/CoreSimulator/123/system.log');
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    }, testOn: 'posix');

    testUsingContext('respects IOS_SIMULATOR_LOG_FILE_PATH', () {
      osx.environment['HOME'] = '/foo/bar';
      osx.environment['IOS_SIMULATOR_LOG_FILE_PATH'] = '/baz/qux/%{id}/system.log';
      expect(IOSSimulator('456').logFilePath, '/baz/qux/456/system.log');
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });
  });

  group('compareIosVersions', () {
    test('compares correctly', () {
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
    test('compares correctly', () {
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
    // This new version string appears in SimulatorApp-850 CoreSimulator-518.16 beta.
    test('can be parsed from iOS-11-3', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'com.apple.CoreSimulator.SimRuntime.iOS-11-3');

      expect(await device.sdkMajorVersion, 11);
    });

    test('can be parsed from iOS 11.2', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 11.2');

      expect(await device.sdkMajorVersion, 11);
    });

    test('Has a simulator category', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 11.2');

      expect(device.category, Category.mobile);
    });
  });

  group('IOSSimulator.isSupported', () {
    testUsingContext('Apple TV is unsupported', () {
      expect(IOSSimulator('x', name: 'Apple TV').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('Apple Watch is unsupported', () {
      expect(IOSSimulator('x', name: 'Apple Watch').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPad 2 is supported', () {
      expect(IOSSimulator('x', name: 'iPad 2').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPad Retina is supported', () {
      expect(IOSSimulator('x', name: 'iPad Retina').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone 5 is supported', () {
      expect(IOSSimulator('x', name: 'iPhone 5').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone 5s is supported', () {
      expect(IOSSimulator('x', name: 'iPhone 5s').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone SE is supported', () {
      expect(IOSSimulator('x', name: 'iPhone SE').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone 7 Plus is supported', () {
      expect(IOSSimulator('x', name: 'iPhone 7 Plus').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone X is supported', () {
      expect(IOSSimulator('x', name: 'iPhone X').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });
  });

  testUsingContext('builds with targetPlatform', () async {
    final IOSSimulator simulator = IOSSimulator('x', name: 'iPhone X');
    when(buildSystem.build(any, any)).thenAnswer((Invocation invocation) async {
      return BuildResult(success: true);
    });
    await simulator.sideloadUpdatedAssetsForInstalledApplicationBundle(BuildInfo.debug, 'lib/main.dart');

    final VerificationResult result = verify(buildSystem.build(any, captureAny));
    final Environment environment = result.captured.single as Environment;
    expect(environment.defines, <String, String>{
      kTargetFile: 'lib/main.dart',
      kTargetPlatform: 'ios',
      kBuildMode: 'debug',
      kTrackWidgetCreation: 'false',
    });
  }, overrides: <Type, Generator>{
    BuildSystem: () => MockBuildSystem(),
  });

  group('Simulator screenshot', () {
    MockXcode mockXcode;
    MockProcessManager mockProcessManager;
    IOSSimulator deviceUnderTest;

    setUp(() {
      mockXcode = MockXcode();
      mockProcessManager = MockProcessManager();
      // Let everything else return exit code 0 so process.dart doesn't crash.
      when(
        mockProcessManager.run(any, environment: null, workingDirectory: null)
      ).thenAnswer((Invocation invocation) =>
        Future<ProcessResult>.value(ProcessResult(2, 0, '', ''))
      );
      // Doesn't matter what the device is.
      deviceUnderTest = IOSSimulator('x', name: 'iPhone SE');
    });

    testUsingContext(
      'old Xcode doesn\'t support screenshot',
      () {
        when(mockXcode.majorVersion).thenReturn(7);
        when(mockXcode.minorVersion).thenReturn(1);
        expect(deviceUnderTest.supportsScreenshot, false);
      },
      overrides: <Type, Generator>{Xcode: () => mockXcode},
    );

    testUsingContext(
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
            '/usr/bin/xcrun',
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
      overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        // Test a real one. Screenshot doesn't require instance states.
        SimControl: () => SimControl(),
        Xcode: () => mockXcode,
      },
    );
  });

  group('launchDeviceLogTool', () {
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
        .thenAnswer((Invocation invocation) => Future<Process>.value(MockProcess()));
    });

    testUsingContext('uses tail on iOS versions prior to iOS 11', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 9.3');
      await launchDeviceLogTool(device);
      expect(
        verify(mockProcessManager.start(captureAny, environment: null, workingDirectory: null)).captured.single,
        contains('tail'),
      );
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('uses /usr/bin/log on iOS 11 and above', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 11.0');
      await launchDeviceLogTool(device);
      expect(
        verify(mockProcessManager.start(captureAny, environment: null, workingDirectory: null)).captured.single,
        contains('/usr/bin/log'),
      );
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('launchSystemLogTool', () {
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
        .thenAnswer((Invocation invocation) => Future<Process>.value(MockProcess()));
    });

    testUsingContext('uses tail on iOS versions prior to iOS 11', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 9.3');
      await launchSystemLogTool(device);
      expect(
        verify(mockProcessManager.start(captureAny, environment: null, workingDirectory: null)).captured.single,
        contains('tail'),
      );
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('uses /usr/bin/log on iOS 11 and above', () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 11.0');
      await launchSystemLogTool(device);
      verifyNever(mockProcessManager.start(any, environment: null, workingDirectory: null));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('log reader', () {
    MockProcessManager mockProcessManager;
    MockIosProject mockIosProject;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockIosProject = MockIosProject();
    });

    testUsingContext('simulator can output `)`', () async {
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
        .thenAnswer((Invocation invocation) {
          final Process mockProcess = MockProcess();
          when(mockProcess.stdout)
            .thenAnswer((Invocation invocation) {
              return Stream<List<int>>.fromIterable(<List<int>>['''
2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) Observatory listening on http://127.0.0.1:57701/
2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) ))))))))))
2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) #0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)'''
                .codeUnits]);
            });
          when(mockProcess.stderr)
              .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
          // Delay return of exitCode until after stdout stream data, since it terminates the logger.
          when(mockProcess.exitCode)
              .thenAnswer((Invocation invocation) => Future<int>.delayed(Duration.zero, () => 0));
          return Future<Process>.value(mockProcess);
        });

      final IOSSimulator device = IOSSimulator('123456', simulatorCategory: 'iOS 11.0');
      final DeviceLogReader logReader = device.getLogReader(
        app: await BuildableIOSApp.fromProject(mockIosProject),
      );

      final List<String> lines = await logReader.logLines.toList();
      expect(lines, <String>[
        'Observatory listening on http://127.0.0.1:57701/',
        '))))))))))',
        '#0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)',
      ]);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
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

    MockProcessManager mockProcessManager;
    SimControl simControl;

    setUp(() {
      mockProcessManager = MockProcessManager();
      when(mockProcessManager.run(any)).thenAnswer((Invocation _) async {
        return ProcessResult(mockPid, 0, validSimControlOutput, '');
      });

      simControl = SimControl();
    });

    testUsingContext('getDevices succeeds', () async {
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
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      SimControl: () => simControl,
    });

    testUsingContext('getDevices handles bad simctl output', () async {
      when(mockProcessManager.run(any))
          .thenAnswer((Invocation _) async => ProcessResult(mockPid, 0, 'Install Started', ''));
      final List<SimDevice> devices = await simControl.getDevices();

      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      SimControl: () => simControl,
    });

    testUsingContext('sdkMajorVersion defaults to 11 when sdkNameAndVersion is junk', () async {
      final IOSSimulator iosSimulatorA = IOSSimulator('x', name: 'Testo', simulatorCategory: 'NaN');

      expect(await iosSimulatorA.sdkMajorVersion, 11);
    });
  });

  group('startApp', () {
    SimControl simControl;

    setUp(() {
      simControl = MockSimControl();
    });

    testUsingContext("startApp uses compiled app's Info.plist to find CFBundleIdentifier", () async {
      final IOSSimulator device = IOSSimulator('x', name: 'iPhone SE', simulatorCategory: 'iOS 11.2');
      when(PlistParser.instance.getValueFromFile(any, any)).thenReturn('correct');

      final Directory mockDir = fs.currentDirectory;
      final IOSApp package = PrebuiltIOSApp(projectBundleId: 'incorrect', bundleName: 'name', bundleDir: mockDir);

      const BuildInfo mockInfo = BuildInfo(BuildMode.debug, 'flavor');
      final DebuggingOptions mockOptions = DebuggingOptions.disabled(mockInfo);
      await device.startApp(package, prebuiltApplication: true, debuggingOptions: mockOptions);

      verify(simControl.launch(any, 'correct', any));
    }, overrides: <Type, Generator>{
      SimControl: () => simControl,
      PlistParser: () => MockPlistUtils(),
    });
  });

  testUsingContext('IOSDevice.isSupportedForProject is true on module project', () async {
    fs.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example

flutter:
  module: {}
''');
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSSimulator('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('IOSDevice.isSupportedForProject is true with editable host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.directory('ios').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSSimulator('test').isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('IOSDevice.isSupportedForProject is false with no host app and no module', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(IOSSimulator('test').isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
