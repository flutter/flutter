import '../../core/parser.dart';
import '../../parser/combinator/optional.dart';
import '../../parser/misc/epsilon.dart';
import '../../parser/repeater/repeating.dart';
import '../../parser/utils/sequential.dart';

/// Returns `true`, if [parser] is directly nullable. This means that the parser
/// can succeed without involving any other parsers.
bool isNullable(Parser parser) {
  if (parser is OptionalParser || parser is EpsilonParser) {
    return true;
  }
  if (parser is RepeatingParser && parser.min == 0) {
    return true;
  }
  return false;
}

/// Returns `true`, if [parser] is a terminal or leaf parser. This means it
/// does not delegate to any other parser.
bool isTerminal(Parser parser) => parser.children.isEmpty;

/// Returns `true`, if [parser] consumes its children in the declared
/// sequence.
bool isSequence(Parser parser) =>
    parser is SequentialParser && parser.children.length > 1;

/// Adds all [elements] to [result]. Returns `true` if [result] was changed.
bool addAll<T>(Set<T> result, Iterable<T> elements) {
  var changed = false;
  for (final element in elements) {
    changed |= result.add(element);
  }
  return changed;
}

/// Tests if two sets of parsers are equal.
bool isParserIterableEqual(Iterable<Parser> first, Iterable<Parser> second) {
  for (final one in first) {
    if (!second.any((two) => one.isEqualTo(two))) {
      return false;
    }
  }
  for (final two in second) {
    if (!first.any((one) => two.isEqualTo(one))) {
      return false;
    }
  }
  return true;
}
