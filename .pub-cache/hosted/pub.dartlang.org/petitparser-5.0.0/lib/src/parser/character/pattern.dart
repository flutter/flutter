import '../../core/parser.dart';
import '../action/map.dart';
import '../combinator/choice.dart';
import '../combinator/optional.dart';
import '../combinator/sequence.dart';
import '../predicate/any.dart';
import '../repeater/possessive.dart';
import 'char.dart';
import 'code.dart';
import 'not.dart';
import 'optimize.dart';
import 'parser.dart';
import 'predicate.dart';
import 'range.dart';

/// Returns a parser that accepts a single character of a given character set
/// provided as a string.
///
/// Characters match themselves. A dash `-` between two characters matches the
/// range of those characters. A caret `^` at the beginning negates the pattern.
///
/// For example, the parser `pattern('aou')` accepts the character 'a', 'o', or
/// 'u', and fails for any other input. The parser `pattern('1-3')` accepts
/// either '1', '2', or '3'; and fails for any other character. The parser
/// `pattern('^aou') accepts any character, but fails for the characters 'a',
/// 'o', or 'u'.
Parser<String> pattern(String element, [String? message]) => CharacterParser(
    _pattern.parse(element).value,
    message ?? '[${toReadableString(element)}] expected');

/// Returns a parser that accepts a single character of a given case-insensitive
/// character set provided as a string.
///
/// Characters match themselves. A dash `-` between two characters matches the
/// range of those characters. A caret `^` at the beginning negates the pattern.
///
/// For example, the parser `patternIgnoreCase('aoU')` accepts the character
/// 'a', 'o', 'u' and 'A', 'O', 'U', and fails for any other input. The parser
/// `patternIgnoreCase('a-c')` accepts 'a', 'b', 'c' and 'A', 'B', 'C'; and
/// fails for any other character. The parser `patternIgnoreCase('^A') accepts
/// any character, but fails for the characters 'a' or 'A'.
Parser<String> patternIgnoreCase(String element, [String? message]) {
  var normalized = element;
  final isNegated = normalized.startsWith('^');
  if (isNegated) {
    normalized = normalized.substring(1);
  }
  final isDashed = normalized.endsWith('-');
  if (isDashed) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return pattern(
      '${isNegated ? '^' : ''}'
      '${normalized.toLowerCase()}${normalized.toUpperCase()}'
      '${isDashed ? '-' : ''}',
      message ?? '[${toReadableString(element)}] (case-insensitive) expected');
}

/// Parser that reads a single character.
final Parser<RangeCharPredicate> _single =
    any().map((element) => RangeCharPredicate(
          toCharCode(element),
          toCharCode(element),
        ));

/// Parser that reads a character range.
final Parser<RangeCharPredicate> _range =
    any().seq(char('-')).seq(any()).map((elements) => RangeCharPredicate(
          toCharCode(elements[0]),
          toCharCode(elements[2]),
        ));

/// Parser that reads a sequence of single characters or ranges.
final Parser<CharacterPredicate> _sequence = _range.or(_single).star().map(
    (predicates) => optimizedRanges(predicates.cast<RangeCharPredicate>()));

/// Parser that reads a possibly negated sequence of predicates.
final Parser<CharacterPredicate> _pattern = char('^')
    .optional()
    .seq(_sequence)
    .map((predicates) => predicates[0] == null
        ? predicates[1]
        : NotCharacterPredicate(predicates[1]));
