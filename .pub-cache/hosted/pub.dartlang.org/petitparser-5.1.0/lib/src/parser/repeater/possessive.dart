import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import 'repeating.dart';
import 'unbounded.dart';

extension PossessiveRepeatingParserExtension<T> on Parser<T> {
  /// Returns a parser that accepts the receiver zero or more times. The
  /// resulting parser returns a list of the parse results of the receiver.
  ///
  /// This is a greedy and blind implementation that tries to consume as much
  /// input as possible and that does not consider what comes afterwards.
  ///
  /// For example, the parser `letter().star()` accepts the empty string or
  /// any sequence of letters and returns a possibly empty list of the parsed
  /// letters.
  Parser<List<T>> star() => repeat(0, unbounded);

  /// Returns a parser that accepts the receiver one or more times. The
  /// resulting parser returns a list of the parse results of the receiver.
  ///
  /// This is a greedy and blind implementation that tries to consume as much
  /// input as possible and that does not consider what comes afterwards.
  ///
  /// For example, the parser `letter().plus()` accepts any sequence of
  /// letters and returns a list of the parsed letters.
  Parser<List<T>> plus() => repeat(1, unbounded);

  /// Returns a parser that accepts the receiver exactly [count] times. The
  /// resulting parser returns a list of the parse results of the receiver.
  ///
  /// For example, the parser `letter().times(2)` accepts two letters and
  /// returns a list of the two parsed letters.
  Parser<List<T>> times(int count) => repeat(count, count);

  /// Returns a parser that accepts the receiver between [min] and [max] times.
  /// The resulting parser returns a list of the parse results of the receiver.
  ///
  /// This is a greedy and blind implementation that tries to consume as much
  /// input as possible and that does not consider what comes afterwards.
  ///
  /// For example, the parser `letter().repeat(2, 4)` accepts a sequence of
  /// two, three, or four letters and returns the accepted letters as a list.
  Parser<List<T>> repeat(int min, [int? max]) =>
      PossessiveRepeatingParser<T>(this, min, max ?? min);
}

/// A greedy parser that repeatedly parses between 'min' and 'max' instances of
/// its delegate.
class PossessiveRepeatingParser<R> extends RepeatingParser<R, List<R>> {
  PossessiveRepeatingParser(super.parser, super.min, super.max);

  @override
  Result<List<R>> parseOn(Context context) {
    final elements = <R>[];
    var current = context;
    while (elements.length < min) {
      final result = delegate.parseOn(current);
      if (result.isFailure) {
        return result.failure(result.message);
      }
      elements.add(result.value);
      current = result;
    }
    while (elements.length < max) {
      final result = delegate.parseOn(current);
      if (result.isFailure) {
        return current.success(elements);
      }
      elements.add(result.value);
      current = result;
    }
    return current.success(elements);
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
    while (count < max) {
      final result = delegate.fastParseOn(buffer, current);
      if (result < 0) {
        return current;
      }
      current = result;
      count++;
    }
    return current;
  }

  @override
  PossessiveRepeatingParser<R> copy() =>
      PossessiveRepeatingParser<R>(delegate, min, max);
}
