// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `MessageFormat` is a "locale aware printf", with plural / gender support.
///
/// `MessageFormat` prepares strings for display to users, with optional
/// arguments (variables/placeholders). The arguments can occur in any order,
/// which is necessary for translation into languages with different grammars.
/// It supports syntax to represent plurals and select options.
library message_format;

import 'dart:collection';
import 'intl.dart';

/// **MessageFormat grammar:**
/// ```
/// message := messageText (argument messageText)*
/// argument := simpleArg | pluralArg | selectArg
///
/// simpleArg := "#" | "{" argNameOrNumber "}"
/// pluralArg := "{" argNameOrNumber "," "plural" "," pluralStyle "}"
/// selectArg := "{" argNameOrNumber "," "select" "," selectStyle "}"
///
/// argNameOrNumber := identifier | number
///
/// pluralStyle := [offsetValue] (pluralSelector "{" message "}")+
/// offsetValue := "offset:" number
/// pluralSelector := explicitValue | pluralKeyword
/// explicitValue := "=" number  // adjacent, no white space in between
/// pluralKeyword := "zero" | "one" | "two" | "few" | "many" | "other"
///
/// selectStyle := (selectSelector "{" message "}")+
/// selectSelector := keyword
///
/// identifier := [^[[:Pattern_Syntax:][:Pattern_White_Space:]]]+
/// number := "0" | ("1".."9" ("0".."9")*)
/// ```
///
/// **NOTE:** "#" has special meaning only inside a plural block.
/// It is "connected" to the argument of the plural, but the value of #
/// is the value of the plural argument minus the offset.
///
/// **Quoting/Escaping:** if syntax characters occur in the text portions,
/// then they need to be quoted by enclosing the syntax in pairs of ASCII
/// apostrophes.
///
/// A pair of ASCII apostrophes always represents one ASCII apostrophe,
/// similar to %% in printf representing one %, although this rule still
/// applies inside quoted text.
///
/// ("This '{isn''t}' obvious" → "This {isn't} obvious")
///
/// An ASCII apostrophe only starts quoted text if it immediately precedes
/// a character that requires quoting (that is, "only where needed"), and
/// works the same in nested messages as on the top level of the pattern.
///
/// **Recommendation:** Use the real apostrophe (single quote) character ’
/// (U+2019) for human-readable text, and use the ASCII apostrophe ' (U+0027)
/// only in program syntax, like escaping.
///
/// This is a subset of the ICU MessageFormat syntax:
///   http://userguide.icu-project.org/formatparse/messages.
///
/// **Message example:**
/// ```
/// I see {NUM_PEOPLE, plural, offset:1
///         =0 {no one at all}
///         =1 {{WHO}}
///         one {{WHO} and one other person}
///         other {{WHO} and # other people}}
/// in {PLACE}.
/// ```
///
/// Calling `format({'NUM_PEOPLE': 2, 'WHO': 'Mark', 'PLACE': 'Athens'})` would
/// produce `"I see Mark and one other person in Athens."` as output.
///
/// Calling `format({'NUM_PEOPLE': 5, 'WHO': 'Mark', 'PLACE': 'Athens'})` would
/// produce `"I see Mark and one 4 other people in Athens."` as output.
/// Notice how the "#" is the value of `NUM_PEOPLE` - 1 (the offset).
///
/// Another important thing to notice is the existence of both `"=1"` and
/// `"one"`. You should think of the plural keywords as names for "buckets of
/// numbers" which have only a loose connection to the numerical value.
///
/// In English there is no difference, but for example in Russian all the
/// numbers that end with `"1"` but not with `"11"` are mapped to `"one"`
///
/// For more information please visit:
/// http://cldr.unicode.org/index/cldr-spec/plural-rules and
/// http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html

// The implementation is based on the
// [Closure goog.i18n.MessageFormat](https://google.github.io/closure-library/api/goog.i18n.MessageFormat.html)
// sources at https://github.com/google/closure-library/blob/master/closure/goog/i18n/messageformat.js,
// so we should try to keep potential fixes in sync.
//
// The initial parsing done by [_extractParts] breaks the pattern into top
// level strings and {...} blocks [_ElementTypeAndVal]
//
// The values are all strings, but the ones that contain curly brackets
// are classified as `blocks` and will be parsed again (recursively)
//
// The second round of parsing takes the parts from above and refines them
// into _BlockTypeAndVal. After this point we have different types of blocks
// (string, plural, ordinal, select, ...)

