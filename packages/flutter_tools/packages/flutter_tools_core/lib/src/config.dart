// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Representation of an experimental or platform-specific feature flag.
@immutable
class FeatureFlag {
  const FeatureFlag({
    required this.name,
    required this.help,
    this.environmentVariable,
    this.enabledByDefault = false,
  });

  /// Deserializes a [FeatureFlag] from a JSON-serializable map.
  factory FeatureFlag.fromJson(Map<String, Object?> json) {
    return FeatureFlag(
      name: json.optionalField<String>(nameKey, defaultValue: ''),
      help: json.optionalField<String>(helpKey, defaultValue: ''),
      environmentVariable: json.nullableField<String>(environmentVariableKey),
      enabledByDefault: json.optionalField<bool>(enabledByDefaultKey, defaultValue: false),
    );
  }

  /// Map key for [enabledByDefault].
  static const String enabledByDefaultKey = 'enabledByDefault';

  /// Map key for [environmentVariable].
  static const String environmentVariableKey = 'environmentVariable';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// The CLI flag name used in `flutter config --<name>` or `--no-<name>` (where
  /// `<name>` typically begins with `enable-`).
  final String name;

  /// Human-readable description displayed in `flutter config`.
  final String help;

  /// Optional environment variable name that overrides this feature flag setting.
  final String? environmentVariable;

  /// Whether this feature flag is enabled by default.
  final bool enabledByDefault;

  /// Serializes the feature flag to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    helpKey: help,
    environmentVariableKey: ?environmentVariable,
    enabledByDefaultKey: enabledByDefault,
  };

  @override
  String toString() =>
      'FeatureFlag(name: $name, help: $help, environmentVariable: $environmentVariable, enabledByDefault: $enabledByDefault)';

  @override
  bool operator ==(Object other) {
    return other is FeatureFlag &&
        other.name == name &&
        other.help == help &&
        other.environmentVariable == environmentVariable &&
        other.enabledByDefault == enabledByDefault;
  }

  @override
  int get hashCode => Object.hash(name, help, environmentVariable, enabledByDefault);
}

/// Representation of a custom configuration setting key and value pair.
@immutable
class ConfigOption {
  const ConfigOption({required this.name, required this.help, this.value});

  /// Deserializes a [ConfigOption] from a JSON-serializable map.
  factory ConfigOption.fromJson(Map<String, Object?> json) {
    return ConfigOption(
      name: json.optionalField<String>(nameKey, defaultValue: ''),
      help: json.optionalField<String>(helpKey, defaultValue: ''),
      value: json.nullableField<String>(valueKey),
    );
  }

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [value].
  static const String valueKey = 'value';

  /// The configuration key name used in `flutter config --<name>=<value>`.
  final String name;

  /// Description of the configuration option displayed in `flutter config`.
  final String help;

  /// Current value set for this configuration option, if any.
  final String? value;

  /// Serializes the configuration option to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{nameKey: name, helpKey: help, valueKey: ?value};

  @override
  String toString() => 'ConfigOption(name: $name, help: $help, value: $value)';

  @override
  bool operator ==(Object other) {
    return other is ConfigOption &&
        other.name == name &&
        other.help == help &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(name, help, value);
}
