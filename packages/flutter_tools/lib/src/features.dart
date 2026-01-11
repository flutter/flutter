// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'flutter_features.dart';
library;

import 'package:meta/meta.dart';

import 'base/context.dart';

/// The current [FeatureFlags] implementation.
FeatureFlags get featureFlags => context.get<FeatureFlags>()!;

/// The interface used to determine if a particular [Feature] is enabled.
///
/// This class is extended in google3. Whenever a new flag is added,
/// google3 must also be updated using a g3fix.
///
/// See also:
///
/// * [FlutterFeatureFlags], Flutter's implementation of this class.
/// * https://github.com/flutter/flutter/blob/main/docs/contributing/Feature-flags.md,
///   docs on feature flags and how to add or use them.
abstract class FeatureFlags {
  /// const constructor so that subclasses can be const.
  const FeatureFlags();

  /// Whether flutter desktop for linux is enabled.
  bool get isLinuxEnabled;

  /// Whether flutter desktop for macOS is enabled.
  bool get isMacOSEnabled;

  /// Whether flutter web is enabled.
  bool get isWebEnabled;

  /// Whether flutter desktop for Windows is enabled.
  bool get isWindowsEnabled;

  /// Whether android is enabled.
  bool get isAndroidEnabled;

  /// Whether iOS is enabled.
  bool get isIOSEnabled;

  /// Whether fuchsia is enabled.
  bool get isFuchsiaEnabled;

  /// Whether custom devices are enabled.
  bool get areCustomDevicesEnabled;

  /// Whether animations are used in the command line interface.
  bool get isCliAnimationEnabled;

  /// Whether native assets compilation and bundling is enabled.
  bool get isNativeAssetsEnabled;

  /// Whether dart data assets building and bundling is enabled.
  bool get isDartDataAssetsEnabled => false;

  /// Whether Swift Package Manager dependency management is enabled.
  bool get isSwiftPackageManagerEnabled;

  /// Whether to stop writing the `{FLUTTER_ROOT}/version` file.
  ///
  /// Tracking removal: <https://github.com/flutter/flutter/issues/171900>.
  bool get isOmitLegacyVersionFileEnabled;

  /// Whether desktop windowing is enabled.
  bool get isWindowingEnabled;

  /// Whether physical iOS devices are debugging with LLDB.
  bool get isLLDBDebuggingEnabled;

  /// Whether UIScene migration is enabled.
  bool get isUISceneMigrationEnabled;

  /// Wether riscv64 support is enabled.
  bool get isRiscv64SupportEnabled;

  /// Whether a particular feature is enabled for the current channel.
  ///
  /// Prefer using one of the specific getters above instead of this API.
  bool isEnabled(Feature feature);

  /// All current Flutter feature flags.
  List<Feature> get allFeatures => const <Feature>[
    flutterWebFeature,
    flutterLinuxDesktopFeature,
    flutterMacOSDesktopFeature,
    flutterWindowsDesktopFeature,
    flutterAndroidFeature,
    flutterIOSFeature,
    flutterFuchsiaFeature,
    flutterCustomDevicesFeature,
    cliAnimation,
    nativeAssets,
    dartDataAssets,
    swiftPackageManager,
    omitLegacyVersionFile,
    windowingFeature,
    lldbDebugging,
    uiSceneMigration,
    riscv64,
  ];

  /// All current Flutter feature flags that can be configured.
  ///
  /// [Feature.configSetting] is not `null`.
  Iterable<Feature> get allConfigurableFeatures {
    return allFeatures.where((Feature feature) => feature.configSetting != null);
  }

  /// All Flutter feature flags that are enabled.
  // This member is overriden in google3.
  Iterable<Feature> get allEnabledFeatures {
    return allFeatures.where(isEnabled);
  }
}

/// All current Flutter feature flags that can be configured.
///
/// [Feature.configSetting] is not `null`.
Iterable<Feature> get allConfigurableFeatures => featureFlags.allConfigurableFeatures;

/// The [Feature] for flutter web.
const flutterWebFeature = Feature.fullyEnabled(
  name: 'Flutter for web',
  configSetting: 'enable-web',
  environmentOverride: 'FLUTTER_WEB',
);

/// The [Feature] for macOS desktop.
const flutterMacOSDesktopFeature = Feature.fullyEnabled(
  name: 'support for desktop on macOS',
  configSetting: 'enable-macos-desktop',
  environmentOverride: 'FLUTTER_MACOS',
);

/// The [Feature] for Linux desktop.
const flutterLinuxDesktopFeature = Feature.fullyEnabled(
  name: 'support for desktop on Linux',
  configSetting: 'enable-linux-desktop',
  environmentOverride: 'FLUTTER_LINUX',
);

