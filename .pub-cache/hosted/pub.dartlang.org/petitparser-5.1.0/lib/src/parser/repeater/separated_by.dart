import '../../core/parser.dart';
import '../combinator/optional.dart';
import '../combinator/sequence.dart';
import '../misc/epsilon.dart';
import '../repeater/possessive.dart';

extension SeparatedByParserExtension<T> on Parser<T> {
  /// Returns a parser that consumes the receiver one or more times separated
  /// by the [separator] parser. The resulting parser returns a flat list of
  /// the parse results of the receiver interleaved with the parse result of the
  /// separator parser. The type parameter `R` defines the type of the returned
  /// list.
  ///
  /// If the optional argument [includeSeparators] is set to `false`, then the
  /// separators themselves are not included in the parse result. If the
  /// optional argument [optionalSeparatorAtStart] or [optionalSeparatorAtEnd]
  /// is set to `true` the parser also accepts optional separators at the start
  /// and/or end.
  ///
  /// For example, the parser `digit().separatedBy(char('-'))` returns a parser
  /// that consumes input like `'1-2-3'` and returns a list of the elements and
  /// separators: `['1', '-', '2', '-', '3']`.
  @Deprecated('Use `plusSeparated` for a better optimized and strongly typed '
      'implementation that provides the elements and separators separately')
  Parser<List<R>> separatedBy<R>(
    Parser separator, {
    bool includeSeparators = true,
    bool optionalSeparatorAtStart = false,
    bool optionalSeparatorAtEnd = false,
  }) =>
      seq4(
              optionalSeparatorAtStart
                  ? separator.optional()
                  : epsilonWith(null),
              this,
              seq2(separator, this).star(),
              optionalSeparatorAtEnd ? separator.optional() : epsilonWith(null))
          .map4(
        (separatorAtStart, firstElement, otherElements, separatorAtEnd) {
          final result = <R>[];
          if (includeSeparators &&
              optionalSeparatorAtStart &&
              separatorAtStart != null) {
            result.add(separatorAtStart);
          }
          result.add(firstElement as R);
          for (var tuple in otherElements) {
            if (includeSeparators) {
              result.add(tuple.first);
            }
            result.add(tuple.second as R);
          }
          if (includeSeparators &&
              optionalSeparatorAtEnd &&
              separatorAtEnd != null) {
            result.add(separatorAtEnd);
          }
          return result;
        },
      );
}
