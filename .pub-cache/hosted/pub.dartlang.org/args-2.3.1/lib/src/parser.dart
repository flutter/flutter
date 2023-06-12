// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'arg_parser.dart';
import 'arg_parser_exception.dart';
import 'arg_results.dart';
import 'option.dart';

/// The actual argument parsing class.
///
/// Unlike [ArgParser] which is really more an "arg grammar", this is the class
/// that does the parsing and holds the mutable state required during a parse.
class Parser {
  /// If parser is parsing a command's options, this will be the name of the
  /// command. For top-level results, this returns `null`.
  final String? _commandName;

  /// The parser for the supercommand of this command parser, or `null` if this
  /// is the top-level parser.
  final Parser? _parent;

  /// The grammar being parsed.
  final ArgParser _grammar;

  /// The arguments being parsed.
  final Queue<String> _args;

  /// The remaining non-option, non-command arguments.
  final List<String> _rest;

  /// The accumulated parsed options.
  final Map<String, dynamic> _results = <String, dynamic>{};

  Parser(this._commandName, this._grammar, this._args,
      [this._parent, List<String>? rest])
      : _rest = [...?rest];

  /// The current argument being parsed.
  String get _current => _args.first;

  /// Parses the arguments. This can only be called once.
  ArgResults parse() {
    var arguments = _args.toList();
    if (_grammar.allowsAnything) {
      return newArgResults(
          _grammar, const {}, _commandName, null, arguments, arguments);
    }

    ArgResults? commandResults;

    // Parse the args.
    while (_args.isNotEmpty) {
      if (_current == '--') {
        // Reached the argument terminator, so stop here.
        _args.removeFirst();
        break;
      }

      // Try to parse the current argument as a command. This happens before
      // options so that commands can have option-like names.
      var command = _grammar.commands[_current];
      if (command != null) {
        _validate(_rest.isEmpty, 'Cannot specify arguments before a command.');
        var commandName = _args.removeFirst();
        var commandParser = Parser(commandName, command, _args, this, _rest);

        try {
          commandResults = commandParser.parse();
        } on ArgParserException catch (error) {
          throw ArgParserException(
              error.message, [commandName, ...error.commands]);
        }

        // All remaining arguments were passed to command so clear them here.
        _rest.clear();
        break;
      }

      // Try to parse the current argument as an option. Note that the order
      // here matters.
      if (_parseSoloOption()) continue;
      if (_parseAbbreviation(this)) continue;
      if (_parseLongOption()) continue;

      // This argument is neither option nor command, so stop parsing unless
      // the [allowTrailingOptions] option is set.
      if (!_grammar.allowTrailingOptions) break;
      _rest.add(_args.removeFirst());
    }

    // Check if mandatory and invoke existing callbacks.
    _grammar.options.forEach((name, option) {
      var parsedOption = _results[name];

      // Check if an option was mandatory and exist
      // if not throw an exception
      if (option.mandatory && parsedOption == null) {
        throw ArgParserException('Option $name is mandatory.');
      }

      var callback = option.callback;
      if (callback == null) return;
      callback(option.valueOrDefault(parsedOption));
    });

    // Add in the leftover arguments we didn't parse to the innermost command.
    _rest.addAll(_args);
    _args.clear();
    return newArgResults(
        _grammar, _results, _commandName, commandResults, _rest, arguments);
  }

  /// Pulls the value for [option] from the second argument in [_args].
  ///
  /// Validates that there is a valid value there.
  void _readNextArgAsValue(Option option) {
    // Take the option argument from the next command line arg.
    _validate(_args.isNotEmpty, 'Missing argument for "${option.name}".');

    _setOption(_results, option, _current);
    _args.removeFirst();
  }

