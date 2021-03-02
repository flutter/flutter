// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';

void main() {
  group('Features', () {
    MockFlutterVerion mockFlutterVerion;
    Config testConfig;
    MockPlatform mockPlatform;
    FlutterFeatureFlags featureFlags;

    setUp(() {
      mockFlutterVerion = MockFlutterVerion();
      testConfig = Config.test();
      mockPlatform = MockPlatform();
      when(mockPlatform.environment).thenReturn(<String, String>{});

      for (final Feature feature in allFeatures) {
        testConfig.setValue(feature.configSetting, false);
      }

      featureFlags = FlutterFeatureFlags(
        flutterVersion: mockFlutterVerion,
        config: testConfig,
        platform: mockPlatform,
      );
    });

    testWithoutContext('setting has safe defaults', () {
      const FeatureChannelSetting featureSetting = FeatureChannelSetting();

      expect(featureSetting.available, false);
      expect(featureSetting.enabledByDefault, false);
    });

    testWithoutContext('has safe defaults', () {
      const Feature feature = Feature(name: 'example');

      expect(feature.name, 'example');
      expect(feature.environmentOverride, null);
      expect(feature.configSetting, null);
    });

    testWithoutContext('retrieves the correct setting for each branch', () {
      final FeatureChannelSetting masterSetting = FeatureChannelSetting(available: nonconst(true));
      final FeatureChannelSetting devSetting = FeatureChannelSetting(available: nonconst(true));
      final FeatureChannelSetting betaSetting = FeatureChannelSetting(available: nonconst(true));
      final FeatureChannelSetting stableSetting = FeatureChannelSetting(available: nonconst(true));
      final Feature feature = Feature(
        name: 'example',
        master: masterSetting,
        dev: devSetting,
        beta: betaSetting,
        stable: stableSetting,
      );

      expect(feature.getSettingForChannel('master'), masterSetting);
      expect(feature.getSettingForChannel('dev'), devSetting);
      expect(feature.getSettingForChannel('beta'), betaSetting);
      expect(feature.getSettingForChannel('stable'), stableSetting);
      expect(feature.getSettingForChannel('unknown'), masterSetting);
    });

    testWithoutContext('env variables are only enabled with "true" string', () {
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WEB': 'hello'});

      expect(featureFlags.isWebEnabled, false);

      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WEB': 'true'});

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web help string', () {
      expect(flutterWebFeature.generateHelpMessage(),
      'Enable or disable Flutter for web. '
      'This setting will take effect on the master, dev, beta, and stable channels.');
    });

    testWithoutContext('flutter macOS desktop help string', () {
      expect(flutterMacOSDesktopFeature.generateHelpMessage(),
      'Enable or disable beta-quality support for desktop on macOS. '
      'This setting will take effect on the master, dev, beta, and stable channels. '
      'Newer beta versions are available on the beta channel.');
    });

    testWithoutContext('flutter Linux desktop help string', () {
      expect(flutterLinuxDesktopFeature.generateHelpMessage(),
      'Enable or disable beta-quality support for desktop on Linux. '
      'This setting will take effect on the master, dev, beta, and stable channels. '
      'Newer beta versions are available on the beta channel.');
    });

    testWithoutContext('flutter Windows desktop help string', () {
      expect(flutterWindowsDesktopFeature.generateHelpMessage(),
      'Enable or disable beta-quality support for desktop on Windows. '
      'This setting will take effect on the master, dev, beta, and stable channels. '
      'Newer beta versions are available on the beta channel.');
    });

    testWithoutContext('help string on multiple channels', () {
      const Feature testWithoutContextFeature = Feature(
        name: 'example',
        master: FeatureChannelSetting(available: true),
        dev: FeatureChannelSetting(available: true),
        beta: FeatureChannelSetting(available: true),
        stable: FeatureChannelSetting(available: true),
        configSetting: 'foo',
      );

      expect(testWithoutContextFeature.generateHelpMessage(), 'Enable or disable example. '
          'This setting will take effect on the master, dev, beta, and stable channels.');
    });

    /// Flutter Web

    testWithoutContext('flutter web off by default on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');

      expect(featureFlags.isWebEnabled, false);
    });

    testWithoutContext('flutter web enabled with config on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      testConfig.setValue('enable-web', true);

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web enabled with environment variable on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WEB': 'true'});

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web off by default on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');

      expect(featureFlags.isWebEnabled, false);
    });

    testWithoutContext('flutter web enabled with config on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      testConfig.setValue('enable-web', true);

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web enabled with environment variable on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WEB': 'true'});

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web off by default on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');

      expect(featureFlags.isWebEnabled, false);
    });

    testWithoutContext('flutter web enabled with config on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      testConfig.setValue('enable-web', true);

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web not enabled with environment variable on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WEB': 'true'});

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web on by default on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      testConfig.removeValue('enable-web');

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web enabled with config on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      testConfig.setValue('enable-web', true);

      expect(featureFlags.isWebEnabled, true);
    });

    testWithoutContext('flutter web not enabled with environment variable on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WEB': 'enabled'});

      expect(featureFlags.isWebEnabled, false);
    });

    /// Flutter macOS desktop.

    testWithoutContext('flutter macos desktop off by default on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');

      expect(featureFlags.isMacOSEnabled, false);
    });

    testWithoutContext('flutter macos desktop enabled with config on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      testConfig.setValue('enable-macos-desktop', true);

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop enabled with environment variable on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_MACOS': 'true'});

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop off by default on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');

      expect(featureFlags.isMacOSEnabled, false);
    });

    testWithoutContext('flutter macos desktop enabled with config on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      testConfig.setValue('enable-macos-desktop', true);

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop enabled with environment variable on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_MACOS': 'true'});

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop off by default on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');

      expect(featureFlags.isMacOSEnabled, false);
    });

    testWithoutContext('flutter macos desktop enabled with config on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      testConfig.setValue('enable-macos-desktop', true);

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop enabled with environment variable on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_MACOS': 'true'});

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop off by default on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');

      expect(featureFlags.isMacOSEnabled, false);
    });

    testWithoutContext('flutter macos desktop enabled with config on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      testConfig.setValue('enable-macos-desktop', true);

      expect(featureFlags.isMacOSEnabled, true);
    });

    testWithoutContext('flutter macos desktop enabled with environment variable on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_MACOS': 'true'});

      expect(featureFlags.isMacOSEnabled, true);
    });

    /// Flutter Linux Desktop
    testWithoutContext('flutter linux desktop off by default on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');

      expect(featureFlags.isLinuxEnabled, false);
    });

    testWithoutContext('flutter linux desktop enabled with config on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      testConfig.setValue('enable-linux-desktop', true);

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop enabled with environment variable on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_LINUX': 'true'});

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop off by default on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');

      expect(featureFlags.isLinuxEnabled, false);
    });

    testWithoutContext('flutter linux desktop enabled with config on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      testConfig.setValue('enable-linux-desktop', true);

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop enabled with environment variable on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_LINUX': 'true'});

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop off by default on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');

      expect(featureFlags.isLinuxEnabled, false);
    });

    testWithoutContext('flutter linux desktop enabled with config on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      testConfig.setValue('enable-linux-desktop', true);

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop enabled with environment variable on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_LINUX': 'true'});

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop off by default on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');

      expect(featureFlags.isLinuxEnabled, false);
    });

    testWithoutContext('flutter linux desktop enabled with config on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      testConfig.setValue('enable-linux-desktop', true);

      expect(featureFlags.isLinuxEnabled, true);
    });

    testWithoutContext('flutter linux desktop enabled with environment variable on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_LINUX': 'true'});

      expect(featureFlags.isLinuxEnabled, true);
    });

    /// Flutter Windows desktop.
    testWithoutContext('flutter windows desktop off by default on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');

      expect(featureFlags.isWindowsEnabled, false);
    });

    testWithoutContext('flutter windows desktop enabled with config on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      testConfig.setValue('enable-windows-desktop', true);

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop enabled with environment variable on master', () {
      when(mockFlutterVerion.channel).thenReturn('master');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WINDOWS': 'true'});

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop off by default on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');

      expect(featureFlags.isWindowsEnabled, false);
    });

    testWithoutContext('flutter windows desktop enabled with config on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      testConfig.setValue('enable-windows-desktop', true);

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop not enabled with environment variable on dev', () {
      when(mockFlutterVerion.channel).thenReturn('dev');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WINDOWS': 'true'});

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop off by default on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');

      expect(featureFlags.isWindowsEnabled, false);
    });

    testWithoutContext('flutter windows desktop enabled with config on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      testConfig.setValue('enable-windows-desktop', true);

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop enabled with environment variable on beta', () {
      when(mockFlutterVerion.channel).thenReturn('beta');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WINDOWS': 'true'});

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop off by default on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');

      expect(featureFlags.isWindowsEnabled, false);
    });

    testWithoutContext('flutter windows desktop enabled with config on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      testConfig.setValue('enable-windows-desktop', true);

      expect(featureFlags.isWindowsEnabled, true);
    });

    testWithoutContext('flutter windows desktop enabled with environment variable on stable', () {
      when(mockFlutterVerion.channel).thenReturn('stable');
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_WINDOWS': 'true'});

      expect(featureFlags.isWindowsEnabled, true);
    });
  });
}

class MockFlutterVerion extends Mock implements FlutterVersion {}
class MockPlatform extends Mock implements Platform {}

T nonconst<T>(T item) => item;