class MessageFormat {
  /// The locale to use for plural, ordinal, decisions,
  /// number / date / time formatting
  final String _locale;

  /// The pattern we parse and apply positional parameters to.
  String? _pattern;

  /// All encountered literals during parse stage.
  Queue<String>? _initialLiterals;

  /// Working list with all encountered literals during parse and format stages.
  Queue<String>? _literals;

  /// Input pattern gets parsed into objects for faster formatting.
  Queue<_BlockTypeAndVal>? _parsedPattern;

  /// Locale aware number formatter.
  final NumberFormat _numberFormat;

  /// Literal strings, including '', are replaced with \uFDDF_x_ for parsing.
  ///
  /// They are recovered during format phase.
  /// \uFDDF is a Unicode nonprinting character, not expected to be found in the
  /// typical message.
  static const String _literalPlaceholder = '\uFDDF_';

  /// Mandatory option in both select and plural form.
  static const String _other = 'other';

  /// Regular expression for looking for string literals.
  static final RegExp _regexLiteral = RegExp("'([{}#].*?)'");

  /// Regular expression for looking for '' in the message.
  static final RegExp _regexDoubleApostrophe = RegExp("''");

  /// Create a MessageFormat for the ICU message string [pattern].
  /// It does parameter substitutions in a locale-aware way.
  /// The syntax is similar to the one used by ICU and is described in the
  /// grammar above.
  MessageFormat(String pattern, {String locale = 'en'})
      : _locale = locale,
        _pattern = pattern,
        _numberFormat = NumberFormat.decimalPattern(locale);

  /// Returns a formatted message, treating '#' as a special placeholder.
  ///
  /// It represents the number (plural_variable - offset).
  ///
  /// The [namedParameters] either influence the formatting or are used as
  /// actual data.
  /// I.e. in call to `fmt.format({'NUM_PEOPLE': 5, 'NAME': 'Angela'})`, the
  /// map `{'NUM_PEOPLE': 5, 'NAME': 'Angela'}` holds parameters.
  /// `NUM_PEOPLE` parameter could mean 5 people, which could influence plural
  /// format, and `NAME` parameter is just a data to be printed out in proper
  /// position.
  String format([Map<String, Object>? namedParameters]) {
    return _format(false, namedParameters);
  }

  /// Returns a formatted message, treating '#' as literal character.
  ///
  /// The [namedParameters] either influence the formatting or are used as
  /// actual data.
  /// I.e. in call to `fmt.format({'NUM_PEOPLE': 5, 'NAME': 'Angela'})`, the
  /// map `{'NUM_PEOPLE': 5, 'NAME': 'Angela'}` holds positional parameters.
  /// `NUM_PEOPLE` parameter could mean 5 people, which could influence plural
  /// format, and `NAME` parameter is just a data to be printed out in proper
  /// position.
  String formatIgnoringPound([Map<String, Object>? namedParameters]) {
    return _format(true, namedParameters);
  }

