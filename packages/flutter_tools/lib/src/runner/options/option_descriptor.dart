// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

/// Defines the lookup scope for an [OptionDescriptor].
enum OptionScope {
  /// Look up only within the subcommand's local `ArgResults`.
  local,

  /// Look up only within the root command runner's `ArgResults.globalResults`.
  global,

  /// Check local `ArgResults` first, falling back to `globalResults`.
  any,
}

/// A metadata-rich, type-safe descriptor for a command-line option or flag.
abstract class OptionDescriptor<T> {
  const OptionDescriptor({
    required this.name,
    required this.help,
    this.abbr,
    this.valueHelp,
    this.defaultsTo,
    this.allowed,
    this.allowedHelp,
    this.scope = OptionScope.local,
    this.hide = false,
    this.verboseOnly = false,
  });

  /// The CLI option name (without leading dashes).
  final String name;

  /// The help string displayed in usage output.
  final String help;

  /// An optional single-character abbreviation.
  final String? abbr;

  /// An optional label displayed in usage to represent the value.
  final String? valueHelp;

  /// The default value if not specified on the command line.
  final T? defaultsTo;

  /// An optional list of allowed values.
  final List<String>? allowed;

  /// An optional map of allowed values to their descriptions.
  final Map<String, String>? allowedHelp;

  /// The scope where this option's result is located.
  final OptionScope scope;

  /// Whether to hide this option from usage output by default.
  final bool hide;

  /// Whether to hide this option from usage output unless verbose help is requested.
  final bool verboseOnly;

  /// The CLI flag representation (e.g., `--target`).
  String get flag => '--$name';

  /// Registers this option with [parser], maintaining descriptor identity in [registry].
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<Object?>>? registry,
    bool verboseHelp = false,
    bool? hideOverride,
  });

  /// Checks if this option was explicitly provided on the command line.
  bool wasProvided(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    return target != null && target.options.contains(name) && target.wasParsed(name);
  }

  /// Checks if this option is registered in [results].
  bool isRegistered(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    return target != null && target.options.contains(name);
  }

  /// Checks if this option was explicitly parsed (alias for [wasProvided]).
  bool wasParsed(ArgResults? results, {ArgResults? globalResults}) =>
      wasProvided(results, globalResults: globalResults);

  /// Returns the resolved value for this option.
  T getValue(ArgResults? results, {ArgResults? globalResults});

  ArgResults? _resolveTargetResults(ArgResults? results, ArgResults? globalResults) {
    return switch (scope) {
      .local => results,
      .global => globalResults,
      .any when results?.options.contains(name) == true && results!.wasParsed(name) => results,
      .any => globalResults ?? results,
    };
  }

  bool _computeEffectiveHide({required bool verboseHelp, bool? hideOverride}) =>
      hideOverride ?? (hide || (verboseOnly && !verboseHelp));

  void _throwConflictError(String name, OptionDescriptor<Object?>? existing) {
    final existingInfo = existing != null
        ? '${existing.runtimeType} (help: "${existing.help}")'
        : 'non-descriptor option';
    throw ArgumentError(
      'Conflicting option descriptor registered for "$name"!\n'
      'Existing: $existingInfo\n'
      'New: $runtimeType (help: "$help")',
    );
  }
}

/// A descriptor for single-value string options.
class StringOptionDescriptor extends OptionDescriptor<String?> {
  const StringOptionDescriptor({
    required super.name,
    required super.help,
    super.abbr,
    super.valueHelp,
    super.defaultsTo,
    this.aliases = const <String>[],
    super.allowed,
    super.allowedHelp,
    super.scope,
    super.hide,
    super.verboseOnly,
  });

  /// Alternative names for this option.
  final List<String> aliases;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<Object?>>? registry,
    bool verboseHelp = false,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<Object?>? existing = registry?[name];
      if (existing != null && identical(existing, this)) {
        return;
      }
      _throwConflictError(name, existing);
    }

    parser.addOption(
      name,
      abbr: abbr,
      aliases: aliases,
      help: help,
      valueHelp: valueHelp,
      defaultsTo: defaultsTo,
      allowed: allowed,
      allowedHelp: allowedHelp,
      hide: _computeEffectiveHide(verboseHelp: verboseHelp, hideOverride: hideOverride),
    );
    registry?[name] = this;
  }

  @override
  String? getValue(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    if (target != null && target.options.contains(name)) {
      return target[name] as String?;
    }
    return defaultsTo;
  }

  /// Returns the resolved value or [fallback] if null.
  String getValueOrDefault(
    ArgResults? results, {
    ArgResults? globalResults,
    String fallback = '',
  }) => getValue(results, globalResults: globalResults) ?? fallback;
}

