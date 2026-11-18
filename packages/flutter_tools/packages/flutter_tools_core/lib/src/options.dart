// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'json_utils.dart';

const _listEquality = ListEquality<String>();
const _mapEquality = MapEquality<String, String>();

int _stringMapHash(Map<String, String> map) => Object.hashAllUnordered(<int>[
  for (final MapEntry(:String key, :String value) in map.entries) Object.hash(key, value),
]);

/// Describes a custom boolean CLI flag registered by a `TemplateService` on
/// `flutter create` or by a `BuildTarget` on `flutter build <name>`.
///
/// Single-character short aliases are intentionally omitted to avoid collisions
/// across global `FlutterCommandRunner` flags, built-in command flags, and
/// multiple active extensions.
@immutable
final class ExtensionFlag {
  /// Defines a boolean CLI flag, hiding it from standard `--help` when [hide]
  /// is `true` or [deprecated] is non-null.
  const ExtensionFlag({
    required this.help,
    required this.name,
    this.defaultsTo = false,
    this.deprecated,
    this.hide = false,
    this.negatable = true,
  }) : assert(name != '');

  /// Deserializes an [ExtensionFlag] from a JSON-serializable map.
  factory ExtensionFlag.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Invalid "$nameKey" in ExtensionFlag: must not be empty.');
    }
    return ExtensionFlag(
      help: json.requiredField<String>(helpKey),
      name: name,
      defaultsTo: json.optionalField<bool>(defaultsToKey, defaultValue: false),
      deprecated: json.nullableField<String>(deprecatedKey),
      hide: json.optionalField<bool>(hideKey, defaultValue: false),
      negatable: json.optionalField<bool>(negatableKey, defaultValue: true),
    );
  }

  /// Map key for [defaultsTo].
  static const String defaultsToKey = 'defaultsTo';

  /// Map key for [deprecated].
  static const String deprecatedKey = 'deprecated';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [hide].
  static const String hideKey = 'hide';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [negatable].
  static const String negatableKey = 'negatable';

  /// Deserializes a list of [ExtensionFlag] objects from JSON.
  static List<ExtensionFlag> listFromJson(Object? raw) {
    if (raw == null) {
      return const <ExtensionFlag>[];
    }
    if (raw is! List<Object?>) {
      throw FormatException('Invalid ExtensionFlag list: expected List, got ${raw.runtimeType}.');
    }
    return <ExtensionFlag>[
      for (final Object? item in raw)
        if (item case final Map<String, Object?> map)
          ExtensionFlag.fromJson(map)
        else
          throw FormatException(
            'Invalid ExtensionFlag element: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
  }

  /// Default boolean value when the flag is not passed on the command line.
  final bool defaultsTo;

  /// Optional deprecation notice; when non-null, the host hides the flag from
  /// standard `--help` output and emits a deprecation warning whenever the flag
  /// is explicitly passed on the command line (`argResults.wasParsed(name)`).
  final String? deprecated;

  /// Description shown in `--help` output.
  final String help;

  /// Whether to omit this flag from standard `--help` output (still shown in
  /// `--help --verbose`).
  final bool hide;

  /// Long CLI flag name (for example, `'tizen-wearable'` or `'sign'`).
  final String name;

  /// Whether the flag supports a `--no-<name>` prefix.
  final bool negatable;

  /// Serializes this [ExtensionFlag] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    defaultsToKey: defaultsTo,
    deprecatedKey: ?deprecated,
    helpKey: help,
    hideKey: hide,
    nameKey: name,
    negatableKey: negatable,
  };

  @override
  String toString() =>
      'ExtensionFlag(name: $name, help: $help, defaultsTo: $defaultsTo, '
      'deprecated: $deprecated, hide: $hide, negatable: $negatable)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionFlag &&
            other.defaultsTo == defaultsTo &&
            other.deprecated == deprecated &&
            other.help == help &&
            other.hide == hide &&
            other.name == name &&
            other.negatable == negatable);
  }

  @override
  int get hashCode => Object.hash(defaultsTo, deprecated, help, hide, name, negatable);
}

/// Describes a custom single-value CLI option registered by a
/// `TemplateService` on `flutter create` or by a `BuildTarget` on
/// `flutter build <name>`.
///
/// Single-character short aliases are intentionally omitted to avoid collisions
/// across global `FlutterCommandRunner` flags, built-in command flags, and
/// multiple active extensions.
@immutable
final class ExtensionOption {
  /// Defines a single-value CLI option, hiding it from standard `--help` when
  /// [hide] is `true` or [deprecated] is non-null.
  ///
  /// Setting [mandatory] to `true` is supported only on `BuildTarget.options`
  /// (`flutter build <name>`) and is rejected on `TemplateService.options`
  /// because `flutter create` shares a single `ArgParser` across all target
  /// platforms.
  const ExtensionOption({
    required this.help,
    required this.name,
    this.allowed,
    this.allowedHelp,
    this.defaultsTo,
    this.deprecated,
    this.hide = false,
    this.mandatory = false,
    this.valueHelp,
  }) : assert(name != '');

