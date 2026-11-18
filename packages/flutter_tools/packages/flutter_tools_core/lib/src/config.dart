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
    required this.name,
    required this.help,
    this.environmentOverride,
    this.enabledByDefault = false,
  });

  /// Deserializes a [FeatureFlag] from a JSON-serializable map.
  factory FeatureFlag.fromJson(Map<String, Object?> json) {
    return FeatureFlag(
      name: json.optionalField<String>(nameKey, defaultValue: ''),
      help: json.optionalField<String>(helpKey, defaultValue: ''),
      environmentOverride: json.nullableField<String>(environmentOverrideKey),
      enabledByDefault: json.optionalField<bool>(enabledByDefaultKey, defaultValue: false),
    );
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
    required this.name,
    required this.help,
    this.environmentOverride,
    this.value,
    this.aliases = const <String>[],
  });

  /// Deserializes a [ConfigOption] from a JSON-serializable map.
  factory ConfigOption.fromJson(Map<String, Object?> json) {
    return ConfigOption(
      name: json.optionalField<String>(nameKey, defaultValue: ''),
      help: json.optionalField<String>(helpKey, defaultValue: ''),
      environmentOverride: json.nullableField<String>(environmentOverrideKey),
      value: json.nullableField<String>(valueKey),
      aliases: List<String>.unmodifiable(json.stringIterable(aliasesKey)),
    );
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

/// Describes an interactive or multi-setting configuration action registered on
/// `flutter config` (for example, `--select-ios-signing-settings` or
/// `--clear-ios-signing-settings`).
@immutable
class ConfigAction {
  /// Creates a configuration action definition for `flutter config`.
  const ConfigAction({
    required this.name,
    required this.help,
    this.aliases = const <String>[],
    this.settingsKeys = const <String>[],
  });

  /// Deserializes a [ConfigAction] from a JSON-serializable map.
  factory ConfigAction.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Field "$nameKey" must not be empty.');
    }
    return ConfigAction(
      name: name,
      help: json.requiredField<String>(helpKey),
      aliases: List<String>.unmodifiable(json.stringIterable(aliasesKey)),
      settingsKeys: List<String>.unmodifiable(json.stringIterable(settingsKeysKey)),
    );
  }

  /// Deserializes a list of [ConfigAction]s from a JSON list.
  static List<ConfigAction> listFromJson(List<Object?> jsonList) {
    return <ConfigAction>[
      for (final Object? element in jsonList)
        switch (element) {
          final Map<String, Object?> map => ConfigAction.fromJson(map),
          _ => throw FormatException(
            'Invalid ConfigAction element: expected Map<String, Object?>, got ${element.runtimeType}.',
          ),
        },
    ];
  }

  /// Map key for [aliases].
  static const String aliasesKey = 'aliases';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [settingsKeys].
  static const String settingsKeysKey = 'settingsKeys';

  /// Flag name exposed on `flutter config` as `--<name>` (non-negatable).
  final String name;

  /// Description shown in `flutter config --help`.
  final String help;

  /// Alternative flag names accepted for this action on the command line.
  final List<String> aliases;

  /// Configuration store keys read, updated, or cleared by this action.
  ///
  /// Used by the Flutter Tool to scope the `currentSettings` passed to
  /// `ConfigService.runConfigAction`, validate the returned updates, and
  /// display saved values under the extension's section in
  /// `flutter config --list` without exposing them as standalone CLI flags.
  final List<String> settingsKeys;

  /// Serializes the configuration action to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    nameKey: name,
    helpKey: help,
    if (aliases.isNotEmpty) aliasesKey: aliases,
    if (settingsKeys.isNotEmpty) settingsKeysKey: settingsKeys,
  };

  @override
  String toString() =>
      'ConfigAction(name: $name, help: $help, aliases: $aliases, settingsKeys: $settingsKeys)';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality<String>();
    return other is ConfigAction &&
        other.name == name &&
        other.help == help &&
        listEquality.equals(other.aliases, aliases) &&
        listEquality.equals(other.settingsKeys, settingsKeys);
  }

  @override
  int get hashCode {
    const listEquality = ListEquality<String>();
    return Object.hash(name, help, listEquality.hash(aliases), listEquality.hash(settingsKeys));
  }
}
