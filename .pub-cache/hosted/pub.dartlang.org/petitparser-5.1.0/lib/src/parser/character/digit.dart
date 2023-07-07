import '../../core/parser.dart';
import 'parser.dart';
import 'predicate.dart';

/// Returns a parser that accepts any digit character. The accepted input is
/// equivalent to the character-set `0-9`.
Parser<String> digit([String message = 'digit expected']) =>
    CharacterParser(const DigitCharPredicate(), message);

class DigitCharPredicate extends CharacterPredicate {
  const DigitCharPredicate();

  @override
  bool test(int value) => 48 <= value && value <= 57;

  @override
  bool isEqualTo(CharacterPredicate other) => other is DigitCharPredicate;
}
