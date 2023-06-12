import '../../core/parser.dart';
import '../action/map.dart';
import '../combinator/optional.dart';
import '../combinator/sequence.dart';
import '../repeater/possessive.dart';

extension SeparatedByParserExtension<T> on Parser<T> {
  /// Returns a parser that consumes the receiver one or more times separated
  /// by the [separator] parser. The resulting parser returns a flat list of
  /// the parse results of the receiver interleaved with the parse result of the
  /// separator parser. The type parameter `R` defines the type of the returned
  /// list.
  ///
  /// If the optional argument [includeSeparators] is set to `false`, then the
  /// separators are not included in the parse result. If the optional argument
  /// [optionalSeparatorAtEnd] is set to `true` the parser also accepts an
  /// optional separator at the end.
  ///
  /// For example, the parser `digit().separatedBy(char('-'))` returns a parser
  /// that consumes input like `'1-2-3'` and returns a list of the elements and
  /// separators: `['1', '-', '2', '-', '3']`.
  Parser<List<R>> separatedBy<R>(Parser separator,
      {bool includeSeparators = true, bool optionalSeparatorAtEnd = false}) {
    final parser = [
      this,
      [separator, this].toSequenceParser().star(),
      if (optionalSeparatorAtEnd) separator.optional(),
    ].toSequenceParser();
    return parser.map((list) {
      final result = <R>[];
      result.add(list[0]);
      for (List tuple in list[1]) {
        if (includeSeparators) {
          result.add(tuple[0]);
        }
        result.add(tuple[1]);
      }
      if (includeSeparators && optionalSeparatorAtEnd && list[2] != null) {
        result.add(list[2]);
      }
      return result;
    });
  }
}
