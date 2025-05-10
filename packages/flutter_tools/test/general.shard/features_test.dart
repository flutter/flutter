// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_features.dart';
import 'package:flutter_tools/src/flutter_features_config.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  group('Features', () {
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
      const FeatureChannelSetting masterSetting = FeatureChannelSetting(available: true);
      const FeatureChannelSetting betaSetting = FeatureChannelSetting(available: true);
      const FeatureChannelSetting stableSetting = FeatureChannelSetting(available: true);
      const Feature feature = Feature(
        name: 'example',
        master: masterSetting,
        beta: betaSetting,
        stable: stableSetting,
      );

      expect(feature.getSettingForChannel('master'), masterSetting);
      expect(feature.getSettingForChannel('beta'), betaSetting);
      expect(feature.getSettingForChannel('stable'), stableSetting);
      expect(feature.getSettingForChannel('unknown'), masterSetting);
    });

    testWithoutContext('reads from configuration if available', () {
      const Feature exampleFeature = Feature(
        name: 'example',
        master: FeatureChannelSetting(available: true),
      );

      final FlutterFeatureFlags flags = FlutterFeatureFlags(
        flutterVersion: FakeFlutterVersion(),
        featuresConfig: _FakeFeaturesConfig()..cannedResponse[exampleFeature] = true,
        platform: FakePlatform(),
      );
      expect(flags.isEnabled(exampleFeature), true);
    });

    testWithoutContext('returns false if not available', () {
      const Feature exampleFeature = Feature(name: 'example');

      final FlutterFeatureFlags flags = FlutterFeatureFlags(
        flutterVersion: FakeFlutterVersion(),
        featuresConfig: _FakeFeaturesConfig()..cannedResponse[exampleFeature] = true,
        platform: FakePlatform(),
      );
      expect(flags.isEnabled(exampleFeature), false);
    });

    FileSystem createFsWithPubspec() {
      final FileSystem fs = MemoryFileSystem.test();
      fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('''
        flutter:
          config:
            enable-foo: true
            enable-bar: false
            enable-baz: true
      ''');
      return fs;
    }

    testUsingContext(
      'FeatureFlags is influenced by the CWD',
      () {
        // This test intentionally uses Context, as featureFlags is read that way at runtime.
        final FeatureFlags featureFlagsFromContext = featureFlags;

        // Try a few flags that don't actually exist, but we want to check configuration more e2e-y.
        expect(
          featureFlagsFromContext.isEnabled(
            const Feature(
              name: 'foo',
              configSetting: 'enable-foo',
              master: FeatureChannelSetting(available: true),
            ),
          ),
          isTrue,
          reason: 'enable-foo: true is in pubspec.yaml',
        );

        expect(
          featureFlagsFromContext.isEnabled(
            const Feature.fullyEnabled(name: 'bar', configSetting: 'enable-bar'),
          ),
          isFalse,
          reason: 'enable-bar: false is in pubspec.yaml',
        );

        expect(
          featureFlagsFromContext.isEnabled(
            const Feature(name: 'baz', configSetting: 'enable-baz'),
          ),
          isFalse,
          reason: 'Is not available',
        );
      },
      overrides: <Type, Generator>{
        ProcessManager: FakeProcessManager.empty,
        FileSystem: createFsWithPubspec,
      },
    );
  });

  group('Linux Destkop', () {
    test('is fully enabled', () {
      expect(flutterLinuxDesktopFeature, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(flutterLinuxDesktopFeature.configSetting, 'enable-linux-desktop');
      expect(flutterLinuxDesktopFeature.environmentOverride, 'FLUTTER_LINUX');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterLinuxDesktopFeature,
      );
      expect(checkFlags.isLinuxEnabled, isTrue);
    });
  });

  group('MacOS Desktop', () {
    test('is fully enabled', () {
      expect(flutterMacOSDesktopFeature, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(flutterMacOSDesktopFeature.configSetting, 'enable-macos-desktop');
      expect(flutterMacOSDesktopFeature.environmentOverride, 'FLUTTER_MACOS');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterMacOSDesktopFeature,
      );
      expect(checkFlags.isMacOSEnabled, isTrue);
    });
  });

  group('Windows Desktop', () {
    test('is fully enabled', () {
      expect(flutterWindowsDesktopFeature, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(flutterWindowsDesktopFeature.configSetting, 'enable-windows-desktop');
      expect(flutterWindowsDesktopFeature.environmentOverride, 'FLUTTER_WINDOWS');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterWindowsDesktopFeature,
      );
      expect(checkFlags.isWindowsEnabled, isTrue);
    });
  });

  group('Web', () {
    test('is fully enabled', () {
      expect(flutterWebFeature, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(flutterWebFeature.configSetting, 'enable-web');
      expect(flutterWebFeature.environmentOverride, 'FLUTTER_WEB');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterWebFeature,
      );
      expect(checkFlags.isWebEnabled, isTrue);
    });
  });

  group('Android', () {
    test('is fully enabled', () {
      expect(flutterAndroidFeature, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(flutterAndroidFeature.configSetting, 'enable-android');
      expect(flutterAndroidFeature.environmentOverride, isNull);
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterAndroidFeature,
      );
      expect(checkFlags.isAndroidEnabled, isTrue);
    });
  });

  group('iOS', () {
    test('is fully enabled', () {
      expect(flutterIOSFeature, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(flutterIOSFeature.configSetting, 'enable-ios');
      expect(flutterIOSFeature.environmentOverride, isNull);
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterIOSFeature,
      );
      expect(checkFlags.isIOSEnabled, isTrue);
    });
  });

  group('Fuchsia', () {
    test('is only available on master', () {
      expect(
        flutterFuchsiaFeature,
        allOf(<Matcher>[
          _onChannelIs('master', available: true, enabledByDefault: false),
          _onChannelIs('stable', available: false, enabledByDefault: false),
          _onChannelIs('beta', available: false, enabledByDefault: false),
        ]),
      );
    });

    test('can be configured', () {
      expect(flutterFuchsiaFeature.configSetting, 'enable-fuchsia');
      expect(flutterFuchsiaFeature.environmentOverride, 'FLUTTER_FUCHSIA');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterFuchsiaFeature,
      );
      expect(checkFlags.isFuchsiaEnabled, isTrue);
    });
  });

  group('Custom Devices', () {
    test('is always available but not enabled by default', () {
      expect(
        flutterCustomDevicesFeature,
        allOf(<Matcher>[
          _onChannelIs('master', available: true, enabledByDefault: false),
          _onChannelIs('stable', available: true, enabledByDefault: false),
          _onChannelIs('beta', available: true, enabledByDefault: false),
        ]),
      );
    });

    test('can be configured', () {
      expect(flutterCustomDevicesFeature.configSetting, 'enable-custom-devices');
      expect(flutterCustomDevicesFeature.environmentOverride, 'FLUTTER_CUSTOM_DEVICES');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: flutterCustomDevicesFeature,
      );
      expect(checkFlags.areCustomDevicesEnabled, isTrue);
    });
  });

  group('CLI Animations', () {
    test('is always enabled', () {
      expect(cliAnimation, _isFullyEnabled);
    });

    test('can be disabled by TERM=dumb', () {
      final FlutterFeatureFlags features = FlutterFeatureFlags(
        flutterVersion: FakeFlutterVersion(),
        featuresConfig: _FakeFeaturesConfig(),
        platform: FakePlatform(environment: <String, String>{'TERM': 'dumb'}),
      );

      expect(features.isCliAnimationEnabled, isFalse);
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: cliAnimation,
      );
      expect(checkFlags.isCliAnimationEnabled, isTrue);
    });
  });

  group('Native Assets', () {
    test('is available on master', () {
      expect(
        nativeAssets,
        allOf(<Matcher>[
          _onChannelIs('master', available: true, enabledByDefault: false),
          _onChannelIs('stable', available: false, enabledByDefault: false),
          _onChannelIs('beta', available: false, enabledByDefault: false),
        ]),
      );
    });

    test('can be configured', () {
      expect(nativeAssets.configSetting, 'enable-native-assets');
      expect(nativeAssets.environmentOverride, 'FLUTTER_NATIVE_ASSETS');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: nativeAssets,
      );
      expect(checkFlags.isNativeAssetsEnabled, isTrue);
    });
  });

  group('Swift Package Manager', () {
    test('is available on all channels', () {
      expect(
        swiftPackageManager,
        allOf(<Matcher>[
          _onChannelIs('master', available: true, enabledByDefault: false),
          _onChannelIs('stable', available: true, enabledByDefault: false),
          _onChannelIs('beta', available: true, enabledByDefault: false),
        ]),
      );
    });

    test('can be configured', () {
      expect(swiftPackageManager.configSetting, 'enable-swift-package-manager');
      expect(swiftPackageManager.environmentOverride, 'FLUTTER_SWIFT_PACKAGE_MANAGER');
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: swiftPackageManager,
      );
      expect(checkFlags.isSwiftPackageManagerEnabled, isTrue);
    });
  });

  group('Explicit Package Dependencies', () {
    test('is fully enabled', () {
      expect(explicitPackageDependencies, _isFullyEnabled);
    });

    test('can be configured', () {
      expect(explicitPackageDependencies.configSetting, 'explicit-package-dependencies');
      expect(explicitPackageDependencies.environmentOverride, isNull);
    });

    test('forwards to isEnabled', () {
      final _TestIsGetterForwarding checkFlags = _TestIsGetterForwarding(
        shouldInvoke: explicitPackageDependencies,
      );
      expect(checkFlags.isExplicitPackageDependenciesEnabled, isTrue);
    });
  });
}