  /// Tries to parse the current argument as a "solo" option, which is a single
  /// hyphen followed by a single letter.
  ///
  /// We treat this differently than collapsed abbreviations (like "-abc") to
  /// handle the possible value that may follow it.
  bool _parseSoloOption() {
    // Hand coded regexp: r'^-([a-zA-Z0-9])$'
    // Length must be two, hyphen followed by any letter/digit.
    if (_current.length != 2) return false;
    if (!_current.startsWith('-')) return false;
    var opt = _current[1];
    if (!_isLetterOrDigit(opt.codeUnitAt(0))) return false;
    return _handleSoloOption(opt);
  }

  bool _handleSoloOption(String opt) {
    var option = _grammar.findByAbbreviation(opt);
    if (option == null) {
      // Walk up to the parent command if possible.
      _validate(_parent != null, 'Could not find an option or flag "-$opt".');
      return _parent!._handleSoloOption(opt);
    }

    _args.removeFirst();

    if (option.isFlag) {
      _setFlag(_results, option, true);
    } else {
      _readNextArgAsValue(option);
    }

    return true;
  }

  /// Tries to parse the current argument as a series of collapsed abbreviations
  /// (like "-abc") or a single abbreviation with the value directly attached
  /// to it (like "-mrelease").
  bool _parseAbbreviation(Parser innermostCommand) {
    // Hand coded regexp: r'^-([a-zA-Z0-9]+)(.*)$'
    // Hyphen then at least one letter/digit then zero or more
    // anything-but-newlines.
    if (_current.length < 2) return false;
    if (!_current.startsWith('-')) return false;

    // Find where we go from letters/digits to rest.
    var index = 1;
    while (index < _current.length &&
        _isLetterOrDigit(_current.codeUnitAt(index))) {
      ++index;
    }
    // Must be at least one letter/digit.
    if (index == 1) return false;

    // If the first character is the abbreviation for a non-flag option, then
    // the rest is the value.
    var lettersAndDigits = _current.substring(1, index);
    var rest = _current.substring(index);
    if (rest.contains('\n') || rest.contains('\r')) return false;
    return _handleAbbreviation(lettersAndDigits, rest, innermostCommand);
  }

  bool _handleAbbreviation(
      String lettersAndDigits, String rest, Parser innermostCommand) {
    var c = lettersAndDigits.substring(0, 1);
    var first = _grammar.findByAbbreviation(c);
    if (first == null) {
      // Walk up to the parent command if possible.
      _validate(
          _parent != null, 'Could not find an option with short name "-$c".');
      return _parent!
          ._handleAbbreviation(lettersAndDigits, rest, innermostCommand);
    } else if (!first.isFlag) {
      // The first character is a non-flag option, so the rest must be the
      // value.
      var value = '${lettersAndDigits.substring(1)}$rest';
      _setOption(_results, first, value);
    } else {
      // If we got some non-flag characters, then it must be a value, but
      // if we got here, it's a flag, which is wrong.
      _validate(
          rest == '',
          'Option "-$c" is a flag and cannot handle value '
          '"${lettersAndDigits.substring(1)}$rest".');

      // Not an option, so all characters should be flags.
      // We use "innermostCommand" here so that if a parent command parses the
      // *first* letter, subcommands can still be found to parse the other
      // letters.
      for (var i = 0; i < lettersAndDigits.length; i++) {
        var c = lettersAndDigits.substring(i, i + 1);
        innermostCommand._parseShortFlag(c);
      }
    }

    _args.removeFirst();
    return true;
  }

  void _parseShortFlag(String c) {
    var option = _grammar.findByAbbreviation(c);
    if (option == null) {
      // Walk up to the parent command if possible.
      _validate(
          _parent != null, 'Could not find an option with short name "-$c".');
      _parent!._parseShortFlag(c);
      return;
    }

    // In a list of short options, only the first can be a non-flag. If
    // we get here we've checked that already.
    _validate(
        option.isFlag, 'Option "-$c" must be a flag to be in a collapsed "-".');

    _setFlag(_results, option, true);
  }

