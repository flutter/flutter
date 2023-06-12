// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'arg_parser.dart';

/// Creates a new [ArgResults].
///
/// Since [ArgResults] doesn't have a public constructor, this lets [ArgParser]
/// get to it. This function isn't exported to the public API of the package.
ArgResults newArgResults(
    ArgParser parser,
    Map<String, dynamic> parsed,
    String? name,
    ArgResults? command,
    List<String> rest,
    List<String> arguments) {
  return ArgResults._(parser, parsed, name, command, rest, arguments);
}

/// The results of parsing a series of command line arguments using
/// [ArgParser.parse()].
///
/// Includes the parsed options and any remaining unparsed command line
/// arguments.
class ArgResults {
  /// The [ArgParser] whose options were parsed for these results.
  final ArgParser _parser;

  /// The option values that were parsed from arguments.
  final Map<String, dynamic> _parsed;

  /// The name of the command for which these options are parsed, or `null` if
  /// these are the top-level results.
  final String? name;

  /// The command that was selected, or `null` if none was.
  ///
  /// This will contain the options that were selected for that command.
  final ArgResults? command;

  /// The remaining command-line arguments that were not parsed as options or
  /// flags.
  ///
  /// If `--` was used to separate the options from the remaining arguments,
  /// it will not be included in this list unless parsing stopped before the
  /// `--` was reached.
  final List<String> rest;

  /// The original arguments that were parsed.
  final List<String> arguments;

  ArgResults._(this._parser, this._parsed, this.name, this.command,
      List<String> rest, List<String> arguments)
      : rest = UnmodifiableListView(rest),
        arguments = UnmodifiableListView(arguments);

  /// Returns the parsed ore default command-line option named [name].
  ///
  /// [name] must be a valid option name in the parser.
  dynamic operator [](String name) {
    if (!_parser.options.containsKey(name)) {
      throw ArgumentError('Could not find an option named "$name".');
    }

    return _parser.options[name]!.valueOrDefault(_parsed[name]);
  }

  /// The names of the available options.
  ///
  /// Includes the options whose values were parsed or that have defaults.
  /// Options that weren't present and have no default are omitted.
  Iterable<String> get options {
    var result = _parsed.keys.toSet();

    // Include the options that have defaults.
    _parser.options.forEach((name, option) {
      if (option.defaultsTo != null) result.add(name);
    });

    return result;
  }

  /// Returns `true` if the option with [name] was parsed from an actual
  /// argument.
  ///
  /// Returns `false` if it wasn't provided and the default value or no default
  /// value would be used instead.
  ///
  /// [name] must be a valid option name in the parser.
  bool wasParsed(String name) {
    if (!_parser.options.containsKey(name)) {
      throw ArgumentError('Could not find an option named "$name".');
    }

    return _parsed.containsKey(name);
  }
}