/// A descriptor for boolean flags with a concrete default value.
class FlagOptionDescriptor extends OptionDescriptor<bool> {
  const FlagOptionDescriptor({
    required super.name,
    required super.help,
    super.abbr,
    super.defaultsTo = false,
    this.negatable = true,
    super.scope,
    super.hide,
    super.verboseOnly,
  });

  /// Whether the flag can be negated with `--no-<name>`.
  final bool negatable;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<Object?>>? registry,
    bool verboseHelp = false,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<Object?>? existing = registry?[name];
      if (existing != null && identical(existing, this)) {
        return;
      }
      _throwConflictError(name, existing);
    }
    parser.addFlag(
      name,
      abbr: abbr,
      help: help,
      defaultsTo: defaultsTo ?? false,
      negatable: negatable,
      hide: _computeEffectiveHide(verboseHelp: verboseHelp, hideOverride: hideOverride),
    );
    registry?[name] = this;
  }

  @override
  bool getValue(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    if (target != null && target.options.contains(name)) {
      return (target[name] as bool?) ?? defaultsTo ?? false;
    }
    return defaultsTo ?? false;
  }
}

/// A descriptor for tri-state boolean flags without a default value.
///
/// When omitted from the command line, [getValue] returns `null`.
class NullableFlagOptionDescriptor extends OptionDescriptor<bool?> {
  const NullableFlagOptionDescriptor({
    required super.name,
    required super.help,
    super.abbr,
    this.negatable = true,
    super.scope,
    super.hide,
    super.verboseOnly,
  }) : super(defaultsTo: null);

  /// Whether the flag can be negated with `--no-<name>`.
  final bool negatable;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<Object?>>? registry,
    bool verboseHelp = false,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<Object?>? existing = registry?[name];
      if (existing != null && identical(existing, this)) {
        return;
      }
      _throwConflictError(name, existing);
    }
    parser.addFlag(
      name,
      abbr: abbr,
      help: help,
      defaultsTo: null,
      negatable: negatable,
      hide: _computeEffectiveHide(verboseHelp: verboseHelp, hideOverride: hideOverride),
    );
    registry?[name] = this;
  }

  @override
  bool? getValue(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    if (target != null && target.options.contains(name)) {
      return target[name] as bool?;
    }
    return defaultsTo;
  }
}

/// A descriptor for multi-value options (passed multiple times or comma-separated).
class MultiOptionDescriptor extends OptionDescriptor<List<String>> {
  const MultiOptionDescriptor({
    required super.name,
    required super.help,
    super.abbr,
    super.valueHelp,
    this.splitCommas = true,
    this.aliases = const <String>[],
    super.defaultsTo = const <String>[],
    super.allowed,
    super.allowedHelp,
    super.scope,
    super.hide,
    super.verboseOnly,
  });

  /// Whether values containing commas are split into multiple entries.
  final bool splitCommas;

  /// Alternative names for this option.
  final List<String> aliases;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<Object?>>? registry,
    bool verboseHelp = false,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<Object?>? existing = registry?[name];
      if (existing != null && identical(existing, this)) {
        return;
      }
      _throwConflictError(name, existing);
    }
    parser.addMultiOption(
      name,
      abbr: abbr,
      aliases: aliases,
      help: help,
      valueHelp: valueHelp,
      defaultsTo: defaultsTo,
      splitCommas: splitCommas,
      allowed: allowed,
      allowedHelp: allowedHelp,
      hide: _computeEffectiveHide(verboseHelp: verboseHelp, hideOverride: hideOverride),
    );
    registry?[name] = this;
  }

  @override
  List<String> getValue(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    if (target != null && target.options.contains(name)) {
      return (target[name] as List<dynamic>?)?.cast<String>() ?? const <String>[];
    }
    return defaultsTo ?? const <String>[];
  }
}
