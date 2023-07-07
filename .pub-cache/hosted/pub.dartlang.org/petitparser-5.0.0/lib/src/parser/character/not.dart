import 'predicate.dart';

/// Negates the result of a character predicate.
class NotCharacterPredicate extends CharacterPredicate {
  const NotCharacterPredicate(this.predicate);

  final CharacterPredicate predicate;

  @override
  bool test(int value) => !predicate.test(value);

  @override
  bool isEqualTo(CharacterPredicate other) =>
      other is NotCharacterPredicate &&
      other.predicate.isEqualTo(other.predicate);
}
