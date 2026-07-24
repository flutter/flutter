// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/common.dart';
import 'base/config.dart';
import 'base/platform.dart';
import 'features.dart';
import 'flutter_manifest.dart';

/// Reads configuration flags to possibly override the default flag value.
///
/// See [isEnabled] for details on how feature flag values are resolved.
interface class FlutterFeaturesConfig {
  /// Creates a feature configuration reader from the provided sources.
  ///
  /// [globalConfig] reads values stored by the `flutter config` tool, which
  /// are normally in the user's `%HOME` directory (varies by system), while
  /// [projectManifest] reads values from the _current_ Flutter project's
  /// `pubspec.yaml`
  const FlutterFeaturesConfig({
    required Config globalConfig,
    required Platform platform,
    required FlutterManifest? projectManifest,
  }) : _globalConfig = globalConfig,
       _platform = platform,
       _projectManifest = projectManifest;

  final Config _globalConfig;
  final Platform _platform;

  // Can be null if no manifest file exists in the current directory.
  final FlutterManifest? _projectManifest;

  /// Returns whether [feature] has been turned on/off from configuration.
  ///
  /// If the feature was not configured, or cannot be configured, returns `null`.
  ///
  /// The value is resolved, if possible, in the following order, where if a
  /// step resolves to a boolean value, no further steps are attempted:
  ///
  ///
  /// ## 1. Local Project Configuration
  ///
  /// If [Feature.configSetting] is `null`, this step is skipped.
  ///
  /// If the value defined by the key `$configSetting` is set in `pubspec.yaml`,
  /// it is returned as a boolean value.
  ///
  /// Assuming there is a setting where `configSetting: 'enable-foo'`:
  ///
  /// ```yaml
  /// # true
  /// flutter:
  ///   config:
  ///     enable-foo: true
  ///
  /// # false
  /// flutter:
  ///   config:
  ///     enable-foo: false
  /// ```
  ///
  /// ## 2. Global Tool Configuration
  ///
  /// If [Feature.configSetting] is `null`, this step is skipped.
  ///
  /// If the value defined by the key `$configSetting` is set in the global
  /// (platform dependent) configuration file, it is returned as a boolean
  /// value.
  ///
  /// Assuming there is a setting where `configSetting: 'enable-foo'`:
  ///
  /// ```sh
  /// # future runs will treat the value as true
  /// flutter config --enable-foo
  ///
  /// # future runs will treat the value as false
  /// flutter config --no-enable-foo
  /// ```
  ///
  /// ## 3. Environment Variable
  ///
  /// If [Feature.environmentOverride] is `null`, this step is skipped.
  ///
  /// If the value defined by the key `$environmentOverride` is equal to the
  /// string `'true'` (case insensitive), returns `true`, or `false` otherwise.
  ///
  /// Assuming there is a flag where `environmentOverride: 'ENABLE_FOO'`:
  ///
  /// ```sh
  /// # true
  /// ENABLE_FOO=true flutter some-command
  ///
  /// # true
  /// ENABLE_FOO=TRUE flutter some-command
  ///
  /// # false
  /// ENABLE_FOO=false flutter some-command
  ///
  /// # false
  /// ENABLE_FOO=any-other-value flutter some-command
  /// ```
  bool? isEnabled(Feature feature) {
    return _isEnabledByConfigValue(feature) ?? _isEnabledByPlatformEnvironment(feature);
  }

  bool? _isEnabledByConfigValue(Feature feature) {
    // If the feature cannot be configured by local/global config settings, return null.
    final String? featureName = feature.configSetting;
    if (featureName == null) {
      return null;
    }
    return _isEnabledAtProjectLevel(featureName) ?? _isEnabledByGlobalConfig(featureName);
  }

  bool? _isEnabledByPlatformEnvironment(Feature feature) {
    // If the feature cannot be configured by an environment variable, return null.
    final String? environmentName = feature.environmentOverride;
    if (environmentName == null) {
      return null;
    }
    final Object? environmentValue = _platform.environment[environmentName]?.toLowerCase();
    if (environmentValue == null) {
      return null;
    }
    return environmentValue == 'true';
  }

  bool? _isEnabledAtProjectLevel(String featureName) {
    final Object? configSection = _projectManifest?.flutterDescriptor['config'];
    if (configSection == null) {
      return null;
    }
    if (configSection is! Map) {
      throwToolExit(
        'The "config" property of "flutter" in pubspec.yaml must be a map, but '
        'got $configSection (${configSection.runtimeType})',
      );
    }
    return _requireBoolOrNull(
      configSection[featureName],
      featureName: featureName,
      source: '"flutter: config:" in pubspec.yaml',
    );
  }

  bool? _isEnabledByGlobalConfig(String featureName) {
    return _requireBoolOrNull(
      _globalConfig.getValue(featureName),
      featureName: featureName,
      source: '"${_globalConfig.configPath}"',
    );
  }

  static bool? _requireBoolOrNull(
    Object? value, {
    required String featureName,
    required String source,
  }) {
    if (value is bool?) {
      return value;
    }
    throwToolExit(
      'The "$featureName" property in $source must be a boolean, but got $value (${value.runtimeType})',
    );
  }
}
