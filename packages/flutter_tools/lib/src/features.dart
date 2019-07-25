// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/config.dart';
import 'base/context.dart';
import 'base/platform.dart';
import 'version.dart';

/// The current [FeatureFlags] implementation.
///
/// If not injected, a default implementation is provided.
FeatureFlags get featureFlags => context.get<FeatureFlags>();

/// The interface used to determine if a particular [Feature] is enabled.
///
/// The rest of the tools code should use this class instead of looking up
/// features directly. To faciliate rolls to google3 and other clients, all
/// flags should be provided with a default implementation here. Clients that
/// use this class should extent instead of implement, so that new flags are
/// picked up automatically.
class FeatureFlags {
  const FeatureFlags();

  /// Whether flutter desktop for linux is enabled.
  bool get isLinuxEnabled => _isEnabled(flutterLinuxDesktopFeature);

  /// Whether flutter desktop for macOS is enabled.
  bool get isMacOSEnabled => _isEnabled(flutterMacOSDesktopFeature);

  /// Whether flutter web is enabled.
  bool get isWebEnabled => _isEnabled(flutterWebFeature);

  /// Whether flutter desktop for Windows is enabled.
  bool get isWindowsEnabled => _isEnabled(flutterWindowsDesktopFeature);

  /// Whether plugins are built as AARs in app projects.
  bool get isPluginAsAarEnabled => _isEnabled(flutterBuildPluginAsAarFeature);

  // Calculate whether a particular feature is enabled for the current channel.
  static bool _isEnabled(Feature feature) {
    final String currentChannel = FlutterVersion.instance.channel;
    final FeatureChannelSetting featureSetting = feature.getSettingForChannel(currentChannel);
    if (!featureSetting.available) {
      return false;
    }
    bool isEnabled = featureSetting.enabledByDefault;
    if (feature.configSetting != null) {
      final bool configOverride = Config.instance.getValue(feature.configSetting);
      if (configOverride != null) {
        isEnabled = configOverride;
      }
    }
    if (feature.environmentOverride != null) {
      if (platform.environment[feature.environmentOverride]?.toLowerCase() == 'true') {
        isEnabled = true;
      }
    }
    return isEnabled;
  }
}

/// All current Flutter feature flags.
const List<Feature> allFeatures = <Feature>[
  flutterWebFeature,
  flutterLinuxDesktopFeature,
  flutterMacOSDesktopFeature,
  flutterWindowsDesktopFeature,
  flutterBuildPluginAsAarFeature,
];

/// The [Feature] for flutter web.
const Feature flutterWebFeature = Feature(
  name: 'Flutter for web',
  configSetting: 'enable-web',
  environmentOverride: 'FLUTTER_WEB',
  master: FeatureChannelSetting(
    available: true,
    enabledByDefault: false,
  ),
  dev: FeatureChannelSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for macOS desktop.
const Feature flutterMacOSDesktopFeature = Feature(
  name: 'Flutter for desktop on macOS',
  configSetting: 'enable-macos-desktop',
  environmentOverride: 'ENABLE_FLUTTER_DESKTOP',
  master: FeatureChannelSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for Linux desktop.
const Feature flutterLinuxDesktopFeature = Feature(
  name: 'Flutter for desktop on Linux',
  configSetting: 'enable-linux-desktop',
  environmentOverride: 'ENABLE_FLUTTER_DESKTOP',
  master: FeatureChannelSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for Windows desktop.
const Feature flutterWindowsDesktopFeature = Feature(
  name: 'Flutter for desktop on Windows',
  configSetting: 'enable-windows-desktop',
  environmentOverride: 'ENABLE_FLUTTER_DESKTOP',
  master: FeatureChannelSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// The [Feature] for building plugins as AARs in an app project.
const Feature flutterBuildPluginAsAarFeature = Feature(
  name: 'Build plugins independently as AARs in app projects',
  configSetting: 'enable-build-plugin-as-aar',
  master: FeatureChannelSetting(
    available: true,
    enabledByDefault: true,
  ),
  dev: FeatureChannelSetting(
    available: true,
    enabledByDefault: false,
  ),
);

/// A [Feature] is a process for conditionally enabling tool features.
///
/// All settings are optional, and if not provided will generally default to
/// a "safe" value, such as being off.
///
/// The top level feature settings can be provided to apply to all channels.
/// Otherwise, more specific settings take precedence over higher level
/// settings.
class Feature {
  /// Creates a [Feature].
  const Feature({
    @required this.name,
    this.environmentOverride,
    this.configSetting,
    this.master = const FeatureChannelSetting(),
    this.dev = const FeatureChannelSetting(),
    this.beta = const FeatureChannelSetting(),
    this.stable = const FeatureChannelSetting(),
  });

  /// The user visible name for this feature.
  final String name;

  /// The settings for the master branch and other unknown channels.
  final FeatureChannelSetting master;

  /// The settings for the dev branch.
  final FeatureChannelSetting dev;

  /// The settings for the beta branch.
  final FeatureChannelSetting beta;

  /// The settings for the stable branch.
  final FeatureChannelSetting stable;

  /// The name of an environment variable that can override the setting.
  ///
  /// The environment variable needs to be set to the value 'true'. This is
  /// only intended for usage by CI and not as an advertised method to enable
  /// a feature.
  ///
  /// If not provided, defaults to `null` meaning there is no override.
  final String environmentOverride;

  /// The name of a setting that can be used to enable this feature.
  ///
  /// If not provided, defaults to `null` meaning there is no config setting.
  final String configSetting;

  /// A help message for the `flutter config` command, or null if unsupported.
  String generateHelpMessage() {
    if (configSetting == null) {
      return null;
    }
    final StringBuffer buffer = StringBuffer('Enable or disable $name. '
        'This setting will take effect on ');
    final List<String> channels = <String>[
      if (master.available) 'master',
      if (dev.available) 'dev',
      if (beta.available) 'beta',
      if (stable.available) 'stable',
    ];
    if (channels.length == 1) {
      buffer.write('the ${channels.single} channel.');
    } else if (channels.length == 2) {
      buffer.write('the ${channels.join(' and ')} channels.');
    } else {
      final String prefix = (channels.toList()
        ..removeLast()).join(', ');
      buffer.write('the $prefix, and ${channels.last} channels.');
    }
    return buffer.toString();
  }

  /// Retrieve the correct setting for the provided `channel`.
  FeatureChannelSetting getSettingForChannel(String channel) {
    switch (channel) {
      case 'stable':
        return stable;
      case 'beta':
        return beta;
      case 'dev':
        return dev;
      case 'master':
      default:
        return master;
    }
  }
}

/// A description of the conditions to enable a feature for a particular channel.
class FeatureChannelSetting {
  const FeatureChannelSetting({
    this.available = false,
    this.enabledByDefault = false,
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
}