final class _FakeFeaturesConfig implements FlutterFeaturesConfig {
  final Map<Feature, bool?> cannedResponse = <Feature, bool?>{};

  @override
  bool? isEnabled(Feature feature) => cannedResponse[feature];
}

Matcher _onChannelIs(String channel, {required bool available, required bool enabledByDefault}) {
  return _FeaturesMatcher(
    channel: channel,
    available: available,
    enabledByDefault: enabledByDefault,
  );
}

Matcher get _isFullyEnabled {
  return allOf(const <_FeaturesMatcher>[
    _FeaturesMatcher(channel: 'master', available: true, enabledByDefault: true),
    _FeaturesMatcher(channel: 'stable', available: true, enabledByDefault: true),
    _FeaturesMatcher(channel: 'beta', available: true, enabledByDefault: true),
  ]);
}

final class _FeaturesMatcher extends Matcher {
  const _FeaturesMatcher({
    required this.channel,
    required this.available,
    required this.enabledByDefault,
  });

  final String channel;
  final bool available;
  final bool enabledByDefault;

  @override
  Description describe(Description description) {
    description = description.add('feature on the "$channel" channel ');
    if (available) {
      description = description.add('is available ');
    } else {
      description = description.add('is not available');
    }
    description = description.add('and is ');
    if (enabledByDefault) {
      description = description.add('is enabled by default');
    } else {
      description = description.add('is not enabled by default');
    }
    return description;
  }

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! Feature) {
      return false;
    }
    final FeatureChannelSetting setting = switch (channel) {
      'master' => item.master,
      'stable' => item.stable,
      'beta' => item.beta,
      _ => throw StateError('Invalid channel: "$channel"'),
    };
    if (setting.available != available) {
      return false;
    }
    if (setting.enabledByDefault != enabledByDefault) {
      return false;
    }
    return true;
  }
}

final class _TestIsGetterForwarding with FlutterFeatureFlagsIsEnabled {
  _TestIsGetterForwarding({required this.shouldInvoke});

  final Feature shouldInvoke;
  @override
  final Platform platform = FakePlatform();

  @override
  bool isEnabled(Feature feature) {
    return feature == shouldInvoke;
  }
}