/// The [Feature] for Windows desktop.
const flutterWindowsDesktopFeature = Feature.fullyEnabled(
  name: 'support for desktop on Windows',
  configSetting: 'enable-windows-desktop',
  environmentOverride: 'FLUTTER_WINDOWS',
);

/// The [Feature] for Android devices.
const flutterAndroidFeature = Feature.fullyEnabled(
  name: 'Flutter for Android',
  configSetting: 'enable-android',
);

/// The [Feature] for iOS devices.
const flutterIOSFeature = Feature.fullyEnabled(
  name: 'Flutter for iOS',
  configSetting: 'enable-ios',
);

/// The [Feature] for Fuchsia support.
const flutterFuchsiaFeature = Feature(
  name: 'Flutter for Fuchsia',
  configSetting: 'enable-fuchsia',
  environmentOverride: 'FLUTTER_FUCHSIA',
  master: FeatureChannelSetting(available: true),
);

const flutterCustomDevicesFeature = Feature(
  name: 'early support for custom device types',
  configSetting: 'enable-custom-devices',
  environmentOverride: 'FLUTTER_CUSTOM_DEVICES',
  master: FeatureChannelSetting(available: true),
  beta: FeatureChannelSetting(available: true),
  stable: FeatureChannelSetting(available: true),
);

/// The [Feature] for CLI animations.
///
/// The TERM environment variable set to "dumb" turns this off.
const cliAnimation = Feature.fullyEnabled(
  name: 'animations in the command line interface',
  configSetting: 'cli-animations',
);

/// Enable native assets compilation and bundling.
const nativeAssets = Feature(
  name: 'native assets compilation and bundling',
  configSetting: 'enable-native-assets',
  environmentOverride: 'FLUTTER_NATIVE_ASSETS',
  master: FeatureChannelSetting(available: true, enabledByDefault: true),
  beta: FeatureChannelSetting(available: true, enabledByDefault: true),
  stable: FeatureChannelSetting(available: true, enabledByDefault: true),
);

/// Enable Dart data assets building and bundling.
const dartDataAssets = Feature(
  name: 'Dart data assets building and bundling',
  configSetting: 'enable-dart-data-assets',
  environmentOverride: 'FLUTTER_DART_DATA_ASSETS',
  master: FeatureChannelSetting(available: true),
);

/// Enable Swift Package Manager as a darwin dependency manager.
const swiftPackageManager = Feature(
  name: 'support for Swift Package Manager for iOS and macOS',
  configSetting: 'enable-swift-package-manager',
  environmentOverride: 'FLUTTER_SWIFT_PACKAGE_MANAGER',
  master: FeatureChannelSetting(available: true),
  beta: FeatureChannelSetting(available: true),
  stable: FeatureChannelSetting(available: true),
);

/// Whether to continue writing the `{FLUTTER_ROOT}/version` legacy file.
///
/// Tracking removal: <https://github.com/flutter/flutter/issues/171900>.
const omitLegacyVersionFile = Feature.fullyEnabled(
  name: 'stops writing the legacy version file',
  configSetting: 'omit-legacy-version-file',
  extraHelpText:
      'If set, the file {FLUTTER_ROOT}/version is no longer written as part of '
      'the flutter tool execution; a newer file format has existed for some '
      'time in {FLUTTER_ROOT}/bin/cache/flutter.version.json.',
);

/// Whether desktop windowing is enabled.
///
/// See: https://github.com/flutter/flutter/issues/30701.
const windowingFeature = Feature(
  name: 'support for windowing on macOS, Linux, and Windows',
  configSetting: 'enable-windowing',
  environmentOverride: 'FLUTTER_WINDOWING',
  runtimeId: 'windowing',
  master: FeatureChannelSetting(available: true),
);

/// Enable LLDB debugging for physical iOS devices. When LLDB debugging is off,
/// Xcode debugging is used instead.
///
/// Requires iOS 17+ and Xcode 26+. If those requirements are not met, the previous
/// default debugging method is used instead.
const lldbDebugging = Feature(
  name: 'support for debugging with LLDB for physical iOS devices',
  extraHelpText:
      'If LLDB debugging is off, Xcode debugging is used instead. '
      'Only available for iOS 17 or newer devices. Requires Xcode 26 or greater.',
  configSetting: 'enable-lldb-debugging',
  environmentOverride: 'FLUTTER_LLDB_DEBUGGING',
  master: FeatureChannelSetting(available: true, enabledByDefault: true),
  beta: FeatureChannelSetting(available: true, enabledByDefault: true),
  stable: FeatureChannelSetting(available: true, enabledByDefault: true),
);

