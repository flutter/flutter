import 'predicate.dart';

class ConstantCharPredicate extends CharacterPredicate {
  const ConstantCharPredicate(this.constant);

  final bool constant;

  @override
  bool test(int value) => constant;

  @override
  bool isEqualTo(CharacterPredicate other) =>
      other is ConstantCharPredicate && other.constant == constant;
}
