// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../version.dart';
import 'config.dart';
import 'context.dart';
import 'platform.dart';

/// The current [FeatureFlags] implementation.
///
/// If not injected, a default implementation is provided.
FeatureFlags get featureFlags => context.get<FeatureFlags>() ?? const FeatureFlags();

/// The interface used to determine if a particular [Feature] is enabled.
///
/// The rest of the tools code should use this class instead of looking up
/// features directly. To faciliate rolls to google3 and other clients, all
/// flags should be provided with a default implementation here. Clients that
/// use this class should extent instead of implement, so that new flags are
/// picked up automatically.
class FeatureFlags {
  const FeatureFlags();

  /// Whether flutter web is enabled.
  ///
  /// Defaults to `false`.
  bool get isWebEnabled => false;

  /// Whether flutter desktop for macOS is enabled.
  ///
  /// Defaults to `false`.
  bool get isMacOSEnabled => false;

  /// Whether flutter desktop for Windows is enabled.
  ///
  /// Defaults to `false`.
  bool get isWindowsEnabled => false;

  /// Whether flutter desktop for linux is enabled.
  ///
  /// Defaults to `false`.
  bool get isLinuxEnabled => false;
}

/// All current Flutter feature flags.
const List<Feature> allFeatures = <Feature>[
  flutterWebFeature,
  flutterLinuxDesktopFeature,
  flutterMacOSDesktopFeature,
  flutterWindowsDesktopFeature,
];

/// The [Feature] for flutter web.
const Feature flutterWebFeature = Feature(
  setting: FeatureSetting(
    configSetting: 'flutter-web',
    environmentOverride: 'FLUTTER_WEB',
  ),
  master: FeatureSetting(
    available: true,
    enabledByDefault: false,
  ),
  dev: FeatureSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for macOS desktop.
const Feature flutterMacOSDesktopFeature = Feature(
  setting: FeatureSetting(
    configSetting: 'flutter-macos-desktop',
    environmentOverride: 'ENABLE_FLUTTER_DESKTOP',
  ),
  master: FeatureSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for Linux desktop.
const Feature flutterLinuxDesktopFeature = Feature(
  setting: FeatureSetting(
    configSetting: 'flutter-linux-desktop',
    environmentOverride: 'ENABLE_FLUTTER_DESKTOP',
  ),
  master: FeatureSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for Windows desktop.
const Feature flutterWindowsDesktopFeature = Feature(
  setting: FeatureSetting(
    configSetting: 'flutter-windows-desktop',
    environmentOverride: 'ENABLE_FLUTTER_DESKTOP',
  ),
  master: FeatureSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// A [FeatureFlags] that looks up values based on [Feature] definitions.
class FlutterFeatureFlags implements FeatureFlags {
  const FlutterFeatureFlags();

  @override
  bool get isLinuxEnabled => _isEnabled(flutterLinuxDesktopFeature);

  @override
  bool get isMacOSEnabled => _isEnabled(flutterMacOSDesktopFeature);

  @override
  bool get isWebEnabled => _isEnabled(flutterWebFeature);

  @override
  bool get isWindowsEnabled => _isEnabled(flutterWindowsDesktopFeature);

  // Calculate whether a particular feature is enabled for the current channel.
  static bool _isEnabled(Feature feature) {
    final String currentChannel = FlutterVersion.instance.channel;
    FeatureSetting featureSetting;
    switch (currentChannel) {
      case 'stable':
        featureSetting = feature.stable;
        break;
      case 'beta':
        featureSetting = feature.beta;
        break;
      case 'dev':
        featureSetting = feature.dev;
        break;
      case 'master':
      default:
        featureSetting = feature.master;
        break;
    }
    featureSetting = featureSetting.combineWith(feature.setting);
    if (!featureSetting.available) {
      return false;
    }
    bool isEnabled = featureSetting.enabledByDefault;
    if (featureSetting.configSetting != null) {
      final bool configOverride = Config.instance.getValue(featureSetting.configSetting);
      if (configOverride != null) {
        isEnabled = configOverride;
      }
    }
    if (featureSetting.environmentOverride != null) {
      if (platform.environment[featureSetting.environmentOverride] != null) {
        isEnabled = true;
      }
    }
    return isEnabled;
  }
}

/// A [Feature] is process for conditionally enabling tool features.
///
/// All settings are optional, and if not provided will generally default to
/// a "safe" value, such as being off.
///
/// The top level feature settings can be provided to apply to all channels.
/// Otherwise, more specific settings take precidence over higher level
/// settings.
///
/// For example, to e
class Feature {
  /// Creates a [Feature].
  const Feature({
    this.master = const FeatureSetting(),
    this.dev = const FeatureSetting(),
    this.beta = const FeatureSetting(),
    this.stable = const FeatureSetting(),
    this.setting = const FeatureSetting(),
  });

  /// The settings for the master branch and other unknown channels.
  final FeatureSetting master;

  /// The settings for the dev branch.
  final FeatureSetting dev;

  /// The settings for the beta branch.
  final FeatureSetting beta;

  /// The settings for the stable branch.
  final FeatureSetting stable;

  /// The top-level deault features.
  final FeatureSetting setting;
}

/// A description of the conditions to enable a feature.
class FeatureSetting {
  const FeatureSetting({
    this.available = false,
    this.enabledByDefault = false,
    this.environmentOverride,
    this.configSetting,
  });

  /// Whether the feature is available on this channel.
  ///
  /// If not provded, defaults to `false`. This implies that the feature
  /// cannot be enabled even by the settings below.
  final bool available;

  /// Whether the feature is enabled by default.
  ///
  /// If not provided, defaults to `false`.
  final bool enabledByDefault;

  /// The name of an environment variable that can override the setting.
  ///
  /// The environment variable only needs to be "set", that is contain a
  /// non empty string. This is only intended for usage by CI and not
  /// as an advertised method to enable a feature.
  ///
  /// If not provided, defaults to `null` meaning there is no override.
  final String environmentOverride;

  /// The name of a setting that can be used to enable this feature.
  ///
  /// If not provided, defaults to `null` meaning there is no config setting.
  final String configSetting;

  /// A utility to combine two feature settings.
  ///
  /// The current object takes precedence with its non-null values.
  FeatureSetting combineWith(FeatureSetting other) {
    return FeatureSetting(
      available: available ?? other.available,
      enabledByDefault: enabledByDefault ?? other.enabledByDefault,
      environmentOverride: environmentOverride ?? other.environmentOverride,
      configSetting: configSetting ?? other.configSetting,
    );
  }
}