  /// Returns a formatted message.
  ///
  /// The [namedParameters] either influence the formatting or are used as
  /// actual data.
  /// I.e. in call to `fmt.format({'NUM_PEOPLE': 5, 'NAME': 'Angela'})`, the
  /// map `{'NUM_PEOPLE': 5, 'NAME': 'Angela'}` holds positional parameters.
  /// `NUM_PEOPLE` parameter could mean 5 people, which could influence plural
  /// format, and `NAME` parameter is just a data to be printed out in proper
  /// position.
  /// If [ignorePound] is true, treat '#' in plural messages as a
  /// literal character, else treat it as an ICU syntax character, resolving
  /// to the number (plural_variable - offset).
  String _format(bool ignorePound, [Map<String, Object>? namedParameters]) {
    _init();
    if (_parsedPattern == null || _parsedPattern!.isEmpty) {
      return '';
    }
    // Clone, we don't want to damage the original
    _literals = Queue<String>()..addAll(_initialLiterals!);

    // Implementation notes: this seems inefficient, we could in theory do the
    // replace + join in one go.
    // But would make the code even more unreadable than it is.
    //
    // `_formatBlock` replaces "full blocks"
    // For example replaces this:
    //   `... {count, plural, =1 {one file} few {...} many {...} other {# files} ...`
    // with
    //    `... one file ...`
    //
    // The replace after that (with `message.replaceFirst`) is only replacing
    // simple parameters (`...{expDate} ... {count}...`)
    //
    // So `_formatBlock` is ugly, potentially recursive.
    // `message.replaceFirst` is very simple, flat.
    //
    // I agree that there might be some performance loss.
    // But in real use the messages don't have that many arguments.
    // If we think printf, how many arguments are common?
    // Probably less than 5 or so.
    var messageParts = Queue<String>();
    _formatBlock(_parsedPattern!, namedParameters!, ignorePound, messageParts);
    var message = messageParts.join('');

    if (!ignorePound) {
      _checkAndThrow(!message.contains('#'), 'Not all # were replaced.');
    }

    while (_literals!.isNotEmpty) {
      message = message.replaceFirst(
          _buildPlaceholder(_literals!), _literals!.removeLast());
    }

    return message;
  }

  /// Takes the parsed tree and the parameters, appending to result.
  ///
  /// The [parsedBlocks] parameter holds parsed tree.
  /// [namedParameters] are parameters that either influence the formatting
  /// or are used as actual data.
  /// If [ignorePound] is true, treat '#' in plural messages as a
  /// literal character, else treat it as an ICU syntax character, resolving
  /// to the number (plural_variable - offset).
  /// Each formatting stage appends its product to the [result].
  /// It can be recursive, as plural / select contain full message patterns.
  void _formatBlock(
      Queue<_BlockTypeAndVal> parsedBlocks,
      Map<String, Object> namedParameters,
      bool ignorePound,
      Queue<String> result) {
    for (var currentPattern in parsedBlocks) {
      var patternValue = currentPattern._value;
      var patternType = currentPattern._type;

      _checkAndThrow(patternType is _BlockType,
          'The type should be a block type: $patternType');
      switch (patternType) {
        case _BlockType.string:
          result.add(patternValue as String);
          break;
        case _BlockType.simple:
          _formatSimplePlaceholder(
              patternValue as String, namedParameters, result);
          break;
        case _BlockType.select:
          _checkAndThrow(patternValue is Map<String, Object>,
              'The value should be a map: $patternValue');
          var mapPattern = patternValue as Map<String, Object>;
          _formatSelectBlock(mapPattern, namedParameters, ignorePound, result);
          break;
        case _BlockType.plural:
          _formatPluralOrdinalBlock(patternValue as Map<String, Object>,
              namedParameters, _PluralRules.select, ignorePound, result);
          break;
        case _BlockType.ordinal:
          _formatPluralOrdinalBlock(patternValue as Map<String, Object>,
              namedParameters, _OrdinalRules.select, ignorePound, result);
          break;
        default:
          _checkAndThrow(false, 'Unrecognized block type: $patternType');
      }
    }
  }

  /// Formats a simple placeholder.
  ///
  /// [parsedBlocks] is an object containing placeholder info.
  /// The [namedParameters] that are used as actual data.
  /// Each formatting stage appends its product to the [result].
  void _formatSimplePlaceholder(String parsedBlocks,
      Map<String, Object> namedParameters, Queue<String> result) {
    var value = namedParameters[parsedBlocks];
    if (!_isDef(value)) {
      result.add('Undefined parameter - $parsedBlocks');
      return;
    }

    // Don't push the value yet, it may contain any of # { } in it which
    // will break formatter. Insert a placeholder and replace at the end.
    String strValue;
    if (value is int) {
      strValue = _numberFormat.format(value);
    } else if (value is String) {
      strValue = value;
    } else {
      strValue = value.toString();
    }
    _literals!.add(strValue);
    result.add(_buildPlaceholder(_literals!));
  }

