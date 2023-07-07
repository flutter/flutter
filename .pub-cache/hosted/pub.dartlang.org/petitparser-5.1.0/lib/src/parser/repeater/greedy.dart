import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import 'lazy.dart';
import 'limited.dart';
import 'possessive.dart';
import 'unbounded.dart';

extension GreedyRepeatingParserExtension<T> on Parser<T> {
  /// Returns a parser that parses the receiver zero or more times until it
  /// reaches a [limit]. This is a greedy non-blind implementation of the
  /// [star] operator. The [limit] is not consumed.
  ///
  /// For example, the parser `char('{') & any().starGreedy(char('}')) &
  /// char('}')` consumes the complete input `'{abc}def}'` of `'{abc}def}'`.
  ///
  /// See [starLazy] for the lazy, more efficient, and generally preferred
  /// variation of this combinator.
  Parser<List<T>> starGreedy(Parser<void> limit) =>
      repeatGreedy(limit, 0, unbounded);

  /// Returns a parser that parses the receiver one or more times until it
  /// reaches [limit]. This is a greedy non-blind implementation of the [plus]
  /// operator. The [limit] is not consumed.
  ///
  /// For example, the parser `char('{') & any().plusGreedy(char('}')) &
  /// char('}')` consumes the complete input `'{abc}def}'` of `'{abc}def}'`.
  ///
  /// See [plusLazy] for the lazy, more efficient, and generally preferred
  /// variation of this combinator.
  Parser<List<T>> plusGreedy(Parser<void> limit) =>
      repeatGreedy(limit, 1, unbounded);

  /// Returns a parser that parses the receiver at least [min] and at most [max]
  /// times until it reaches a [limit]. This is a greedy non-blind
  /// implementation of the [repeat] operator. The [limit] is not consumed.
  ///
  /// This is the more generic variation of the [starGreedy] and [plusGreedy]
  /// combinators.
  Parser<List<T>> repeatGreedy(Parser<void> limit, int min, int max) =>
      GreedyRepeatingParser<T>(this, limit, min, max);
}

/// A greedy repeating parser, commonly seen in regular expression
/// implementations. It aggressively consumes as much input as possible and then
/// backtracks to meet the 'limit' condition.
class GreedyRepeatingParser<R> extends LimitedRepeatingParser<R> {
  GreedyRepeatingParser(super.parser, super.limit, super.min, super.max);

  @override
  Result<List<R>> parseOn(Context context) {
    var current = context;
    final elements = <R>[];
    while (elements.length < min) {
      final result = delegate.parseOn(current);
      if (result.isFailure) {
        return result.failure(result.message);
      }
      elements.add(result.value);
      current = result;
    }
    final contexts = <Context>[current];
    while (elements.length < max) {
      final result = delegate.parseOn(current);
      if (result.isFailure) {
        break;
      }
      elements.add(result.value);
      contexts.add(current = result);
    }
    for (;;) {
      final limiter = limit.parseOn(contexts.last);
      if (limiter.isSuccess) {
        return contexts.last.success(elements);
      }
      if (elements.isEmpty) {
        return limiter.failure(limiter.message);
      }
      contexts.removeLast();
      elements.removeLast();
      if (contexts.isEmpty) {
        return limiter.failure(limiter.message);
      }
    }
  }

  @override
  int fastParseOn(String buffer, int position) {
    var count = 0;
    var current = position;
    while (count < min) {
      final result = delegate.fastParseOn(buffer, current);
      if (result < 0) {
        return -1;
      }
      current = result;
      count++;
    }
    final positions = <int>[current];
    while (count < max) {
      final result = delegate.fastParseOn(buffer, current);
      if (result < 0) {
        break;
      }
      positions.add(current = result);
      count++;
    }
    for (;;) {
      final limiter = limit.fastParseOn(buffer, positions.last);
      if (limiter >= 0) {
        return positions.last;
      }
      if (count == 0) {
        return -1;
      }
      positions.removeLast();
      count--;
      if (positions.isEmpty) {
        return -1;
      }
    }
  }

  @override
  GreedyRepeatingParser<R> copy() =>
      GreedyRepeatingParser<R>(delegate, limit, min, max);
}
