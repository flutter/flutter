// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Creates a new [Option].
///
/// Since [Option] doesn't have a public constructor, this lets `ArgParser`
/// get to it. This function isn't exported to the public API of the package.
Option newOption(
    String name,
    String? abbr,
    String? help,
    String? valueHelp,
    Iterable<String>? allowed,
    Map<String, String>? allowedHelp,
    defaultsTo,
    Function? callback,
    OptionType type,
    {bool? negatable,
    bool? splitCommas,
    bool mandatory = false,
    bool hide = false,
    List<String> aliases = const []}) {
  return Option._(name, abbr, help, valueHelp, allowed, allowedHelp, defaultsTo,
      callback, type,
      negatable: negatable,
      splitCommas: splitCommas,
      mandatory: mandatory,
      hide: hide,
      aliases: aliases);
}

/// A command-line option.
///
/// This represents both boolean flags and options which take a value.
class Option {
  /// The name of the option that the user passes as an argument.
  final String name;

  /// A single-character string that can be used as a shorthand for this option.
  ///
  /// For example, `abbr: "a"` will allow the user to pass `-a value` or
  /// `-avalue`.
  final String? abbr;

  /// A description of this option.
  final String? help;

  /// A name for the value this option takes.
  final String? valueHelp;

  /// A list of valid values for this option.
  final List<String>? allowed;

  /// A map from values in [allowed] to documentation for those values.
  final Map<String, String>? allowedHelp;

  /// The value this option will have if the user doesn't explicitly pass it.
  final dynamic defaultsTo;

  /// Whether this flag's value can be set to `false`.
  ///
  /// For example, if [name] is `flag`, the user can pass `--no-flag` to set its
  /// value to `false`.
  ///
  /// This is `null` unless [type] is [OptionType.flag].
  final bool? negatable;

  /// The callback to invoke with the option's value when the option is parsed.
  final Function? callback;

  /// Whether this is a flag, a single value option, or a multi-value option.
  final OptionType type;

  /// Whether multiple values may be passed by writing `--option a,b` in
  /// addition to `--option a --option b`.
  final bool splitCommas;

  /// Whether this option must be provided for correct usage.
  final bool mandatory;

  /// Whether this option should be hidden from usage documentation.
  final bool hide;

  /// All aliases for [name].
  final List<String> aliases;

  /// Whether the option is boolean-valued flag.
  bool get isFlag => type == OptionType.flag;

  /// Whether the option takes a single value.
  bool get isSingle => type == OptionType.single;

  /// Whether the option allows multiple values.
  bool get isMultiple => type == OptionType.multiple;

  Option._(
      this.name,
      this.abbr,
      this.help,
      this.valueHelp,
      Iterable<String>? allowed,
      Map<String, String>? allowedHelp,
      this.defaultsTo,
      this.callback,
      this.type,
      {this.negatable,
      bool? splitCommas,
      this.mandatory = false,
      this.hide = false,
      this.aliases = const []})
      : allowed = allowed == null ? null : List.unmodifiable(allowed),
        allowedHelp =
            allowedHelp == null ? null : Map.unmodifiable(allowedHelp),
        // If the user doesn't specify [splitCommas], it defaults to true for
        // multiple options.
        splitCommas = splitCommas ?? type == OptionType.multiple {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    } else if (name.startsWith('-')) {
      throw ArgumentError('Name $name cannot start with "-".');
    }

    // Ensure name does not contain any invalid characters.
    if (_invalidChars.hasMatch(name)) {
      throw ArgumentError('Name "$name" contains invalid characters.');
    }

    var abbr = this.abbr;
    if (abbr != null) {
      if (abbr.length != 1) {
        throw ArgumentError('Abbreviation must be null or have length 1.');
      } else if (abbr == '-') {
        throw ArgumentError('Abbreviation cannot be "-".');
      }

      if (_invalidChars.hasMatch(abbr)) {
        throw ArgumentError('Abbreviation is an invalid character.');
      }
    }
  }

  /// Returns [value] if non-`null`, otherwise returns the default value for
  /// this option.
  ///
  /// For single-valued options, it will be [defaultsTo] if set or `null`
  /// otherwise. For multiple-valued options, it will be an empty list or a
  /// list containing [defaultsTo] if set.
  dynamic valueOrDefault(value) {
    if (value != null) return value;
    if (isMultiple) return defaultsTo ?? <String>[];
    return defaultsTo;
  }

  @Deprecated('Use valueOrDefault instead.')
  dynamic getOrDefault(value) => valueOrDefault(value);

  static final _invalidChars = RegExp(r'''[ \t\r\n"'\\/]''');
}

/// What kinds of values an option accepts.
class OptionType {
  /// An option that can only be `true` or `false`.
  ///
  /// The presence of the option name itself in the argument list means `true`.
  static const flag = OptionType._('OptionType.flag');

  /// An option that takes a single value.
  ///
  /// Examples:
  ///
  ///     --mode debug
  ///     -mdebug
  ///     --mode=debug
  ///
  /// If the option is passed more than once, the last one wins.
  static const single = OptionType._('OptionType.single');

  /// An option that allows multiple values.
  ///
  /// Example:
  ///
  ///     --output text --output xml
  ///
  /// In the parsed `ArgResults`, a multiple-valued option will always return
  /// a list, even if one or no values were passed.
  static const multiple = OptionType._('OptionType.multiple');

  final String name;

  const OptionType._(this.name);
}
