import 'package:test/test.dart';

import 'package:flutter_tools/src/ios/simulators.dart';

void main() {
  group('compareIosVersions', () {
    test('compares correctly', () {
      // This list must be sorted in ascending preference order
      List<String> testList = <String>[
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
      List<String> testList = <String>[
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
    test('Apple TV is unsupported', () {
      expect(new IOSSimulator('x', name: 'Apple TV').isSupported(), false);
    });

    test('Apple Watch is unsupported', () {
      expect(new IOSSimulator('x', name: 'Apple Watch').isSupported(), false);
    });

    test('iPad 2 is unsupported', () {
      expect(new IOSSimulator('x', name: 'iPad 2').isSupported(), false);
    });

    test('iPad Retina is unsupported', () {
      expect(new IOSSimulator('x', name: 'iPad Retina').isSupported(), false);
    });

    test('iPhone 5 is unsupported', () {
      expect(new IOSSimulator('x', name: 'iPhone 5').isSupported(), false);
    });

    test('iPhone 5s is supported', () {
      expect(new IOSSimulator('x', name: 'iPhone 5s').isSupported(), true);
    });

    test('iPhone SE is supported', () {
      expect(new IOSSimulator('x', name: 'iPhone SE').isSupported(), true);
    });

    test('iPhone 7 Plus is supported', () {
      expect(new IOSSimulator('x', name: 'iPhone 7 Plus').isSupported(), true);
    });
  });
}
