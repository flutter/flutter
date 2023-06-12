import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';

/// Returns a parser that consumes nothing and succeeds.
///
/// For example, `char('a').or(epsilon())` is equivalent to
/// `char('a').optional()`.
Parser<void> epsilon() => epsilonWith<void>(null);

/// Returns a parser that consumes nothing and succeeds with [result].
Parser<R> epsilonWith<R>(R result) => EpsilonParser<R>(result);

/// A parser that consumes nothing and succeeds.
class EpsilonParser<R> extends Parser<R> {
  EpsilonParser(this.result);

  /// Value to be returned when the parser is activated.
  final R result;

  @override
  Result<R> parseOn(Context context) => context.success(result);

  @override
  int fastParseOn(String buffer, int position) => position;

  @override
  EpsilonParser<R> copy() => EpsilonParser<R>(result);

  @override
  bool hasEqualProperties(EpsilonParser<R> other) =>
      super.hasEqualProperties(other) && result == other.result;
}