  /// Deserializes an [ExtensionOption] from a JSON-serializable map.
  factory ExtensionOption.fromJson(Map<String, Object?> json) {
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Invalid "$nameKey" in ExtensionOption: must not be empty.');
    }
    final List<String>? allowed = json[allowedKey] != null
        ? json.stringIterable(allowedKey).toList()
        : null;
    final Map<String, String>? allowedHelp = json[allowedHelpKey] != null
        ? json.stringMap(allowedHelpKey)
        : null;
    return ExtensionOption(
      help: json.requiredField<String>(helpKey),
      name: name,
      allowed: allowed,
      allowedHelp: allowedHelp,
      defaultsTo: json.nullableField<String>(defaultsToKey),
      deprecated: json.nullableField<String>(deprecatedKey),
      hide: json.optionalField<bool>(hideKey, defaultValue: false),
      mandatory: json.optionalField<bool>(mandatoryKey, defaultValue: false),
      valueHelp: json.nullableField<String>(valueHelpKey),
    );
  }

  /// Map key for [allowed].
  static const String allowedKey = 'allowed';

  /// Map key for [allowedHelp].
  static const String allowedHelpKey = 'allowedHelp';

  /// Map key for [defaultsTo].
  static const String defaultsToKey = 'defaultsTo';

  /// Map key for [deprecated].
  static const String deprecatedKey = 'deprecated';

  /// Map key for [help].
  static const String helpKey = 'help';

  /// Map key for [hide].
  static const String hideKey = 'hide';

  /// Map key for [mandatory].
  static const String mandatoryKey = 'mandatory';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [valueHelp].
  static const String valueHelpKey = 'valueHelp';

  /// Deserializes a list of [ExtensionOption] objects from JSON.
  static List<ExtensionOption> listFromJson(Object? raw) {
    if (raw == null) {
      return const <ExtensionOption>[];
    }
    if (raw is! List<Object?>) {
      throw FormatException('Invalid ExtensionOption list: expected List, got ${raw.runtimeType}.');
    }
    return <ExtensionOption>[
      for (final Object? item in raw)
        if (item case final Map<String, Object?> map)
          ExtensionOption.fromJson(map)
        else
          throw FormatException(
            'Invalid ExtensionOption element: expected Map<String, Object?>, got ${item.runtimeType}.',
          ),
    ];
  }

  /// Optional allowlist of valid string values for this option.
  final List<String>? allowed;

  /// Optional per-value descriptions for each entry in [allowed].
  final Map<String, String>? allowedHelp;

  /// Default value used when the option is omitted on the command line.
  final String? defaultsTo;

  /// Optional deprecation notice; when non-null, the host hides the option from
  /// standard `--help` output and emits a deprecation warning whenever the
  /// option is explicitly passed on the command line
  /// (`argResults.wasParsed(name)`).
  final String? deprecated;

  /// Description shown in `--help` output.
  final String help;

  /// Whether to omit this option from standard `--help` output (still shown in
  /// `--help --verbose`).
  final bool hide;

  /// Whether the user must provide this option when invoking
  /// `flutter build <name>` (must remain `false` on `TemplateService.options`).
  final bool mandatory;

  /// Long CLI option name (for example, `'tizen-language'` or
  /// `'security-profile'`).
  final String name;

  /// Placeholder label for the option value in `--help` output (for example,
  /// `'profile-name'`).
  final String? valueHelp;

  /// Serializes this [ExtensionOption] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    allowedKey: ?allowed,
    allowedHelpKey: ?allowedHelp,
    defaultsToKey: ?defaultsTo,
    deprecatedKey: ?deprecated,
    helpKey: help,
    hideKey: hide,
    mandatoryKey: mandatory,
    nameKey: name,
    valueHelpKey: ?valueHelp,
  };

  @override
  String toString() =>
      'ExtensionOption(name: $name, help: $help, defaultsTo: $defaultsTo, '
      'deprecated: $deprecated, hide: $hide, allowed: $allowed, '
      'allowedHelp: $allowedHelp, valueHelp: $valueHelp, mandatory: $mandatory)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionOption &&
            _listEquality.equals(other.allowed, allowed) &&
            _mapEquality.equals(other.allowedHelp, allowedHelp) &&
            other.defaultsTo == defaultsTo &&
            other.deprecated == deprecated &&
            other.help == help &&
            other.hide == hide &&
            other.mandatory == mandatory &&
            other.name == name &&
            other.valueHelp == valueHelp);
  }

  @override
  int get hashCode => Object.hash(
    allowed == null ? null : Object.hashAll(allowed!),
    allowedHelp == null ? null : _stringMapHash(allowedHelp!),
    defaultsTo,
    deprecated,
    help,
    hide,
    mandatory,
    name,
    valueHelp,
  );
}