  /// Formats select block. Only one option is selected.
  ///
  /// [parsedBlocks] is an object containing select block info.
  /// [namedParameters] are parameters that either influence the formatting
  /// or are used as actual data.
  /// If [ignorePound] is true, treat '#' in plural messages as a
  /// literal character, else treat it as an ICU syntax character, resolving
  /// to the number (plural_variable - offset).
  /// Each formatting stage appends its product to the [result].
  void _formatSelectBlock(
      Map<String, Object> parsedBlocks,
      Map<String, Object> namedParameters,
      bool ignorePound,
      Queue<String> result) {
    var argumentName = parsedBlocks['argumentName'];
    if (!_isDef(namedParameters[argumentName])) {
      result.add('Undefined parameter - $argumentName');
      return;
    }

    var option =
        parsedBlocks[namedParameters[argumentName]] as Queue<_BlockTypeAndVal>?;
    if (!_isDef(option)) {
      option = parsedBlocks[_other] as Queue<_BlockTypeAndVal>?;
      _checkAndThrow(option != null,
          'Invalid option or missing other option for select block.');
    }

    _formatBlock(option!, namedParameters, ignorePound, result);
  }

  /// Formats `plural` / `selectordinal` block, selects an option, replaces `#`
  ///
  /// [parsedBlocks] is an object containing plural block info.
  /// [namedParameters] are parameters that either influence the formatting
  /// or are used as actual data.
  /// The [pluralSelector] is a select function from pluralRules or ordinalRules
  /// which determines which plural/ordinal form to use based on the input
  /// number's cardinality.
  /// If [ignorePound] is true, treat '#' in plural messages as a
  /// literal character, else treat it as an ICU syntax character, resolving
  /// to the number (plural_variable - offset).
  /// Each formatting stage appends its product to the [result].
  void _formatPluralOrdinalBlock(
      Map<String, Object> parsedBlocks,
      var namedParameters,
      Function(num, String) pluralSelector,
      bool ignorePound,
      Queue<String> result) {
    var argumentName = parsedBlocks['argumentName'];
    var argumentOffset = parsedBlocks['argumentOffset'];
    var pluralValue = namedParameters[argumentName];

    if (!_isDef(pluralValue)) {
      result.add('Undefined parameter - $argumentName');
      return;
    }

    var numPluralValue =
        pluralValue is num ? pluralValue : double.tryParse(pluralValue);
    if (numPluralValue == null) {
      result.add('Invalid parameter - $argumentName');
      return;
    }

    var numArgumentOffset = argumentOffset is num
        ? argumentOffset
        : double.tryParse(argumentOffset as String);
    if (numArgumentOffset == null) {
      result.add('Invalid offset - $argumentOffset');
      return;
    }

    var diff = numPluralValue - numArgumentOffset;

    // Check if there is an exact match.
    var option =
        parsedBlocks[namedParameters[argumentName]] as Queue<_BlockTypeAndVal>?;
    if (!_isDef(option)) {
      option = parsedBlocks[namedParameters[argumentName].toString()]
          as Queue<_BlockTypeAndVal>?;
    }
    if (!_isDef(option)) {
      var item = pluralSelector(diff.abs(), _locale);
      _checkAndThrow(item is String, 'Invalid plural key.');

      option = parsedBlocks[item] as Queue<_BlockTypeAndVal>?;

      // If option is not provided fall back to "other".
      if (!_isDef(option)) {
        option = parsedBlocks[_other] as Queue<_BlockTypeAndVal>?;
      }

      _checkAndThrow(option != null,
          'Invalid option or missing other option for plural block.');
    }

    var pluralResult = Queue<String>();
    _formatBlock(option!, namedParameters, ignorePound, pluralResult);
    var plural = pluralResult.join('');
    _checkAndThrow(plural is String, 'Empty block in plural.');
    if (ignorePound) {
      result.add(plural);
    } else {
      var localeAwareDiff = _numberFormat.format(diff);
      result.add(plural.replaceAll('#', localeAwareDiff));
    }
  }

  /// Set up the MessageFormat.
  ///
  /// Parses input pattern into an array, for faster reformatting with
  /// different input parameters.
  /// Parsing is locale independent.
  void _init() {
    if (_pattern != null) {
      _initialLiterals = Queue<String>();
      var pattern = _insertPlaceholders(_pattern!);

      _parsedPattern = _parseBlock(pattern);
      _pattern = null;
    }
  }

