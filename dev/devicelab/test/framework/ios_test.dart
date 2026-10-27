// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_devicelab/framework/ios.dart';

import '../common.dart';

const String _iPhone11 = 'com.apple.CoreSimulator.SimDeviceType.iPhone-11';
const String _iPadM4 = 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-8GB';
const String _iPhoneDuo = 'com.apple.CoreSimulator.SimDeviceType.iPhone-Duo';

/// Mimics one entry of `simctl list runtimes --json`.
Map<String, Object?> _runtime({
  required String identifier,
  required String build,
  required String version,
  required List<String> deviceTypes,
  String platform = 'iOS',
  bool isAvailable = true,
}) {
  return <String, Object?>{
    'buildversion': build,
    'bundlePath': '/Library/Developer/CoreSimulator/Volumes/$platform-$version/$build.simruntime',
    'identifier': identifier,
    'isAvailable': isAvailable,
    'isInternal': false,
    'name': '$platform $version',
    'platform': platform,
    'runtimeRoot': '/Library/Developer/CoreSimulator/Volumes/$platform-$version/RuntimeRoot',
    'supportedArchitectures': <String>['arm64'],
    'supportedDeviceTypes': <Object?>[
      for (final String deviceType in deviceTypes)
        <String, Object?>{
          'bundlePath': '/Library/Developer/CoreSimulator/Profiles/DeviceTypes/$deviceType',
          'identifier': deviceType,
          'name': deviceType.split('.').last,
          'productFamily': deviceType.contains('iPad') ? 'iPad' : 'iPhone',
        },
    ],
    'version': version,
  };
}

String _listRuntimesJson(List<Map<String, Object?>> runtimes) {
  return json.encode(<String, Object?>{'runtimes': runtimes});
}

/// Mimics `simctl runtime match list --json`, including non-iOS platforms.
String _matchListJson({String? iosKey, Map<String, Object?> ios = const <String, Object?>{}}) {
  return json.encode(<String, Object?>{
    'appletvos27.0': <String, Object?>{
      'chosenRuntimeBuild': '24J360',
      'defaultBuild': '24J360',
      'platform': 'com.apple.platform.appletvos',
      'sdkBuild': '24J360',
      'sdkVersion': '27.0',
    },
    if (iosKey != null)
      iosKey: <String, Object?>{'platform': 'com.apple.platform.iphoneos', ...ios},
    'watchos27.0': <String, Object?>{
      'chosenRuntimeBuild': '24R360',
      'defaultBuild': '24R360',
      'platform': 'com.apple.platform.watchos',
      'sdkBuild': '24R360',
      'sdkVersion': '27.0',
    },
  });
}

