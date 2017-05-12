import 'dart:async';
import 'dart:io' show ProcessResult;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockXcode extends Mock implements Xcode {}
class MockFile extends Mock implements File {}
class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  final FakePlatform osx = new FakePlatform.fromPlatform(const LocalPlatform());
  osx.operatingSystem = 'macos';

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
        mockProcessManager.run(any, environment: null, workingDirectory:  null)
      ).thenReturn(
        new Future<ProcessResult>.value(new ProcessResult(2, 0, '', ''))
      );
      // Doesn't matter what the device is.
      deviceUnderTest = new IOSSimulator('x', name: 'iPhone SE');
    });

    testUsingContext(
      'old Xcode doesn\'t support screenshot',
      () {
        when(mockXcode.xcodeMajorVersion).thenReturn(7);
        when(mockXcode.xcodeMinorVersion).thenReturn(1);
        expect(deviceUnderTest.supportsScreenshot, false);
      },
      overrides: <Type, Generator>{Xcode: () => mockXcode}
    );

    testUsingContext(
      'Xcode 8.2+ supports screenshots',
      () async {
        when(mockXcode.xcodeMajorVersion).thenReturn(8);
        when(mockXcode.xcodeMinorVersion).thenReturn(2);
        expect(deviceUnderTest.supportsScreenshot, true);
        final MockFile mockFile = new MockFile();
        when(mockFile.path).thenReturn(fs.path.join('some', 'path', 'to', 'screenshot.png'));
        await deviceUnderTest.takeScreenshot(mockFile);
        verify(mockProcessManager.run(
          <String>[
              '/usr/bin/xcrun',
              'simctl',
              'io',
              'booted',
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
}
