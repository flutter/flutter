// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'json_utils.dart';

/// Representation of an experimental or platform-specific feature flag.
@immutable
class FeatureFlag {
  const FeatureFlag({
    required this.help,
    required this.name,
    this.enabledByDefault = false,
    this.environmentOverride,
  });

  /// Deserializes a [FeatureFlag] from a JSON-serializable map.
  factory FeatureFlag.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Field "$nameKey" must not be empty.');
    }
    return FeatureFlag(
      name: name,
      help: json.requiredField<String>(helpKey),
      environmentOverride: json.nullableField<String>(environmentOverrideKey),
      enabledByDefault: json.requiredField<bool>(enabledByDefaultKey),
    );
  }

  /// Deserializes a list of [FeatureFlag]s from a JSON list.
  static List<FeatureFlag> listFromJson(List<Object?> jsonList) {
    return <FeatureFlag>[
      for (final Object? element in jsonList)
        switch (element) {
          final Map<String, Object?> map => FeatureFlag.fromJson(map),
          _ => throw FormatException(
            'Invalid FeatureFlag element: expected Map<String, Object?>, got ${element.runtimeType}.',
          ),
        },
    ];
  }

  /// Map key for [enabledByDefault].
  static const String enabledByDefaultKey = 'enabledByDefault';

  /// Map key for [environmentOverride].
  static const String environmentOverrideKey = 'environmentOverride';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// The CLI flag name used in `flutter config --<name>` or `--no-<name>` (where
  /// `<name>` typically begins with `enable-`).
  final String name;

  /// Configuration setting key name stored in `flutter_settings` for this
  /// feature flag.
  String get settingName => name;

  /// Human-readable description displayed in `flutter config`.
  final String help;

  /// Optional environment variable name that overrides this feature flag setting.
  final String? environmentOverride;

  /// Whether this feature flag is enabled by default.
  final bool enabledByDefault;

  /// Serializes the feature flag to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    helpKey: help,
    environmentOverrideKey: ?environmentOverride,
    enabledByDefaultKey: enabledByDefault,
  };

  @override
  String toString() =>
      'FeatureFlag(name: $name, help: $help, environmentOverride: $environmentOverride, enabledByDefault: $enabledByDefault)';

  @override
  bool operator ==(Object other) {
    return other is FeatureFlag &&
        other.name == name &&
        other.help == help &&
        other.environmentOverride == environmentOverride &&
        other.enabledByDefault == enabledByDefault;
  }

  @override
  int get hashCode => Object.hash(name, help, environmentOverride, enabledByDefault);
}

/// Representation of a custom configuration setting key and value pair.
@immutable
class ConfigOption {
  const ConfigOption({
    required this.help,
    required this.name,
    this.aliases = const <String>[],
    this.environmentOverride,
    this.value,
  });

  /// Deserializes a [ConfigOption] from a JSON-serializable map.
  factory ConfigOption.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Field "$nameKey" must not be empty.');
    }
    return ConfigOption(
      name: name,
      help: json.requiredField<String>(helpKey),
      environmentOverride: json.nullableField<String>(environmentOverrideKey),
      value: json.nullableField<String>(valueKey),
      aliases: List<String>.unmodifiable(json.stringIterable(aliasesKey)),
    );
  }

  /// Deserializes a list of [ConfigOption]s from a JSON list.
  static List<ConfigOption> listFromJson(List<Object?> jsonList) {
    return <ConfigOption>[
      for (final Object? element in jsonList)
        switch (element) {
          final Map<String, Object?> map => ConfigOption.fromJson(map),
          _ => throw FormatException(
            'Invalid ConfigOption element: expected Map<String, Object?>, got ${element.runtimeType}.',
          ),
        },
    ];
  }

  /// Map key for [aliases].
  static const String aliasesKey = 'aliases';

  /// Map key for [environmentOverride].
  static const String environmentOverrideKey = 'environmentOverride';

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

  /// Optional environment variable name that overrides this configuration option.
  final String? environmentOverride;

  /// Current or default value set for this configuration option, if any.
  final String? value;

  /// Optional CLI flag and legacy settings key aliases for this option.
  final List<String> aliases;

  /// Serializes the configuration option to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    helpKey: help,
    environmentOverrideKey: ?environmentOverride,
    valueKey: ?value,
    if (aliases.isNotEmpty) aliasesKey: aliases,
  };

  @override
  String toString() =>
      'ConfigOption(name: $name, help: $help, environmentOverride: $environmentOverride, value: $value, aliases: $aliases)';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality<String>();
    return other is ConfigOption &&
        other.name == name &&
        other.help == help &&
        other.environmentOverride == environmentOverride &&
        other.value == value &&
        listEquality.equals(other.aliases, aliases);
  }

  @override
  int get hashCode => Object.hash(
    name,
    help,
    environmentOverride,
    value,
    const ListEquality<String>().hash(aliases),
  );
}
