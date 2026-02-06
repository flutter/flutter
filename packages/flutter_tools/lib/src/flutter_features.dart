// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/platform.dart';
import 'features.dart';
import 'flutter_features_config.dart';
import 'version.dart';

@visibleForTesting
mixin FlutterFeatureFlagsIsEnabled implements FeatureFlags {
  @protected
  Platform get platform;

  @override
  bool get isLinuxEnabled => isEnabled(flutterLinuxDesktopFeature);

  @override
  bool get isMacOSEnabled => isEnabled(flutterMacOSDesktopFeature);

  @override
  bool get isWebEnabled => isEnabled(flutterWebFeature);

  @override
  bool get isWindowsEnabled => isEnabled(flutterWindowsDesktopFeature);

  @override
  bool get isAndroidEnabled => isEnabled(flutterAndroidFeature);

  @override
  bool get isIOSEnabled => isEnabled(flutterIOSFeature);

  @override
  bool get isFuchsiaEnabled => isEnabled(flutterFuchsiaFeature);

  @override
  bool get areCustomDevicesEnabled => isEnabled(flutterCustomDevicesFeature);

  @override
  bool get isCliAnimationEnabled {
    if (platform.environment['TERM'] == 'dumb') {
      return false;
    }
    return isEnabled(cliAnimation);
  }

  @override
  bool get isNativeAssetsEnabled => isEnabled(nativeAssets);

  @override
  bool get isDartDataAssetsEnabled => isEnabled(dartDataAssets);

  @override
  bool get isSwiftPackageManagerEnabled => isEnabled(swiftPackageManager);

  @override
  bool get isOmitLegacyVersionFileEnabled => isEnabled(omitLegacyVersionFile);

  @override
  bool get isWindowingEnabled => isEnabled(windowingFeature);

  @override
  bool get isLLDBDebuggingEnabled => isEnabled(lldbDebugging);

  @override
  bool get isUISceneMigrationEnabled => isEnabled(uiSceneMigration);

  @override
  bool get isRiscv64SupportEnabled => isEnabled(riscv64);
}

interface class FlutterFeatureFlags extends FeatureFlags with FlutterFeatureFlagsIsEnabled {
  FlutterFeatureFlags({
    required FlutterVersion flutterVersion,
    required FlutterFeaturesConfig featuresConfig,
    required this.platform,
  }) : _flutterVersion = flutterVersion,
       _featuresConfig = featuresConfig;

  final FlutterVersion _flutterVersion;
  final FlutterFeaturesConfig _featuresConfig;

  @override
  @protected
  final Platform platform;

  @override
  bool isEnabled(Feature feature) {
    final String currentChannel = _flutterVersion.channel;
    final FeatureChannelSetting featureSetting = feature.getSettingForChannel(currentChannel);

    // If unavailable, then no setting can enable this feature.
    if (!featureSetting.available) {
      return false;
    }

    // Otherwise, read it from environment variable > project manifest > global config
    return _featuresConfig.isEnabled(feature) ?? featureSetting.enabledByDefault;
  }
}
