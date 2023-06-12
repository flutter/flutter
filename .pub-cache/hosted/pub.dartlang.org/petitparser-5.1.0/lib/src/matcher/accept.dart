import '../core/parser.dart';

extension AcceptParser<T> on Parser<T> {
  /// Tests if the [input] can be successfully parsed.
  ///
  /// For example, `letter().plus().accept('abc')` returns `true`, and
  /// `letter().plus().accept('123')` returns `false`.
  bool accept(String input) => fastParseOn(input, 0) >= 0;
}