/// Enable UIScene lifecycle migration for iOS apps. When enabled, if possible the tool will
/// attempt to auto-migrate the app. Otherwise, it will print a warning with instructions on how to
/// migrate manually.
const uiSceneMigration = Feature(
  name: 'support for migrating to UIScene lifecycle',
  extraHelpText:
      'If enabled, Flutter will migrate your app to iOS UIScene lifecycle if possible or '
      'otherwise instruct you to migrate manually.',
  configSetting: 'enable-uiscene-migration',
  environmentOverride: 'FLUTTER_UISCENE_MIGRATION',
  master: FeatureChannelSetting(available: true, enabledByDefault: true),
  beta: FeatureChannelSetting(available: true, enabledByDefault: true),
  stable: FeatureChannelSetting(available: true, enabledByDefault: true),
);

/// The [Feature] for building code targetting riscv64 architecture
const riscv64 = Feature(
  name: 'support for riscv64 architecture',
  configSetting: 'enable-riscv64',
  environmentOverride: 'FLUTTER_RISCV64',
  master: FeatureChannelSetting(available: true, enabledByDefault: true),
  beta: FeatureChannelSetting(available: true),
  stable: FeatureChannelSetting(available: true),
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
    required this.name,
    this.environmentOverride,
    this.configSetting,
    this.runtimeId,
    this.extraHelpText,
    this.master = const FeatureChannelSetting(),
    this.beta = const FeatureChannelSetting(),
    this.stable = const FeatureChannelSetting(),
  });

  /// Creates a [Feature] that is fully enabled across channels.
  const Feature.fullyEnabled({
    required this.name,
    this.environmentOverride,
    this.configSetting,
    this.runtimeId,
    this.extraHelpText,
  }) : master = const FeatureChannelSetting(available: true, enabledByDefault: true),
       beta = const FeatureChannelSetting(available: true, enabledByDefault: true),
       stable = const FeatureChannelSetting(available: true, enabledByDefault: true);

  /// The user visible name for this feature.
  final String name;

  /// The settings for the master branch and other unknown channels.
  final FeatureChannelSetting master;

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
  final String? environmentOverride;

  /// The name of a setting that can be used to enable this feature.
  ///
  /// If not provided, defaults to `null` meaning there is no config setting.
  final String? configSetting;

  /// The unique identifier for this feature at runtime.
  ///
  /// If not `null`, the Flutter framework's enabled feature flags will
  /// contain this value if this feature is enabled.
  final String? runtimeId;

  /// Additional text to add to the end of the help message.
  ///
  /// If not provided, defaults to `null` meaning there is no additional text.
  final String? extraHelpText;

  /// A help message for the `flutter config` command, or null if unsupported.
  String? generateHelpMessage() {
    if (configSetting == null) {
      return null;
    }
    final buffer = StringBuffer('Enable or disable $name.');
    final channels = <String>[
      if (master.available) 'master',
      if (beta.available) 'beta',
      if (stable.available) 'stable',
    ];
    // Add channel info for settings only on some channels.
    if (channels.length == 1) {
      buffer.write('\nThis setting applies only to the ${channels.single} channel.');
    } else if (channels.length == 2) {
      buffer.write('\nThis setting applies only to the ${channels.join(' and ')} channels.');
    }
    if (extraHelpText != null) {
      buffer.write(' $extraHelpText');
    }
    return buffer.toString();
  }

  /// Retrieve the correct setting for the provided `channel`.
  FeatureChannelSetting getSettingForChannel(String channel) {
    return switch (channel) {
      'stable' => stable,
      'beta' => beta,
      'master' || _ => master,
    };
  }
}

/// A description of the conditions to enable a feature for a particular channel.
@immutable
final class FeatureChannelSetting {
  const FeatureChannelSetting({this.available = false, this.enabledByDefault = false});

  /// Whether the feature is available on this channel.
  ///
  /// If not provided, defaults to `false`. This implies that the feature
  /// cannot be enabled even by the settings below.
  final bool available;

  /// Whether the feature is enabled by default.
  ///
  /// If not provided, defaults to `false`.
  final bool enabledByDefault;

  @override
  bool operator ==(Object other) {
    return other is FeatureChannelSetting &&
        available == other.available &&
        enabledByDefault == other.enabledByDefault;
  }

  @override
  int get hashCode => Object.hash(available, enabledByDefault);

  @override
  String toString() {
    return 'FeatureChannelSetting <available: $available, enabledByDefault: $enabledByDefault>';
  }
}
