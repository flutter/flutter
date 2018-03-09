import 'dart:async';
import 'dart:io' show ProcessResult, Process;

import 'package:file/file.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockFile extends Mock implements File {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcode extends Mock implements Xcode {}

void main() {
  FakePlatform osx;

  setUp(() {
    osx = new FakePlatform.fromPlatform(const LocalPlatform());
    osx.operatingSystem = 'macos';
  });

  group('logFilePath', () {
    testUsingContext('defaults to rooted from HOME', () {
      osx.environment['HOME'] = '/foo/bar';
      expect(new IOSSimulator('123').logFilePath, '/foo/bar/Library/Logs/CoreSimulator/123/system.log');
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    }, testOn: 'posix');

    testUsingContext('respects IOS_SIMULATOR_LOG_FILE_PATH', () {
      osx.environment['HOME'] = '/foo/bar';
      osx.environment['IOS_SIMULATOR_LOG_FILE_PATH'] = '/baz/qux/%{id}/system.log';
      expect(new IOSSimulator('456').logFilePath, '/baz/qux/456/system.log');
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

  group('IOSSimulator.isSupported', () {
    testUsingContext('Apple TV is unsupported', () {
      expect(new IOSSimulator('x', name: 'Apple TV').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('Apple Watch is unsupported', () {
      expect(new IOSSimulator('x', name: 'Apple Watch').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPad 2 is unsupported', () {
      expect(new IOSSimulator('x', name: 'iPad 2').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPad Retina is unsupported', () {
      expect(new IOSSimulator('x', name: 'iPad Retina').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone 5 is unsupported', () {
      expect(new IOSSimulator('x', name: 'iPhone 5').isSupported(), false);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone 5s is supported', () {
      expect(new IOSSimulator('x', name: 'iPhone 5s').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone SE is supported', () {
      expect(new IOSSimulator('x', name: 'iPhone SE').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });

    testUsingContext('iPhone 7 Plus is supported', () {
      expect(new IOSSimulator('x', name: 'iPhone 7 Plus').isSupported(), true);
    }, overrides: <Type, Generator>{
      Platform: () => osx,
    });
  });

  group('Simulator screenshot', () {
    MockXcode mockXcode;
    MockProcessManager mockProcessManager;
    IOSSimulator deviceUnderTest;

    setUp(() {
      mockXcode = new MockXcode();
      mockProcessManager = new MockProcessManager();
      // Let everything else return exit code 0 so process.dart doesn't crash.
      when(
        mockProcessManager.run(any, environment: null, workingDirectory: null)
      ).thenAnswer((Invocation invocation) =>
        new Future<ProcessResult>.value(new ProcessResult(2, 0, '', ''))
      );
      // Doesn't matter what the device is.
      deviceUnderTest = new IOSSimulator('x', name: 'iPhone SE');
    });

    testUsingContext(
      'old Xcode doesn\'t support screenshot',
      () {
        when(mockXcode.majorVersion).thenReturn(7);
        when(mockXcode.minorVersion).thenReturn(1);
        expect(deviceUnderTest.supportsScreenshot, false);
      },
      overrides: <Type, Generator>{Xcode: () => mockXcode}
    );

    testUsingContext(
      'Xcode 8.2+ supports screenshots',
      () async {
        when(mockXcode.majorVersion).thenReturn(8);
        when(mockXcode.minorVersion).thenReturn(2);
        expect(deviceUnderTest.supportsScreenshot, true);
        final MockFile mockFile = new MockFile();
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
          workingDirectory: null
        ));
      },
      overrides: <Type, Generator>{
        ProcessManager: () => mockProcessManager,
        // Test a real one. Screenshot doesn't require instance states.
        SimControl: () => new SimControl(),
        Xcode: () => mockXcode,
      }
    );
  });

  group('launchDeviceLogTool', () {
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
        .thenAnswer((Invocation invocation) => new Future<Process>.value(new MockProcess()));
    });

    testUsingContext('uses tail on iOS versions prior to iOS 11', () async {
      final IOSSimulator device = new IOSSimulator('x', name: 'iPhone SE', category: 'iOS 9.3');
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
      final IOSSimulator device = new IOSSimulator('x', name: 'iPhone SE', category: 'iOS 11.0');
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
      mockProcessManager = new MockProcessManager();
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
        .thenAnswer((Invocation invocation) => new Future<Process>.value(new MockProcess()));
    });

    testUsingContext('uses tail on iOS versions prior to iOS 11', () async {
      final IOSSimulator device = new IOSSimulator('x', name: 'iPhone SE', category: 'iOS 9.3');
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
      final IOSSimulator device = new IOSSimulator('x', name: 'iPhone SE', category: 'iOS 11.0');
      await launchSystemLogTool(device);
      verifyNever(mockProcessManager.start(any, environment: null, workingDirectory: null));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('log reader', () {
    MockProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = new MockProcessManager();
    });

    testUsingContext('simulator can output `)`', () async {
      when(mockProcessManager.start(any, environment: null, workingDirectory: null))
          .thenAnswer((Invocation invocation) {
        final Process mockProcess = new MockProcess();
        when(mockProcess.stdout).thenAnswer((Invocation invocation) =>
            new Stream<List<int>>.fromIterable(<List<int>>['''
2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) Observatory listening on http://127.0.0.1:57701/
2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) ))))))))))
2017-09-13 15:26:57.228948-0700  localhost Runner[37195]: (Flutter) #0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)'''
                .codeUnits]));
        when(mockProcess.stderr)
            .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty());
        // Delay return of exitCode until after stdout stream data, since it terminates the logger.
        when(mockProcess.exitCode)
            .thenAnswer((Invocation invocation) => new Future<int>.delayed(Duration.zero, () => 0));
        return new Future<Process>.value(mockProcess);
      })
          .thenThrow(new TestFailure('Should start one process only'));

      final IOSSimulator device = new IOSSimulator('123456', category: 'iOS 11.0');
      final DeviceLogReader logReader = device.getLogReader(
        app: new BuildableIOSApp(projectBundleId: 'bundleId'),
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
}
