import '../../core/parser.dart';
import '../character/char.dart';
import '../character/pattern.dart';
import '../misc/epsilon.dart';
import 'predicate.dart';

extension PredicateStringExtension on String {
  /// Converts this string to a corresponding parser.
  Parser<String> toParser({
    bool isPattern = false,
    bool caseInsensitive = false,
    String? message,
  }) {
    if (isEmpty) {
      return epsilonWith<String>(this);
    } else if (length == 1) {
      return caseInsensitive
          ? charIgnoringCase(this, message)
          : char(this, message);
    } else {
      if (isPattern) {
        return caseInsensitive
            ? patternIgnoreCase(this, message)
            : pattern(this, message);
      } else {
        return caseInsensitive
            ? stringIgnoreCase(this, message)
            : string(this, message);
      }
    }
  }
}

/// Returns a parser that accepts the string [element].
///
/// For example, `string('foo')` `succeeds and consumes the input string
/// `'foo'`. Fails for any other input.`
Parser<String> string(String element, [String? message]) => predicate(
    element.length,
    (each) => element == each,
    message ?? '"$element" expected');

/// Returns a parser that accepts the string [element] ignoring the case.
///
/// For example, `stringIgnoreCase('foo')` succeeds and consumes the input
/// string `'Foo'` or `'FOO'`. Fails for any other input.
Parser<String> stringIgnoreCase(String element, [String? message]) {
  final lowerElement = element.toLowerCase();
  return predicate(element.length, (each) => lowerElement == each.toLowerCase(),
      message ?? '"$element" (case-insensitive) expected');
}
