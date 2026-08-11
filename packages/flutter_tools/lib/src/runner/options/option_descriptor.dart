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

  /// The CLI flag representation (e.g., `--target`).
  String get flag => '--$name';

  /// Registers this option with [parser], maintaining descriptor identity in [registry].
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<dynamic>>? registry,
    bool? hideOverride,
  });

  /// Checks if this option was explicitly parsed in [results] or [globalResults].
  bool wasParsed(ArgResults? results, {ArgResults? globalResults}) {
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    return target != null && target.options.contains(name) && target.wasParsed(name);
  }

  /// Returns the explicitly parsed value or `null` if the option was omitted.
  T? getParsedValue(ArgResults? results, {ArgResults? globalResults});

  /// Returns the parsed value, falling back to [defaultsTo].
  T? getValue(ArgResults? results, {ArgResults? globalResults}) =>
      getParsedValue(results, globalResults: globalResults) ?? defaultsTo;

  ArgResults? _resolveTargetResults(ArgResults? results, ArgResults? globalResults) {
    return switch (scope) {
      OptionScope.local => results,
      OptionScope.global => globalResults,
      OptionScope.any =>
        (results != null && results.options.contains(name) && results.wasParsed(name))
            ? results
            : (globalResults ?? results),
    };
  }
}

/// A descriptor for single-value string options.
class StringOptionDescriptor extends OptionDescriptor<String> {
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
  });

  /// Alternative names for this option.
  final List<String> aliases;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<dynamic>>? registry,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<dynamic>? existing = registry?[name];
      if (existing != null && (identical(existing, this) || existing == this)) {
        return;
      }
      throw ArgumentError('Conflicting option descriptor registered for "$name"!');
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
      hide: hideOverride ?? hide,
    );
    registry?[name] = this;
  }

  @override
  String? getParsedValue(ArgResults? results, {ArgResults? globalResults}) {
    if (!wasParsed(results, globalResults: globalResults)) {
      return null;
    }
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    return target?[name] as String?;
  }
}

/// A descriptor for boolean flags.
class FlagOptionDescriptor extends OptionDescriptor<bool> {
  const FlagOptionDescriptor({
    required super.name,
    required super.help,
    super.abbr,
    super.defaultsTo = false,
    this.negatable = true,
    super.scope,
    super.hide,
  });

  /// Whether the flag can be negated with `--no-<name>`.
  final bool negatable;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<dynamic>>? registry,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<dynamic>? existing = registry?[name];
      if (existing != null && (identical(existing, this) || existing == this)) {
        return;
      }
      throw ArgumentError('Conflicting flag descriptor registered for "$name"!');
    }
    parser.addFlag(
      name,
      abbr: abbr,
      help: help,
      defaultsTo: defaultsTo ?? false,
      negatable: negatable,
      hide: hideOverride ?? hide,
    );
    registry?[name] = this;
  }

  @override
  bool? getParsedValue(ArgResults? results, {ArgResults? globalResults}) {
    if (!wasParsed(results, globalResults: globalResults)) {
      return null;
    }
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    return target?[name] as bool?;
  }

  @override
  bool getValue(ArgResults? results, {ArgResults? globalResults}) =>
      getParsedValue(results, globalResults: globalResults) ?? defaultsTo ?? false;
}

/// A descriptor for multi-value options (lists of strings).
class MultiOptionDescriptor extends OptionDescriptor<List<String>> {
  const MultiOptionDescriptor({
    required super.name,
    required super.help,
    super.abbr,
    super.valueHelp,
    this.splitCommas = true,
    this.aliases = const <String>[],
    super.allowed,
    super.allowedHelp,
    super.scope,
    super.hide,
  }) : super(defaultsTo: const <String>[]);

  /// Whether multiple values can be separated by commas in a single flag.
  final bool splitCommas;

  /// Alternative names for this option.
  final List<String> aliases;

  @override
  void addTo(
    ArgParser parser, {
    Map<String, OptionDescriptor<dynamic>>? registry,
    bool? hideOverride,
  }) {
    if (parser.options.containsKey(name)) {
      final OptionDescriptor<dynamic>? existing = registry?[name];
      if (existing != null && (identical(existing, this) || existing == this)) {
        return;
      }
      throw ArgumentError('Conflicting multi-option descriptor registered for "$name"!');
    }
    parser.addMultiOption(
      name,
      abbr: abbr,
      help: help,
      valueHelp: valueHelp,
      splitCommas: splitCommas,
      aliases: aliases,
      allowed: allowed,
      allowedHelp: allowedHelp,
      hide: hideOverride ?? hide,
    );
    registry?[name] = this;
  }

  @override
  List<String>? getParsedValue(ArgResults? results, {ArgResults? globalResults}) {
    if (!wasParsed(results, globalResults: globalResults)) {
      return null;
    }
    final ArgResults? target = _resolveTargetResults(results, globalResults);
    final Object? raw = target?[name];
    if (raw is List<String>) {
      return raw;
    }
    if (raw is List) {
      return raw.cast<String>();
    }
    return null;
  }

  @override
  List<String> getValue(ArgResults? results, {ArgResults? globalResults}) =>
      getParsedValue(results, globalResults: globalResults) ?? const <String>[];
}