  /// Replaces string literals with literal placeholders in [pattern].
  ///
  /// Literals are string of the form '}...', '{...' and '#...' where ... is
  /// set of characters not containing '
  /// Builds a dictionary so we can recover literals during format phase.
  String _insertPlaceholders(String pattern) {
    var literals = _initialLiterals!;
    var buildPlaceholder = _buildPlaceholder;

    // First replace '' with single quote placeholder since they can be found
    // inside other literals.
    pattern = pattern.replaceAllMapped(_regexDoubleApostrophe, (match) {
      literals.add("'");
      return buildPlaceholder(literals);
    });

    pattern = pattern.replaceAllMapped(_regexLiteral, (match) {
      // match, text
      var text = match.group(1)!;
      literals.add(text);
      return buildPlaceholder(literals);
    });

    return pattern;
  }

  /// Breaks [pattern] into strings and top level {...} blocks.
  Queue<_ElementTypeAndVal> _extractParts(String pattern) {
    var prevPos = 0;
    var braceStack = Queue<String>();
    var results = Queue<_ElementTypeAndVal>();

    var braces = RegExp('[{}]');

    Match match;
    for (match in braces.allMatches(pattern)) {
      var pos = match.start;
      if (match[0] == '}') {
        String? brace;
        try {
          brace = braceStack.removeLast();
        } on StateError {
          _checkAndThrow(brace != '}', 'No matching } for {.');
        }
        _checkAndThrow(brace == '{', 'No matching { for }.');

        if (braceStack.isEmpty) {
          // End of the block.
          var part = _ElementTypeAndVal(
              _ElementType.block, pattern.substring(prevPos, pos));
          results.add(part);
          prevPos = pos + 1;
        }
      } else {
        if (braceStack.isEmpty) {
          var substring = pattern.substring(prevPos, pos);
          if (substring != '') {
            results.add(_ElementTypeAndVal(_ElementType.string, substring));
          }
          prevPos = pos + 1;
        }
        braceStack.add('{');
      }
    }

    // Take care of the final string, and check if the braceStack is empty.
    _checkAndThrow(
        braceStack.isEmpty, 'There are mismatched { or } in the pattern.');

    var substring = pattern.substring(prevPos);
    if (substring != '') {
      results.add(_ElementTypeAndVal(_ElementType.string, substring));
    }

    return results;
  }

  /// A regular expression to parse the plural block.
  ///
  /// It extracts the argument index and offset (if any).
  static final RegExp _pluralBlockRe =
      RegExp('^\\s*(\\w+)\\s*,\\s*plural\\s*,(?:\\s*offset:(\\d+))?');

  /// A regular expression to parse the ordinal block.
  ///
  /// It extracts the argument index.
  static final RegExp _ordinalBlockRe =
      RegExp('^\\s*(\\w+)\\s*,\\s*selectordinal\\s*,');

  /// A regular expression to parse the select block.
  ///
  /// It extracts the argument index.
  static final RegExp _selectBlockRe =
      RegExp('^\\s*(\\w+)\\s*,\\s*select\\s*,');

  /// Detects the block type of the [pattern].
  _BlockType _parseBlockType(String pattern) {
    if (_pluralBlockRe.hasMatch(pattern)) {
      return _BlockType.plural;
    }

    if (_ordinalBlockRe.hasMatch(pattern)) {
      return _BlockType.ordinal;
    }

    if (_selectBlockRe.hasMatch(pattern)) {
      return _BlockType.select;
    }

    if (RegExp('^\\s*\\w+\\s*').hasMatch(pattern)) {
      return _BlockType.simple;
    }

    return _BlockType.unknown;
  }