void main() {
  group('selectIOSSimulatorRuntime', () {
    final Map<String, Object?> ios18 = _runtime(
      identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-18-4',
      build: '22E238',
      version: '18.4',
      deviceTypes: <String>[_iPhone11, _iPadM4],
    );
    final Map<String, Object?> ios26 = _runtime(
      identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-26-0',
      build: '23A343',
      version: '26.0',
      deviceTypes: <String>[_iPhone11, _iPadM4],
    );
    final Map<String, Object?> ios27 = _runtime(
      identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-27-0',
      build: '24A434',
      version: '27.0',
      deviceTypes: <String>[_iPhone11, _iPadM4],
    );
    // Xcode 27.1's runtime only supports the iPhone Duo.
    final Map<String, Object?> ios27_1 = _runtime(
      identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-27-1',
      build: '24A94232',
      version: '27.1',
      deviceTypes: <String>[_iPhoneDuo],
    );
    final String allRuntimes = _listRuntimesJson(<Map<String, Object?>>[
      ios18,
      ios26,
      ios27,
      ios27_1,
    ]);

    test('uses the selected Xcode runtime from legacy "preferredBuild" key', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos26.0',
          ios: <String, Object?>{'preferredBuild': '23A343', 'defaultBuild': '23A343'},
        ),
        deviceTypeId: _iPhone11,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-26-0');
      expect(runtime.build, '23A343');
    });

    test('uses the selected Xcode runtime from "chosenRuntimeBuild" key', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos27.0',
          ios: <String, Object?>{'chosenRuntimeBuild': '24A434', 'defaultBuild': '24A434'},
        ),
        deviceTypeId: _iPhone11,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-27-0');
      expect(runtime.build, '24A434');
    });

    test('"userOverriddenBuild" takes precedence over matched build', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos27.0',
          ios: <String, Object?>{
            'chosenRuntimeBuild': '24A434',
            'defaultBuild': '24A434',
            'userOverriddenBuild': '22E238',
          },
        ),
        deviceTypeId: _iPhone11,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-18-4');
      expect(runtime.build, '22E238');
    });

    test('falls back to last compatible runtime when selected Xcode runtime '
        'does not support the device type', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos27.1',
          ios: <String, Object?>{'chosenRuntimeBuild': '24A94232', 'defaultBuild': '24A94232'},
        ),
        deviceTypeId: _iPadM4,
      );

      // iOS 27.1 only supports the iPhone Duo, so the newest iPad-compatible
      // runtime is used instead.
      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-27-0');
      expect(runtime.build, '24A434');
    });

    test('selects the selected Xcode runtime when it supports the device type', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos27.1',
          ios: <String, Object?>{'chosenRuntimeBuild': '24A94232', 'defaultBuild': '24A94232'},
        ),
        deviceTypeId: _iPhoneDuo,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-27-1');
      expect(runtime.build, '24A94232');
    });

    test('falls back to last compatible runtime when there is no iOS SDK match', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(),
        deviceTypeId: _iPhone11,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-27-0');
    });

    test('falls back to last compatible runtime when the match has no known build key', () {
      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: allRuntimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos27.0',
          ios: <String, Object?>{'defaultBuild': '24A434'},
        ),
        deviceTypeId: _iPhone11,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-27-0');
    });

    test('ignores unavailable and non-iOS runtimes', () {
      final String runtimes = _listRuntimesJson(<Map<String, Object?>>[
        ios18,
        _runtime(
          identifier: 'com.apple.CoreSimulator.SimRuntime.iOS-26-0',
          build: '23A343',
          version: '26.0',
          deviceTypes: <String>[_iPhone11],
          isAvailable: false,
        ),
        _runtime(
          identifier: 'com.apple.CoreSimulator.SimRuntime.watchOS-11-1',
          build: '22R581',
          version: '11.1',
          platform: 'watchOS',
          deviceTypes: <String>[_iPhone11],
        ),
      ]);

      final SimulatorRuntime runtime = selectIOSSimulatorRuntime(
        simctlListRuntimesJson: runtimes,
        simctlRuntimeMatchListJson: _matchListJson(
          iosKey: 'iphoneos26.0',
          ios: <String, Object?>{'chosenRuntimeBuild': '23A343'},
        ),
        deviceTypeId: _iPhone11,
      );

      expect(runtime.identifier, 'com.apple.CoreSimulator.SimRuntime.iOS-18-4');
    });

    test('throws when no runtime supports the device type', () {
      expect(
        () => selectIOSSimulatorRuntime(
          simctlListRuntimesJson: _listRuntimesJson(<Map<String, Object?>>[ios27_1]),
          simctlRuntimeMatchListJson: _matchListJson(
            iosKey: 'iphoneos27.1',
            ios: <String, Object?>{'chosenRuntimeBuild': '24A94232'},
          ),
          deviceTypeId: _iPadM4,
        ),
        throwsA(contains('No iOS simulator runtime supports $_iPadM4')),
      );
    });

    test('throws when there are no runtimes', () {
      expect(
        () => selectIOSSimulatorRuntime(
          simctlListRuntimesJson: '{}',
          simctlRuntimeMatchListJson: '{}',
          deviceTypeId: _iPhone11,
        ),
        throwsA(contains('No iOS simulator runtime supports $_iPhone11')),
      );
    });
  });
}