  /// Tries to parse the current argument as a long-form named option, which
  /// may include a value like "--mode=release" or "--mode release".
  bool _parseLongOption() {
    // Hand coded regexp: r'^--([a-zA-Z\-_0-9]+)(=(.*))?$'
    // Two hyphens then at least one letter/digit/hyphen, optionally an equal
    // sign followed by zero or more anything-but-newlines.

    if (!_current.startsWith('--')) return false;

    var index = _current.indexOf('=');
    var name =
        index == -1 ? _current.substring(2) : _current.substring(2, index);
    for (var i = 0; i != name.length; ++i) {
      if (!_isLetterDigitHyphenOrUnderscore(name.codeUnitAt(i))) return false;
    }
    var value = index == -1 ? null : _current.substring(index + 1);
    if (value != null && (value.contains('\n') || value.contains('\r'))) {
      return false;
    }
    return _handleLongOption(name, value);
  }

  bool _handleLongOption(String name, String? value) {
    var option = _grammar.findByNameOrAlias(name);
    if (option != null) {
      _args.removeFirst();
      if (option.isFlag) {
        _validate(
            value == null, 'Flag option "$name" should not be given a value.');

        _setFlag(_results, option, true);
      } else if (value != null) {
        // We have a value like --foo=bar.
        _setOption(_results, option, value);
      } else {
        // Option like --foo, so look for the value as the next arg.
        _readNextArgAsValue(option);
      }
    } else if (name.startsWith('no-')) {
      // See if it's a negated flag.
      var positiveName = name.substring('no-'.length);
      option = _grammar.findByNameOrAlias(positiveName);
      if (option == null) {
        // Walk up to the parent command if possible.
        _validate(_parent != null, 'Could not find an option named "$name".');
        return _parent!._handleLongOption(name, value);
      }

      _args.removeFirst();
      _validate(option.isFlag, 'Cannot negate non-flag option "$name".');
      _validate(option.negatable!, 'Cannot negate option "$name".');

      _setFlag(_results, option, false);
    } else {
      // Walk up to the parent command if possible.
      _validate(_parent != null, 'Could not find an option named "$name".');
      return _parent!._handleLongOption(name, value);
    }

    return true;
  }

  /// Called during parsing to validate the arguments.
  ///
  /// Throws an [ArgParserException] if [condition] is `false`.
  void _validate(bool condition, String message) {
    if (!condition) throw ArgParserException(message);
  }

  /// Validates and stores [value] as the value for [option], which must not be
  /// a flag.
  void _setOption(Map results, Option option, String value) {
    assert(!option.isFlag);

    if (!option.isMultiple) {
      _validateAllowed(option, value);
      results[option.name] = value;
      return;
    }

    var list = results.putIfAbsent(option.name, () => <String>[]);

    if (option.splitCommas) {
      for (var element in value.split(',')) {
        _validateAllowed(option, element);
        list.add(element);
      }
    } else {
      _validateAllowed(option, value);
      list.add(value);
    }
  }

  /// Validates and stores [value] as the value for [option], which must be a
  /// flag.
  void _setFlag(Map results, Option option, bool value) {
    assert(option.isFlag);
    results[option.name] = value;
  }

  /// Validates that [value] is allowed as a value of [option].
  void _validateAllowed(Option option, String value) {
    if (option.allowed == null) return;

    _validate(option.allowed!.contains(value),
        '"$value" is not an allowed value for option "${option.name}".');
  }
}

bool _isLetterOrDigit(int codeUnit) =>
    // Uppercase letters.
    (codeUnit >= 65 && codeUnit <= 90) ||
    // Lowercase letters.
    (codeUnit >= 97 && codeUnit <= 122) ||
    // Digits.
    (codeUnit >= 48 && codeUnit <= 57);

bool _isLetterDigitHyphenOrUnderscore(int codeUnit) =>
    _isLetterOrDigit(codeUnit) ||
    // Hyphen.
    codeUnit == 45 ||
    // Underscore.
    codeUnit == 95;