  /// Parses generic block.
  ///
  /// Takes the [pattern], which is the content of the block to parse,
  /// and returns sub-blocks marked as strings, select, plural, ...
  Queue<_BlockTypeAndVal> _parseBlock(String pattern) {
    var result = Queue<_BlockTypeAndVal>();
    var parts = _extractParts(pattern);
    for (var thePart in parts) {
      _BlockTypeAndVal? block;
      if (_ElementType.string == thePart._type) {
        block = _BlockTypeAndVal(_BlockType.string, thePart._value);
      } else if (_ElementType.block == thePart._type) {
        _checkAndThrow(thePart._value is String,
            'The value should be a string: ${thePart._value}');
        var blockType = _parseBlockType(thePart._value);

        switch (blockType) {
          case _BlockType.select:
            block = _BlockTypeAndVal(
                _BlockType.select, _parseSelectBlock(thePart._value));
            break;
          case _BlockType.plural:
            block = _BlockTypeAndVal(
                _BlockType.plural, _parsePluralBlock(thePart._value));
            break;
          case _BlockType.ordinal:
            block = _BlockTypeAndVal(
                _BlockType.ordinal, _parseOrdinalBlock(thePart._value));
            break;
          case _BlockType.simple:
            block = _BlockTypeAndVal(_BlockType.simple, thePart._value);
            break;
          default:
            _checkAndThrow(
                false, 'Unknown block type for pattern: ${thePart._value}');
        }
      } else {
        _checkAndThrow(false, 'Unknown part of the pattern.');
      }
      result.add(block!);
    }

    return result;
  }

  /// Parses a select type of a block and produces an object for it.
  ///
  /// The [pattern] is the  sub-pattern that needs to be parsed as select,
  /// and returns an object with select block info.
  Map<String, Object> _parseSelectBlock(String pattern) {
    var argumentName = '';
    var replaceRegex = _selectBlockRe;
    pattern = pattern.replaceFirstMapped(replaceRegex, (match) {
      // string, name
      argumentName = match.group(1)!;
      return '';
    });
    var result = <String, Object>{'argumentName': argumentName};

    var parts = _extractParts(pattern);
    // Looking for (key block)+ sequence. One of the keys has to be "other".
    var pos = 0;
    while (pos < parts.length) {
      var thePart = parts.elementAt(pos);
      _checkAndThrow(thePart._value is String, 'Missing select key element.');
      var key = thePart._value;

      pos++;
      _checkAndThrow(
          pos < parts.length, 'Missing or invalid select value element.');
      thePart = parts.elementAt(pos);

      Queue<_BlockTypeAndVal>? value;
      if (_ElementType.block == thePart._type) {
        value = _parseBlock(thePart._value);
      } else {
        _checkAndThrow(false, 'Expected block type.');
      }
      result[key.replaceAll(RegExp('\\s'), '')] = value!;
      pos++;
    }

    _checkAndThrow(
        result.containsKey(_other), 'Missing other key in select statement.');
    return result;
  }

  /// Parses a plural type of a block and produces an object for it.
  ///
  /// The [pattern] is the sub-pattern that needs to be parsed as plural.
  /// and returns an bject with plural block info.
  Map<String, Object> _parsePluralBlock(String pattern) {
    var argumentName = '';
    var argumentOffset = 0;
    var replaceRegex = _pluralBlockRe;
    pattern = pattern.replaceFirstMapped(replaceRegex, (match) {
      // string, name, offset
      argumentName = match.group(1)!;
      if (_isDef(match.group(2))) {
        argumentOffset = int.parse(match.group(2)!);
      }
      return '';
    });

    var result = {
      'argumentName': argumentName,
      'argumentOffset': argumentOffset
    };

    var parts = _extractParts(pattern);
    // Looking for (key block)+ sequence.
    var pos = 0;
    while (pos < parts.length) {
      var thePart = parts.elementAt(pos);
      _checkAndThrow(thePart._value is String, 'Missing plural key element.');
      var key = thePart._value;

      pos++;
      _checkAndThrow(
          pos < parts.length, 'Missing or invalid plural value element.');
      thePart = parts.elementAt(pos);

      Queue<_BlockTypeAndVal>? value;
      if (_ElementType.block == thePart._type) {
        value = _parseBlock(thePart._value);
      } else {
        _checkAndThrow(false, 'Expected block type.');
      }
      key = key.replaceFirstMapped(RegExp('\\s*(?:=)?(\\w+)\\s*'), (match) {
        return match.group(1).toString();
      });
      result[key] = value!;
      pos++;
    }

    _checkAndThrow(
        result.containsKey(_other), 'Missing other key in plural statement.');

    return result;
  }

