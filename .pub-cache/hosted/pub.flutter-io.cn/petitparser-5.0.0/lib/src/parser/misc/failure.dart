import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';

/// Returns a parser that consumes nothing and fails.
///
/// For example, `failure()` always fails, no matter what input it is given.
Parser<R> failure<R>([String message = 'unable to parse']) =>
    FailureParser<R>(message);

/// A parser that consumes nothing and fails.
class FailureParser<R> extends Parser<R> {
  FailureParser(this.message);

  /// Error message to annotate parse failures with.
  final String message;

  @override
  Result<R> parseOn(Context context) => context.failure<R>(message);

  @override
  int fastParseOn(String buffer, int position) => -1;

  @override
  String toString() => '${super.toString()}[$message]';

  @override
  FailureParser<R> copy() => FailureParser<R>(message);

  @override
  bool hasEqualProperties(FailureParser<R> other) =>
      super.hasEqualProperties(other) && message == other.message;
}
