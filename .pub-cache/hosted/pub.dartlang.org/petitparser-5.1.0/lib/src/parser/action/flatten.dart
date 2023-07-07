import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../combinator/delegate.dart';

extension FlattenParserExtension<T> on Parser<T> {
  /// Returns a parser that discards the result of the receiver and answers
  /// the sub-string its delegate consumes.
  ///
  /// If a [message] is provided, the flatten parser can switch to a fast mode
  /// where error tracking within the receiver is suppressed and in case of a
  /// problem [message] is reported instead.
  ///
  /// For example, the parser `letter().plus().flatten()` returns `'abc'`
  /// for the input `'abc'`. In contrast, the parser `letter().plus()` would
  /// return `['a', 'b', 'c']` for the same input instead.
  Parser<String> flatten([String? message]) => FlattenParser<T>(this, message);
}

/// A parser that discards the result of the delegate and answers the
/// sub-string its delegate consumes.
class FlattenParser<T> extends DelegateParser<T, String> {
  FlattenParser(super.delegate, [this.message]);

  /// Error message to indicate parse failures with.
  final String? message;

  @override
  Result<String> parseOn(Context context) {
    // If we have a message we can switch to fast mode.
    if (message != null) {
      final position = delegate.fastParseOn(context.buffer, context.position);
      if (position < 0) {
        return context.failure(message!);
      }
      final output = context.buffer.substring(context.position, position);
      return context.success(output, position);
    } else {
      final result = delegate.parseOn(context);
      if (result.isSuccess) {
        final output =
            context.buffer.substring(context.position, result.position);
        return result.success(output);
      }
      return result.failure(result.message);
    }
  }

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  bool hasEqualProperties(FlattenParser<T> other) =>
      super.hasEqualProperties(other) && message == other.message;

  @override
  FlattenParser<T> copy() => FlattenParser<T>(delegate, message);
}