  /// Parses an ordinal type of a block and produces an object for it.
  ///
  /// For example the input string:
  ///  `{FOO, selectordinal, one {Message A}other {Message B}}`
  /// Should result in the output object:
  /// ```
  /// {
  ///   argumentName: 'FOO',
  ///   argumentOffest: 0,
  ///   one: [ { type: 4, value: 'Message A' } ],
  ///   other: [ { type: 4, value: 'Message B' } ]
  /// }
  /// ```
  /// The [pattern] is the sub-pattern that needs to be parsed as ordinal,
  /// and returns an bject with ordinal block info.
  Map<String, Object> _parseOrdinalBlock(String pattern) {
    var argumentName = '';
    var replaceRegex = _ordinalBlockRe;
    pattern = pattern.replaceFirstMapped(replaceRegex, (match) {
      // string, name
      argumentName = match.group(1)!;
      return '';
    });

    var result = {'argumentName': argumentName, 'argumentOffset': 0};

    var parts = _extractParts(pattern);
    // Looking for (key block)+ sequence.
    var pos = 0;
    while (pos < parts.length) {
      var thePart = parts.elementAt(pos);
      _checkAndThrow(thePart._value is String, 'Missing ordinal key element.');
      var key = thePart._value;

      pos++;
      _checkAndThrow(
          pos < parts.length, 'Missing or invalid ordinal value element.');
      thePart = parts.elementAt(pos);

      Queue<_BlockTypeAndVal>? value;
      if (_ElementType.block == thePart._type) {
        value = _parseBlock(thePart._value);
      } else {
        _checkAndThrow(false, 'Expected block type.');
      }
      key = key.replaceFirstMapped(RegExp('\\s*(?:=)?(\\w+)\\s*'), (match) {
        return match.group(1).toString();
      });
      result[key] = value!;
      pos++;
    }

    _checkAndThrow(result.containsKey(_other),
        'Missing other key in selectordinal statement.');

    return result;
  }

  /// Builds a placeholder from the last index of the array.
  ///
  /// using all the [literals] encountered during parse.
  /// It returns a string that looks like this: `"\uFDDF_" + last index + "_"`.
  String _buildPlaceholder(Queue<String> literals) {
    _checkAndThrow(literals.isNotEmpty, 'Literal array is empty.');

    var index = (literals.length - 1).toString();
    return '$_literalPlaceholder${index}_';
  }
}

//========== EXTRAS: temporary, to help the move from JS to Dart ==========

// Simple goog.isDef replacement, will probably remove it
bool _isDef(Object? obj) {
  return obj != null;
}

// Closure calls assert, which actually ends up with an exception on can catch.
// In Dart assert is only for debug, so I am using this small wrapper method.
void _checkAndThrow(bool condition, String message) {
  if (!condition) {
    throw AssertionError(message);
  }
}

// Dart has no support for ordinals
// TODO(b/142132665): add ordial rules to intl, then fix this
class _OrdinalRules {
  static String select(num n, String locale) {
    return _PluralRules.select(n, locale);
  }
}

// Simple mapping from Intl.pluralLogic to _PluralRules, to change later
class _PluralRules {
  static String select(num n, String locale) {
    return Intl.pluralLogic(n,
        zero: 'zero',
        one: 'one',
        two: 'two',
        few: 'few',
        many: 'many',
        other: 'other',
        locale: locale);
  }
}

// Pairs a value and information about its type.
class _TypeAndVal<T, V> {
  final T _type;
  final V _value;

  _TypeAndVal(var this._type, var this._value);

  @override
  String toString() {
    return '{type:$_type, value:$_value}';
  }
}

/// Marks a string and block during parsing.
enum _ElementType { string, block }

class _ElementTypeAndVal extends _TypeAndVal<_ElementType, String> {
  _ElementTypeAndVal(var _type, var _value) : super(_type, _value);
}

/// Block type.
enum _BlockType { plural, ordinal, select, simple, string, unknown }

class _BlockTypeAndVal extends _TypeAndVal<_BlockType, Object> {
  _BlockTypeAndVal(var _type, var _value) : super(_type, _value);
}
