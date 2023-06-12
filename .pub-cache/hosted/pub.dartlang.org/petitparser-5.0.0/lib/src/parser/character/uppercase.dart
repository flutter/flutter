import '../../core/parser.dart';
import 'parser.dart';
import 'predicate.dart';

/// Returns a parser that accepts any uppercase character. The accepted input is
/// equivalent to the character-set `A-Z`.
Parser<String> uppercase([String message = 'uppercase letter expected']) =>
    CharacterParser(const UppercaseCharPredicate(), message);

class UppercaseCharPredicate implements CharacterPredicate {
  const UppercaseCharPredicate();

  @override
  bool test(int value) => 65 <= value && value <= 90;

  @override
  bool isEqualTo(CharacterPredicate other) => other is UppercaseCharPredicate;
}
